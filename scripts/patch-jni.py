#!/usr/bin/env python3
"""Patch tidesdb-java JNI C source for compatibility with tidesdb v9.3.13."""

import sys
import re


def patch_jni_source(path):
    with open(path, 'r') as f:
        content = f.read()

    # 1. Replace include
    content = content.replace('#include <tidesdb/db.h>', '#include "tidesdb.h"')

    # 2. Remove dlfcn include block
    content = re.sub(
        r'#ifndef _WIN32\n#include <dlfcn\.h>\n#endif\n',
        '',
        content
    )

    # 3. Remove the Java_com_tidesdb_TidesDB_nativeS3Available function
    #    From the function signature to its closing brace
    content = re.sub(
        r'JNIEXPORT jboolean JNICALL Java_com_tidesdb_TidesDB_nativeS3Available.*?^}\n',
        '',
        content,
        flags=re.MULTILINE | re.DOTALL
    )

    # 4. Remove the Java_com_tidesdb_TidesDB_nativeObjstoreS3Create function
    #    From the function signature to its closing brace (before nativeClose)
    content = re.sub(
        r'JNIEXPORT jlong JNICALL Java_com_tidesdb_TidesDB_nativeObjstoreS3Create.*?^}\n',
        '',
        content,
        flags=re.MULTILINE | re.DOTALL
    )

    # 5. Remove the S3 typedef and resolve function block
    content = re.sub(
        r'/\* S3 object store support.*?^}\n',
        '',
        content,
        flags=re.MULTILINE | re.DOTALL
    )

    # 6. Fix nativeOpen: replace object store connector code block
    old_objstore_block = re.compile(
        r'(    /\* object store connector:.*?oscReplicaReplayWal \? 1 : 0\};)\n',
        re.DOTALL
    )
    replacement = (
        '    /* object store connector: not supported in MVP; always use filesystem backend */\n'
        '    (void)objStoreHandle;\n'
        '    (void)objectStoreFsPath;\n'
        '    (void)oscLocalCachePath;\n'
        '    (void)oscLocalCacheMaxBytes;\n'
        '    (void)oscCacheOnRead;\n'
        '    (void)oscCacheOnWrite;\n'
        '    (void)oscMaxConcurrentUploads;\n'
        '    (void)oscMaxConcurrentDownloads;\n'
        '    (void)oscMultipartThreshold;\n'
        '    (void)oscMultipartPartSize;\n'
        '    (void)oscSyncManifestToObject;\n'
        '    (void)oscReplicateWal;\n'
        '    (void)oscWalUploadSync;\n'
        '    (void)oscWalSyncThresholdBytes;\n'
        '    (void)oscWalSyncOnCommit;\n'
        '    (void)oscReplicaMode;\n'
        '    (void)oscReplicaSyncIntervalUs;\n'
        '    (void)oscReplicaReplayWal;\n'
        '\n'
    )
    content = old_objstore_block.sub(replacement, content)

    # 7. Replace .object_store = obj_store, with .object_store = NULL,
    content = content.replace(
        '.object_store = obj_store,',
        '.object_store = NULL,'
    )
    # 8. Replace .object_store_config = obj_store != NULL ? &os_cfg : NULL,
    content = content.replace(
        '.object_store_config = obj_store != NULL ? &os_cfg : NULL,',
        '.object_store_config = NULL,'
    )

    # 9. Remove the fs_path and cache_path cleanup at the end of nativeOpen
    content = re.sub(
        r'(\(\*env\)->ReleaseStringUTFChars\(env, dbPath, path\);\n)'
        r'    if \(fs_path != NULL\)\n'
        r'    \{\n'
        r'        \(\*env\)->ReleaseStringUTFChars\(env, objectStoreFsPath, fs_path\);\n'
        r'    \}\n'
        r'    if \(cache_path != NULL\)\n'
        r'    \{\n'
        r'        \(\*env\)->ReleaseStringUTFChars\(env, oscLocalCachePath, cache_path\);\n'
        r'    \}\n',
        r'\1',
        content
    )

    # 10. Clean up any double blank lines
    content = re.sub(r'\n\n\n+', '\n\n', content)

    with open(path, 'w') as f:
        f.write(content)

    print(f"[PATCH] Patched {path}")


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <path-to-com_tidesdb_TidesDB.c>")
        sys.exit(1)
    patch_jni_source(sys.argv[1])
