# tidesdb-java-unified

A self-contained Java binding for [TidesDB](https://github.com/tidesdb/tidesdb). The generated JAR embeds the TidesDB JNI library together with its native compression dependencies, so applications do not need a separate TidesDB installation or a custom `java.library.path`.

> **Current platform:** Linux x86-64 with glibc. Other operating systems and architectures are not yet supported.

## Versions

| Component | Version |
|---|---|
| tidesdb-java | 0.8.3 |
| TidesDB | 9.3.13 |
| Java | 11 or later |
| zstd | 1.5.6 |
| LZ4 | 1.10.0 |
| Snappy | 1.2.1 |

All upstream sources are checked out at immutable commits recorded in [`upstream.properties`](upstream.properties).

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
- `curl`, `file`, `ldd`, `sha256sum`, `tar`, and Python 3

For Ubuntu 22.04, the non-JDK build dependencies can be installed with:

```bash
sudo apt-get update
sudo apt-get install -y cmake ninja-build gcc g++ binutils curl file tar python3
```

Install a JDK 11 or later separately and ensure `java`, `javac`, and `jar` resolve from `PATH`.

The build performs the following steps:

1. validates the host and toolchain;
2. clones all upstream projects at pinned commits;
3. refreshes the checked-in `tidesdb-java` API sources;
4. applies the documented JNI compatibility patch;
5. builds static zstd, LZ4, Snappy, and TidesDB libraries;
6. links them into `libtidesdb_jni.so`;
7. audits the native library for forbidden dynamic dependencies;
8. builds and tests the Java project;
9. runs the standalone example against the packaged JAR using an isolated Maven repository;
10. writes the validated artifacts and checksums to `dist/`.

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
src/main/java/       Java API and customized native loader
src/test/java/       loader and JNI integration tests
examples/basic/      standalone packaged-JAR acceptance test
cmake/CMakeLists.txt native build definition
```

The Java API is based on the pinned `tidesdb-java` release. `NativeLibrary.java` is maintained by this project, while [`scripts/patch-jni.py`](scripts/patch-jni.py) applies compatibility changes to the cloned JNI C source during the build. These differences are documented in [`VENDORED-CHANGES.md`](VENDORED-CHANGES.md).

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

## Licensing

TidesDB and tidesdb-java are distributed under the Mozilla Public License 2.0. This project preserves their notices and includes license information for bundled native dependencies in [`LICENSES`](LICENSES) and each generated `dist/` directory.
