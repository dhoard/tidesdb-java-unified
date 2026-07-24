#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
STAGING_DIR="$PROJECT_DIR/build/staging"
DIST_DIR="$PROJECT_DIR/dist"
WORK_DIR="$PROJECT_DIR/build/work"
GENERATED_RESOURCES_DIR="$PROJECT_DIR/build/generated-resources"
MAVEN_REPO_DIR="$WORK_DIR/m2"
NATIVE_RESOURCE_DIR="$GENERATED_RESOURCES_DIR/native/linux-x86_64"
NATIVE_LIBRARY="$NATIVE_RESOURCE_DIR/libtidesdb_jni.so"

# --- Trap: print failing command and line on error ---
trap 'echo "[ERROR] Command failed (line $LINENO): $BASH_COMMAND" >&2' ERR

# --- Trap: clean staging on exit if build fails ---
trap 'rm -rf "$STAGING_DIR"; rm -f "$PROJECT_DIR/dependency-reduced-pom.xml"' EXIT

# --- Clean dist/ from any previous run ---
rm -rf "$DIST_DIR" "$STAGING_DIR"

# --- Phase timing helper ---
phase() { echo ""; echo "===[ $(date -u +%T) ] $* ==="; }

# ===================================================================
# Preflight checks
# ===================================================================
preflight() {
    local errors=0
    local missing=()

    check_cmd() {
        local cmd="$1" min_ver="${2:-}" label="${3:-$1}"
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "[PREFLIGHT] MISSING: $label ($cmd)"
            missing+=("$label ($cmd)")
            errors=$((errors + 1))
            return 1
        fi
        if [ -n "$min_ver" ]; then
            local ver
            ver=$("$cmd" --version 2>&1 | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1 || true)
            if [ -z "$ver" ]; then
                echo "[PREFLIGHT] WARNING: could not determine version of $cmd"
            fi
        fi
        return 0
    }

    echo "[PREFLIGHT] Host: $(uname -a)"

    # --- Platform check ---
    local os arch
    os=$(uname -s)
    arch=$(uname -m)
    if [[ "$os" != "Linux" ]]; then
        echo "[PREFLIGHT] FAIL: expected Linux, detected $os"
        errors=$((errors + 1))
    fi
    if [[ "$arch" != "x86_64" && "$arch" != "amd64" ]]; then
        echo "[PREFLIGHT] FAIL: expected x86_64, detected $arch"
        errors=$((errors + 1))
    fi

    # --- Required tools ---
    check_cmd bash   ""       "Bash"
    check_cmd git    ""       "Git"
    check_cmd cmake  "3.25"   "CMake (>= 3.25 required by TidesDB)"
    check_cmd ninja  ""       "Ninja (preferred build backend)"
    check_cmd gcc    ""       "GCC"
    check_cmd g++    ""       "G++"
    check_cmd ld     ""       "GNU ld"
    check_cmd ar     ""       "GNU ar"
    check_cmd ranlib ""       "ranlib"
    check_cmd readelf ""      "readelf (native dependency inspection)"
    check_cmd ldd    ""       "ldd (native dependency inspection)"
    check_cmd file   ""       "file (library type verification)"
    check_cmd sha256sum ""    "sha256sum"
    check_cmd tar    ""       "tar"
    check_cmd curl   ""       "curl (Maven Wrapper bootstrap)"

    # --- JDK ---
    check_cmd java "" "Java"
    check_cmd javac "" "javac"
    check_cmd jar "" "jar"

    local java_ver
    java_ver=$(java -version 2>&1 | head -1 | grep -oE '[0-9]+(\.[0-9]+)?' | head -1 || echo "0")
    if [ "$(echo "$java_ver >= 11" | bc -l 2>/dev/null || echo 0)" != "1" ]; then
        echo "[PREFLIGHT] FAIL: Java >= 11 required, detected $java_ver"
        errors=$((errors + 1))
    else
        echo "[PREFLIGHT] Java version: $java_ver"
    fi
    if ! javac -version >/dev/null 2>&1; then
        echo "[PREFLIGHT] FAIL: javac not found"
        errors=$((errors + 1))
    fi

    # --- Maven Wrapper ---
    if [ ! -x "$PROJECT_DIR/mvnw" ]; then
        echo "[PREFLIGHT] FAIL: mvnw not found or not executable"
        errors=$((errors + 1))
    fi

    # --- upstream.properties ---
    if [ ! -f "$PROJECT_DIR/upstream.properties" ]; then
        echo "[PREFLIGHT] FAIL: upstream.properties not found"
        errors=$((errors + 1))
    fi

    # --- vcpkg (optional; only needed if vcpkg.json manifest mode is used) ---
    :

    # --- Unsafe environment overrides ---
    for var in LD_LIBRARY_PATH LD_PRELOAD CFLAGS CXXFLAGS LDFLAGS; do
        if [ -n "${!var:-}" ]; then
            echo "[PREFLIGHT] WARNING: $var is set (${!var}). This may contaminate native linkage."
        fi
    done

    # --- Disk space (require ~2GB free) ---
    local free_kb
    free_kb=$(df -k "$PROJECT_DIR" | tail -1 | awk '{print $4}')
    if [ "$free_kb" -lt 2097152 ]; then
        echo "[PREFLIGHT] FAIL: insufficient disk space (< 2 GB free)"
        errors=$((errors + 1))
    fi

    # --- Report ---
    if [ "$errors" -gt 0 ]; then
        echo ""
        echo "===== PREFLIGHT FAILED ($errors issue(s)) ====="
        echo "The following prerequisites are missing or incompatible:"
        for m in "${missing[@]}"; do
            echo "  - $m"
        done
        echo ""
        echo "build.sh does not install prerequisites. Please install them manually."
        echo "For Ubuntu: sudo apt-get install cmake ninja-build gcc g++ binutils"
        echo "             curl tar openjdk-11-jdk-headless"
        echo "vcpkg:       git clone https://github.com/microsoft/vcpkg.git && cd vcpkg && ./bootstrap-vcpkg.sh"
        echo "             export VCPKG_ROOT=\$PWD"
        exit 1
    fi
    echo "[PREFLIGHT] All checks passed."
}

