# tidesdb-java-unified

A self-contained Java binding for [TidesDB](https://github.com/tidesdb/tidesdb). The generated JAR embeds the TidesDB JNI library together with its native compression dependencies, so applications do not need a separate TidesDB installation or a custom `java.library.path`.

> **Current platform:** Linux x86-64 with glibc. Other operating systems and architectures are not yet supported.

## Upstream configuration

All upstream sources are configured in [`upstream.properties`](upstream.properties) using a branch + tag model:

```properties
tidesdb.branch=master
tidesdb.tag=           # empty = latest on branch
tidesdb.repo=https://github.com/tidesdb/tidesdb.git
```

| Field | Purpose |
|---|---|
| `.branch` | Branch to clone |
| `.tag` | Tag to checkout (empty = latest on branch) |
| `.repo` | Repository URL |

To pin a specific release, set the tag:

```properties
tidesdb.branch=master
tidesdb.tag=v9.3.13
```

| Component | Branch | Default Tag |
|---|---|---|
| tidesdb-java | master | (latest) |
| TidesDB | master | (latest) |
| Java | 11 or later | — |
| zstd | dev | (latest) |
| LZ4 | dev | (latest) |
| Snappy | main | (latest) |

## Build

The complete build has one entry point:

```bash
./build.sh
```

Run it on Linux x86-64 with at least 2 GB of free disk space. It requires:

- Bash
- Git
- CMake 3.25 or later
- Ninja
- GCC and G++
- GNU binutils (`ld`, `ar`, `ranlib`, and `readelf`)
- Java Development Kit 11 or later (`java`, `javac`, and `jar`)
- `curl`, `file`, `ldd`, `sha256sum`, and `tar`

For Ubuntu 22.04, the non-JDK build dependencies can be installed with:

```bash
sudo apt-get update
sudo apt-get install -y cmake ninja-build gcc g++ binutils curl file tar
```

Install a JDK 11 or later separately and ensure `java`, `javac`, and `jar` resolve from `PATH`.

The build performs the following steps:

1. validates the host and toolchain;
2. clones all upstream projects at configured branch/tag;
3. builds the pinned `tidesdb-java` Java artifact without modifying its source;
4. builds static zstd, LZ4, Snappy, and TidesDB libraries;
5. compiles the unchanged upstream JNI source and links it into `libtidesdb_jni.so`;
6. audits the native library for forbidden dynamic dependencies;
7. assembles and tests the unified Java artifact;
8. runs the standalone example against the packaged JAR using an isolated Maven repository;
9. writes the validated artifacts and checksums to `dist/`.

The script may download Maven through the checked-in Maven Wrapper and requires network access to GitHub and Maven Central.

## Build outputs

A successful build creates:

```text
dist/
├── tidesdb-java-unified-0.8.3_tidesdb-9.3.13.jar
├── tidesdb-java-unified-0.8.3_tidesdb-9.3.13-sources.jar
├── tidesdb-java-unified-0.8.3_tidesdb-9.3.13-javadoc.jar
├── checksums.sha256
├── native-dependencies.txt
└── license and third-party notice files
```

Verify the artifacts with:

```bash
cd dist
sha256sum --check checksums.sha256
```

## Use from Maven

`./build.sh` installs the artifact into the local Maven repository. It is not currently published to Maven Central.

```xml
<dependency>
  <groupId>com.tidesdb</groupId>
  <artifactId>tidesdb-java-unified</artifactId>
  <version>0.8.3_tidesdb-9.3.13</version>
</dependency>
```

The application does not need to set `LD_LIBRARY_PATH` or `java.library.path`. On first use, `NativeLibrary` extracts the embedded JNI library into a versioned, SHA-256-addressed directory beneath `java.io.tmpdir` and loads it with `System.load(...)`.

For development only, an explicit native library can be selected with an absolute path:

```bash
java -Dtidesdb.native.library.path=/absolute/path/libtidesdb_jni.so ...
```

## Example

The checked-in example under [`examples/basic`](examples/basic) opens a database, writes and reads a value, closes the database, and verifies persistence after reopening it.

After building the main project, run:

```bash
./mvnw -q -f examples/basic/pom.xml verify
```

A successful run prints:

```text
tidesdb-java-unified validation succeeded
```

## Development

Production sources, tests, and examples are checked in:

```text
src/main/java/       unified embedded-native loader (upstream API is merged during the build)
src/test/java/       loader and JNI integration tests
examples/basic/      standalone packaged-JAR acceptance test
cmake/CMakeLists.txt native build definition
```

The Java API comes from the upstream `tidesdb-java` build under `build/work/`. `NativeLibrary.java` is maintained by this project to provide deterministic embedded-native extraction. The cloned upstream Java and JNI source is never patched, copied into the source tree, or formatted by this build. See [`VENDORED-CHANGES.md`](VENDORED-CHANGES.md) and [`BUILD-PLAN.md`](BUILD-PLAN.md).

To apply Java formatting:

```bash
./mvnw spotless:apply
```

The canonical end-to-end verification remains:

```bash
./build.sh
```

## Native dependency policy

The packaged JNI shared library must not dynamically depend on separately installed copies of:

- TidesDB
- zstd
- LZ4
- Snappy
- curl, OpenSSL, or the optional S3 implementation

Normal Linux system dependencies such as glibc are permitted. The build enforces this policy with `ldd` and `readelf`; results are recorded in `dist/native-dependencies.txt`.

## CI

GitHub Actions runs `./build.sh` for pushes and pull requests targeting `main`, then retains `dist/` as a workflow artifact. CI uses SHA-pinned official actions and Corretto JDK 11.

By default CI pulls the latest commit on each configured branch. To pin CI to specific versions, set the `.tag` values in `upstream.properties`.

## Licensing

TidesDB and tidesdb-java are distributed under the Mozilla Public License 2.0. This project preserves their notices and includes license information for bundled native dependencies in [`LICENSES`](LICENSES) and each generated `dist/` directory.
