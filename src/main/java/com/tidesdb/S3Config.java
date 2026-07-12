/**
 *
 * Copyright (C) TidesDB
 *
 * Original Author: Alex Gaetano Padula
 *
 * Licensed under the Mozilla Public License, v. 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.mozilla.org/en-US/MPL/2.0/
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.tidesdb;

/**
 * Configuration for an S3-compatible object store connector (AWS S3, MinIO, etc.).
 *
 * <p>Mirrors {@code tidesdb_objstore_s3_config_t}. Set it on a {@link Config} via
 * {@link Config.Builder#objectStoreS3Config(S3Config)} to back a database with object storage.
 * Combine it with an {@link ObjectStoreConfig} (cache, multipart, WAL replication, replica mode)
 * for full control over object store behavior.
 *
 * <p>Requires the native TidesDB library to have been built with {@code TIDESDB_WITH_S3=ON};
 * otherwise opening the database throws a {@link TidesDBException}. Use
 * {@link TidesDB#isS3Available()} to probe support at runtime.
 */
public class S3Config {

    private final String endpoint;
    private final String bucket;
    private final String prefix;
    private final String accessKey;
    private final String secretKey;
    private final String region;
    private final boolean useSsl;
    private final boolean usePathStyle;
    private final String tlsCaPath;
    private final boolean tlsInsecureSkipVerify;
    private final long multipartThreshold;
    private final long multipartPartSize;

    private S3Config(Builder builder) {
        this.endpoint = builder.endpoint;
        this.bucket = builder.bucket;
        this.prefix = builder.prefix;
        this.accessKey = builder.accessKey;
        this.secretKey = builder.secretKey;
        this.region = builder.region;
        this.useSsl = builder.useSsl;
        this.usePathStyle = builder.usePathStyle;
        this.tlsCaPath = builder.tlsCaPath;
        this.tlsInsecureSkipVerify = builder.tlsInsecureSkipVerify;
        this.multipartThreshold = builder.multipartThreshold;
        this.multipartPartSize = builder.multipartPartSize;
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getEndpoint() { return endpoint; }
    public String getBucket() { return bucket; }
    public String getPrefix() { return prefix; }
    public String getAccessKey() { return accessKey; }
    public String getSecretKey() { return secretKey; }
    public String getRegion() { return region; }
    public boolean isUseSsl() { return useSsl; }
    public boolean isUsePathStyle() { return usePathStyle; }
    public String getTlsCaPath() { return tlsCaPath; }
    public boolean isTlsInsecureSkipVerify() { return tlsInsecureSkipVerify; }
    public long getMultipartThreshold() { return multipartThreshold; }
    public long getMultipartPartSize() { return multipartPartSize; }

    /**
     * Builder for {@link S3Config}. {@code endpoint}, {@code bucket}, {@code accessKey}, and
     * {@code secretKey} are required; the rest default to secure, AWS-friendly values
     * (HTTPS on, virtual-hosted URLs, TLS verification enabled, built-in multipart sizing).
     */
    public static class Builder {
        private String endpoint;
        private String bucket;
        private String prefix = null;
        private String accessKey;
        private String secretKey;
        private String region = null;
        private boolean useSsl = true;
        private boolean usePathStyle = false;
        private String tlsCaPath = null;
        private boolean tlsInsecureSkipVerify = false;
        private long multipartThreshold = 0; // 0 = library default
        private long multipartPartSize = 0;  // 0 = library default

        /** S3 endpoint, e.g. "s3.amazonaws.com" or "minio.local:9000" (required). */
        public Builder endpoint(String endpoint) { this.endpoint = endpoint; return this; }

        /** Bucket name (required). */
        public Builder bucket(String bucket) { this.bucket = bucket; return this; }

        /** Key prefix, e.g. "production/db1/" (optional). */
        public Builder prefix(String prefix) { this.prefix = prefix; return this; }

        /** AWS access key ID (required). */
        public Builder accessKey(String accessKey) { this.accessKey = accessKey; return this; }

        /** AWS secret access key (required). */
        public Builder secretKey(String secretKey) { this.secretKey = secretKey; return this; }

        /** AWS region, e.g. "us-east-1"; null for MinIO/default. */
        public Builder region(String region) { this.region = region; return this; }

        /** 1 for HTTPS (default), 0 for HTTP. */
        public Builder useSsl(boolean useSsl) { this.useSsl = useSsl; return this; }

        /** Path-style URLs (MinIO) when true; virtual-hosted (AWS) when false (default). */
        public Builder usePathStyle(boolean usePathStyle) { this.usePathStyle = usePathStyle; return this; }

        /** Custom CA bundle file path, or null for the system bundle. */
        public Builder tlsCaPath(String tlsCaPath) { this.tlsCaPath = tlsCaPath; return this; }

        /**
         * Disable TLS peer and host verification when true (test only, insecure). Default false
         * keeps verification on.
         */
        public Builder tlsInsecureSkipVerify(boolean tlsInsecureSkipVerify) {
            this.tlsInsecureSkipVerify = tlsInsecureSkipVerify;
            return this;
        }

        /** Object size at/above which multipart upload is used; 0 uses the library default. */
        public Builder multipartThreshold(long multipartThreshold) {
            this.multipartThreshold = multipartThreshold;
            return this;
        }

        /** Multipart chunk size in bytes; 0 uses the library default. */
        public Builder multipartPartSize(long multipartPartSize) {
            this.multipartPartSize = multipartPartSize;
            return this;
        }

        public S3Config build() {
            if (endpoint == null || endpoint.isEmpty()) {
                throw new IllegalArgumentException("S3 endpoint is required");
            }
            if (bucket == null || bucket.isEmpty()) {
                throw new IllegalArgumentException("S3 bucket is required");
            }
            if (accessKey == null || accessKey.isEmpty()) {
                throw new IllegalArgumentException("S3 access key is required");
            }
            if (secretKey == null || secretKey.isEmpty()) {
                throw new IllegalArgumentException("S3 secret key is required");
            }
            return new S3Config(this);
        }
    }
}