# ===================================================================
# Clone upstream sources
# ===================================================================
clone_sources() {
    rm -rf "$WORK_DIR" "$GENERATED_RESOURCES_DIR"
    mkdir -p "$WORK_DIR" "$GENERATED_RESOURCES_DIR"

    # Parse upstream.properties
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
        key=$(echo "$key" | xargs | tr '.-' '__')
        value=$(echo "$value" | xargs)
        declare "$key=$value"
    done < "$PROJECT_DIR/upstream.properties"

    # clone_and_checkout <name> <branch> <tag> <repo_url> <dest_dir>
    clone_and_checkout() {
        local name="$1" branch="$2" tag="$3" repo="$4" dest="$5"
        echo "[CLONE] $name (branch: $branch${tag:+, tag: $tag})"
        git clone --branch "$branch" "$repo" "$dest"
        if [ -n "$tag" ]; then
            git -C "$dest" checkout "$tag"
        fi
    }

    clone_and_checkout tidesdb "$tidesdb_branch" "$tidesdb_tag" "$tidesdb_repo" "$WORK_DIR/tidesdb"
    clone_and_checkout tidesdb-java "$tidesdb_java_branch" "$tidesdb_java_tag" "$tidesdb_java_repo" "$WORK_DIR/tidesdb-java"
    clone_and_checkout zstd "$zstd_branch" "$zstd_tag" "$zstd_repo" "$WORK_DIR/zstd"
    clone_and_checkout lz4 "$lz4_branch" "$lz4_tag" "$lz4_repo" "$WORK_DIR/lz4"
    clone_and_checkout snappy "$snappy_branch" "$snappy_tag" "$snappy_repo" "$WORK_DIR/snappy"
}

# ===================================================================
# Build the pinned upstream Java artifact without modifying its source
# ===================================================================
build_upstream_java() {
    echo "[JAVA-UPSTREAM] Building pinned tidesdb-java source..."
    "$WORK_DIR/tidesdb-java/mvnw" \
        -f "$WORK_DIR/tidesdb-java/pom.xml" \
        -Dmaven.repo.local="$MAVEN_REPO_DIR" \
        -DskipTests \
        -Dmaven.javadoc.skip=true \
        clean install

    git -C "$WORK_DIR/tidesdb-java" diff --exit-code
    echo "[JAVA-UPSTREAM] Source checkout remained unchanged."
}

# ===================================================================
# Build native library
# ===================================================================
build_native() {
    local native_build_dir="$WORK_DIR/build-native"
    mkdir -p "$native_build_dir"

    cmake -S "$PROJECT_DIR/cmake" -B "$native_build_dir" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DTIDESDB_SOURCE_DIR="$WORK_DIR/tidesdb" \
        -DTIDESDB_JAVA_SOURCE_DIR="$WORK_DIR/tidesdb-java" \
        -DZSTD_SOURCE_DIR="$WORK_DIR/zstd" \
        -DLZ4_SOURCE_DIR="$WORK_DIR/lz4" \
        -DSNAPPY_SOURCE_DIR="$WORK_DIR/snappy" \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON

    cmake --build "$native_build_dir" --config Release

    # Publish only generated output as a Maven resource. The source tree remains clean.
    mkdir -p "$NATIVE_RESOURCE_DIR"
    cp "$native_build_dir/libtidesdb_jni.so" "$NATIVE_LIBRARY"

    # Release builds must never modify either cloned upstream checkout.
    git -C "$WORK_DIR/tidesdb" diff --exit-code
    git -C "$WORK_DIR/tidesdb-java" diff --exit-code

    echo "[NATIVE] Built: $NATIVE_LIBRARY"
}

