#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORK_DIR="${WORK_DIR:-$PROJECT_DIR/build/work}"
mkdir -p "$WORK_DIR"

# Parse upstream.properties
while IFS='=' read -r key value; do
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
    key=$(echo "$key" | xargs | tr '.-' '__')
    value=$(echo "$value" | xargs)
    declare "$key=$value"
done < "$PROJECT_DIR/upstream.properties"

# Clone and verify tidesdb
if [ ! -d "$WORK_DIR/tidesdb" ]; then
    git clone "$tidesdb_repo" "$WORK_DIR/tidesdb"
fi
git -C "$WORK_DIR/tidesdb" fetch --tags
git -C "$WORK_DIR/tidesdb" checkout "$tidesdb_commit"
actual=$(git -C "$WORK_DIR/tidesdb" rev-parse HEAD)
if [ "$actual" != "$tidesdb_commit" ]; then
    echo "ERROR: tidesdb checkout mismatch" >&2; exit 1
fi

# Clone and verify tidesdb-java
if [ ! -d "$WORK_DIR/tidesdb-java" ]; then
    git clone "$tidesdb_java_repo" "$WORK_DIR/tidesdb-java"
fi
git -C "$WORK_DIR/tidesdb-java" fetch --tags
git -C "$WORK_DIR/tidesdb-java" checkout "$tidesdb_java_commit"
actual=$(git -C "$WORK_DIR/tidesdb-java" rev-parse HEAD)
if [ "$actual" != "$tidesdb_java_commit" ]; then
    echo "ERROR: tidesdb-java checkout mismatch" >&2; exit 1
fi

echo "Sources checked out at pinned commits."
