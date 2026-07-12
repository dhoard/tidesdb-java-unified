# Vendored Source Changes

Upstream: tidesdb/tidesdb-java v0.8.3 (commit: 4ce8f8a520022242d1d785bf594df5be0772a35b)

## Changes Applied

1. `NativeLibrary.java` — replaced with unified loader (see `src/main/java/com/tidesdb/NativeLibrary.java`).
   The unified loader normalizes platform detection, extracts the embedded native library
   from the JAR resource to a hash-addressed cache directory, and loads it atomically.
   It supports a development override via system property `tidesdb.native.library.path`
   and is idempotent and thread-safe.

2. `com_tidesdb_TidesDB.c` (JNI C source) — patched for tidesdb v9.3.13 compatibility:
   - Changed `#include <tidesdb/db.h>` to `#include "tidesdb.h"` (consolidated header).
   - Removed `#include <dlfcn.h>` guard (no longer needed without S3 dlsym).
   - Removed S3 object store functions (`nativeS3Available`, `nativeObjstoreS3Create`)
     because `tidesdb_objstore_s3_config_t` is not exposed in v9.3.13's public API
     and S3 support is deferred out of MVP scope.
   - Simplified `nativeOpen` to always pass `NULL` for `object_store` and
     `object_store_config` since `tidesdb_objstore_fs_create` no longer exists
     and `tidesdb_objstore_config_t` is opaque in v9.3.13.
   Patches are applied automatically by `scripts/patch-jni.py` during `./build.sh`.

3. No other source changes. If any are needed, document them here with justification.