# ===================================================================
# Verify native library dependencies
# ===================================================================
verify_native() {
    local lib="$NATIVE_LIBRARY"
    if [ ! -f "$lib" ]; then
        echo "[VERIFY] FAIL: library not found: $lib"
        exit 3
    fi

    echo "[VERIFY] Library type: $(file "$lib")"

    # Forbidden dynamic dependencies
    local forbidden=("libtidesdb" "libzstd" "liblz4" "libsnappy" "libs3" "libcurl" "libssl" "libcrypto")
    local ldd_out
    ldd_out=$(ldd "$lib" 2>&1)

    local fail=0
    for dep in "${forbidden[@]}"; do
        if echo "$ldd_out" | grep -qi "$dep"; then
            echo "[VERIFY] FAIL: forbidden dynamic dependency: $dep"
            fail=1
        fi
    done

    echo "[VERIFY] ldd output:"
    echo "$ldd_out"

    echo "[VERIFY] readelf NEEDED:"
    readelf -d "$lib" | grep 'NEEDED' || echo "(none)"

    # Check for RPATH/RUNPATH contamination
    if readelf -d "$lib" | grep -qiE '(RPATH|RUNPATH).*(/tmp|/home|/build|/vcpkg)'; then
        echo "[VERIFY] FAIL: suspicious RPATH/RUNPATH entry detected"
        fail=1
    fi

    if [ "$fail" -ne 0 ]; then
        echo "[VERIFY] FAIL: native dependency audit failed"
        exit 3
    fi
    echo "[VERIFY] PASS"
}

# ===================================================================
# Build Java project
# ===================================================================
build_java() {
    echo "[JAVA] Running unified Maven build against the pinned upstream artifact..."
    cd "$PROJECT_DIR"
    ./mvnw -Dmaven.repo.local="$MAVEN_REPO_DIR" clean install -Dspotless.check.skip=true
    rm -f "$PROJECT_DIR/dependency-reduced-pom.xml"
    echo "[JAVA] Build complete."
}

# ===================================================================
# Assemble complete sources without copying upstream source into this tree
# ===================================================================
assemble_sources() {
    local upstream_sources="$WORK_DIR/tidesdb-java/target/tidesdb-java-0.8.3-sources.jar"
    local unified_sources="$PROJECT_DIR/target/tidesdb-java-unified-0.8.3_tidesdb-9.3.13-sources.jar"
    local assembly_dir="$WORK_DIR/source-assembly"
    local assembled_sources="$WORK_DIR/tidesdb-java-unified-sources.jar"

    if [ ! -f "$upstream_sources" ] || [ ! -f "$unified_sources" ]; then
        echo "[SOURCES] FAIL: source artifact missing"
        exit 4
    fi

    rm -rf "$assembly_dir"
    mkdir -p "$assembly_dir"
    (
        cd "$assembly_dir"
        jar xf "$upstream_sources"
        rm -f com/tidesdb/NativeLibrary.java
        rm -rf META-INF/maven/com.tidesdb/tidesdb-java
        jar xf "$unified_sources"
        rm -rf native
        jar --create --file "$assembled_sources" .
    )
    mv "$assembled_sources" "$unified_sources"

    # Replace only the initially installed loader-only source artifact. Do not
    # reinstall the project POM: Maven Shade installed a dependency-reduced POM
    # so consumers retain the single-JAR contract.
    cp "$unified_sources" \
        "$MAVEN_REPO_DIR/com/tidesdb/tidesdb-java-unified/0.8.3_tidesdb-9.3.13/"

    echo "[SOURCES] Combined unchanged upstream API sources with the unified loader source."
}

# ===================================================================
# Packaged-JAR validation
# ===================================================================
validate_jar() {
    echo "[VALIDATE] Running packaged-JAR validation example..."

    # Build and run the example in an isolated local Maven repository
    local example_repo="$WORK_DIR/example-repo"
    rm -rf "$example_repo"
    mkdir -p "$example_repo"

    # Install the built JAR into the isolated repo
    local jar_path
    jar_path=$(find "$PROJECT_DIR/target" -maxdepth 1 -name "tidesdb-java-unified-*.jar" ! -name "*sources*" ! -name "*javadoc*" | head -1)
    if [ ! -f "$jar_path" ]; then
        echo "[VALIDATE] FAIL: built JAR not found under target/"
        exit 4
    fi

    local version
    version=$(./mvnw -f "$PROJECT_DIR/pom.xml" help:evaluate -Dexpression=project.version -q -DforceStdout)
    local groupId="com.tidesdb"
    local artifactId="tidesdb-java-unified"

    ./mvnw -f "$PROJECT_DIR/pom.xml" \
        install:install-file \
        -Dfile="$jar_path" \
        -DgroupId="$groupId" \
        -DartifactId="$artifactId" \
        -Dversion="$version" \
        -Dpackaging=jar \
        -DlocalRepositoryPath="$example_repo" \
        -DcreateChecksum=true

    # Install sources and javadoc if present
    local sources_jar
    sources_jar=$(find "$PROJECT_DIR/target" -maxdepth 1 -name "tidesdb-java-unified-*-sources.jar" | head -1)
    if [ -f "$sources_jar" ]; then
        ./mvnw -f "$PROJECT_DIR/pom.xml" \
            install:install-file \
            -Dfile="$sources_jar" \
            -DgroupId="$groupId" \
            -DartifactId="$artifactId" \
            -Dversion="$version" \
            -Dpackaging=jar \
            -Dclassifier=sources \
            -DlocalRepositoryPath="$example_repo"
    fi

    # Run example using the isolated repository
    # Must not set java.library.path, LD_LIBRARY_PATH, or DYLD_LIBRARY_PATH
    ./mvnw -f "$PROJECT_DIR/examples/basic/pom.xml" \
        verify \
        -Dmaven.repo.local="$example_repo"

    echo "[VALIDATE] PASS"
}

# ===================================================================
# Generate deliverables
# ===================================================================
generate_dist() {
    rm -rf "$DIST_DIR" "$STAGING_DIR"
    mkdir -p "$STAGING_DIR" "$DIST_DIR"

    # Copy JARs
    cp "$PROJECT_DIR"/target/tidesdb-java-unified-*.jar "$STAGING_DIR/"

    # Generate SHA-256 checksums
    cd "$STAGING_DIR"
    sha256sum *.jar > checksums.sha256

    # Generate native dependency report
    local report="$STAGING_DIR/native-dependencies.txt"
    {
        echo "Native Dependency Report"
        echo "========================"
        echo "Build host: $(uname -a)"
        echo "TidesDB branch: $(grep 'tidesdb.branch=' "$PROJECT_DIR/upstream.properties" | cut -d= -f2)"
        echo "TidesDB tag: $(grep 'tidesdb.tag=' "$PROJECT_DIR/upstream.properties" | cut -d= -f2 || echo '(latest)')"
        echo "tidesdb-java branch: $(grep 'tidesdb-java.branch=' "$PROJECT_DIR/upstream.properties" | cut -d= -f2)"
        echo "tidesdb-java tag: $(grep 'tidesdb-java.tag=' "$PROJECT_DIR/upstream.properties" | cut -d= -f2 || echo '(latest)')"
        echo ""
        echo "--- ldd ---"
        ldd "$NATIVE_LIBRARY" 2>&1
        echo ""
        echo "--- readelf -d ---"
        readelf -d "$NATIVE_LIBRARY" 2>&1 | grep 'NEEDED' || echo "(none)"
    } > "$report"

    # Copy license files
    cp "$PROJECT_DIR"/LICENSES/*.txt "$STAGING_DIR/" 2>/dev/null || true

    # Atomic move: only if everything succeeded
    mv "$STAGING_DIR"/* "$DIST_DIR/"
    rmdir "$STAGING_DIR"

    echo "[DIST] Deliverables in: $DIST_DIR"
}

# ===================================================================
# Main build phases
# ===================================================================
phase "Preflight checks"
preflight

phase "Clone upstream sources"
clone_sources

phase "Build pinned tidesdb-java artifact"
build_upstream_java

phase "Build native library from unchanged upstream JNI source"
build_native

phase "Verify native library dependencies"
verify_native

phase "Build Java project"
build_java

phase "Assemble complete sources artifact"
assemble_sources

phase "Packaged-JAR validation"
validate_jar

phase "Generate deliverables"
generate_dist

# --- Success: disable EXIT trap's staging cleanup, keep dist/ ---
trap - EXIT
echo ""
echo "===== BUILD SUCCESS ====="
echo "Deliverables:"
find "$DIST_DIR" -type f -exec ls -lh {} \;
