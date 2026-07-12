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
 * Statistics about a column family.
 */
public class Stats {

    private final int numLevels;
    private final long memtableSize;
    private final long[] levelSizes;
    private final int[] levelNumSSTables;
    private final ColumnFamilyConfig config;
    private final long totalKeys;
    private final long totalDataSize;
    private final double avgKeySize;
    private final double avgValueSize;
    private final long[] levelKeyCounts;
    private final double readAmp;
    private final double hitRate;
    private final boolean useBtree;
    private final long btreeTotalNodes;
    private final int btreeMaxHeight;
    private final double btreeAvgHeight;
    private final long totalTombstones;
    private final double tombstoneRatio;
    private final long[] levelTombstoneCounts;
    private final double maxSstDensity;
    private final int maxSstDensityLevel;
    private final long walBytesWritten;
    private final long flushBytesWritten;
    private final long compactionBytesWritten;
    private final long compactionBytesRead;
    private final long userBytesWritten;
    private final long flushCount;
    private final long compactionCount;

    public Stats(int numLevels, long memtableSize, long[] levelSizes, int[] levelNumSSTables,
                 ColumnFamilyConfig config, long totalKeys, long totalDataSize,
                 double avgKeySize, double avgValueSize, long[] levelKeyCounts,
                 double readAmp, double hitRate, boolean useBtree, long btreeTotalNodes,
                 int btreeMaxHeight, double btreeAvgHeight,
                 long totalTombstones, double tombstoneRatio, long[] levelTombstoneCounts,
                 double maxSstDensity, int maxSstDensityLevel,
                 long walBytesWritten, long flushBytesWritten, long compactionBytesWritten,
                 long compactionBytesRead, long userBytesWritten, long flushCount,
                 long compactionCount) {
        this.numLevels = numLevels;
        this.memtableSize = memtableSize;
        this.levelSizes = levelSizes;
        this.levelNumSSTables = levelNumSSTables;
        this.config = config;
        this.totalKeys = totalKeys;
        this.totalDataSize = totalDataSize;
        this.avgKeySize = avgKeySize;
        this.avgValueSize = avgValueSize;
        this.levelKeyCounts = levelKeyCounts;
        this.readAmp = readAmp;
        this.hitRate = hitRate;
        this.useBtree = useBtree;
        this.btreeTotalNodes = btreeTotalNodes;
        this.btreeMaxHeight = btreeMaxHeight;
        this.btreeAvgHeight = btreeAvgHeight;
        this.totalTombstones = totalTombstones;
        this.tombstoneRatio = tombstoneRatio;
        this.levelTombstoneCounts = levelTombstoneCounts;
        this.maxSstDensity = maxSstDensity;
        this.maxSstDensityLevel = maxSstDensityLevel;
        this.walBytesWritten = walBytesWritten;
        this.flushBytesWritten = flushBytesWritten;
        this.compactionBytesWritten = compactionBytesWritten;
        this.compactionBytesRead = compactionBytesRead;
        this.userBytesWritten = userBytesWritten;
        this.flushCount = flushCount;
        this.compactionCount = compactionCount;
    }

    /**
     * Gets the number of levels.
     *
     * @return the number of levels
     */
    public int getNumLevels() {
        return numLevels;
    }

    /**
     * Gets the memtable size in bytes.
     *
     * @return the memtable size
     */
    public long getMemtableSize() {
        return memtableSize;
    }

    /**
     * Gets the sizes of each level in bytes.
     *
     * @return array of level sizes
     */
    public long[] getLevelSizes() {
        return levelSizes;
    }

    /**
     * Gets the number of SSTables at each level.
     *
     * @return array of SSTable counts per level
     */
    public int[] getLevelNumSSTables() {
        return levelNumSSTables;
    }

    /**
     * Gets the column family configuration.
     *
     * @return the configuration
     */
    public ColumnFamilyConfig getConfig() {
        return config;
    }

    /**
     * Gets the total number of keys across memtable and all SSTables.
     *
     * @return total key count
     */
    public long getTotalKeys() {
        return totalKeys;
    }

    /**
     * Gets the total data size (klog + vlog) across all SSTables.
     *
     * @return total data size in bytes
     */
    public long getTotalDataSize() {
        return totalDataSize;
    }

    /**
     * Gets the average key size in bytes.
     *
     * @return average key size
     */
    public double getAvgKeySize() {
        return avgKeySize;
    }

    /**
     * Gets the average value size in bytes.
     *
     * @return average value size
     */
    public double getAvgValueSize() {
        return avgValueSize;
    }

    /**
     * Gets the number of keys per level.
     *
     * @return array of key counts per level
     */
    public long[] getLevelKeyCounts() {
        return levelKeyCounts;
    }

    /**
     * Gets the read amplification (point lookup cost multiplier).
     *
     * @return read amplification factor
     */
    public double getReadAmp() {
        return readAmp;
    }

    /**
     * Gets the cache hit rate for this column family.
     *
     * @return hit rate (0.0 to 1.0), or 0.0 if cache is disabled
     */
    public double getHitRate() {
        return hitRate;
    }

    /**
     * Returns whether this column family uses B+tree format.
     *
     * @return true if B+tree format is used
     */
    public boolean isUseBtree() {
        return useBtree;
    }

    /**
     * Gets the total number of B+tree nodes across all SSTables.
     * Only populated when useBtree is true.
     *
     * @return total B+tree nodes
     */
    public long getBtreeTotalNodes() {
        return btreeTotalNodes;
    }

    /**
     * Gets the maximum B+tree height across all SSTables.
     * Only populated when useBtree is true.
     *
     * @return maximum tree height
     */
    public int getBtreeMaxHeight() {
        return btreeMaxHeight;
    }

    /**
     * Gets the average B+tree height across all SSTables.
     * Only populated when useBtree is true.
     *
     * @return average tree height
     */
    public double getBtreeAvgHeight() {
        return btreeAvgHeight;
    }

    /**
     * Gets the total number of tombstones across every SSTable in the column family.
     *
     * @return total tombstone count
     */
    public long getTotalTombstones() {
        return totalTombstones;
    }

    /**
     * Gets the tombstone ratio (totalTombstones / totalKeys).
     * Returns 0.0 when totalKeys is 0. Always within [0.0, 1.0].
     *
     * @return tombstone ratio
     */
    public double getTombstoneRatio() {
        return tombstoneRatio;
    }

    /**
     * Gets the per-level tombstone counts. Length matches numLevels and parallels
     * {@link #getLevelKeyCounts()}.
     *
     * @return per-level tombstone counts
     */
    public long[] getLevelTombstoneCounts() {
        return levelTombstoneCounts;
    }

    /**
     * Gets the worst per-SSTable tombstone density (tombstone_count / num_entries)
     * observed in this column family. Always within [0.0, 1.0].
     *
     * @return max per-SSTable tombstone density
     */
    public double getMaxSstDensity() {
        return maxSstDensity;
    }

    /**
     * Gets the 1-based level index where the worst per-SSTable tombstone density
     * was observed. Returns 0 if no SSTable contributed to the measurement.
     *
     * @return 1-based level index of the worst SSTable, or 0 if none
     */
    public int getMaxSstDensityLevel() {
        return maxSstDensityLevel;
    }

    /**
     * Gets the framed bytes appended to this column family's WAL (lifetime since open).
     * Always 0 in unified memtable mode, where the shared WAL volume is reported db-wide
     * via {@link DbStats#getUwalBytesWritten()}.
     *
     * @return WAL bytes written
     */
    public long getWalBytesWritten() {
        return walBytesWritten;
    }

    /**
     * Gets the on-disk bytes this column family's flushes wrote to L0 SSTables
     * (lifetime since open).
     *
     * @return flush output bytes written
     */
    public long getFlushBytesWritten() {
        return flushBytesWritten;
    }

    /**
     * Gets the on-disk bytes this column family's compactions wrote (lifetime since open).
     *
     * @return compaction output bytes written
     */
    public long getCompactionBytesWritten() {
        return compactionBytesWritten;
    }

    /**
     * Gets the on-disk bytes this column family's compactions read as input
     * (lifetime since open).
     *
     * @return compaction input bytes read
     */
    public long getCompactionBytesRead() {
        return compactionBytesRead;
    }

    /**
     * Gets the logical key+value bytes committed to this column family (lifetime since open).
     * This is the write-amplification denominator: divide the WAL, flush, and compaction
     * write totals by this value to compute write amplification.
     *
     * @return user bytes written
     */
    public long getUserBytesWritten() {
        return userBytesWritten;
    }

    /**
     * Gets the number of flushed SSTables produced by this column family (lifetime since open).
     *
     * @return flush count
     */
    public long getFlushCount() {
        return flushCount;
    }

    /**
     * Gets the number of compaction output SSTables produced by this column family
     * (lifetime since open).
     *
     * @return compaction count
     */
    public long getCompactionCount() {
        return compactionCount;
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("Stats{numLevels=").append(numLevels);
        sb.append(", memtableSize=").append(memtableSize);
        sb.append(", totalKeys=").append(totalKeys);
        sb.append(", totalDataSize=").append(totalDataSize);
        sb.append(", avgKeySize=").append(avgKeySize);
        sb.append(", avgValueSize=").append(avgValueSize);
        sb.append(", readAmp=").append(readAmp);
        sb.append(", hitRate=").append(hitRate);
        sb.append(", useBtree=").append(useBtree);
        if (useBtree) {
            sb.append(", btreeTotalNodes=").append(btreeTotalNodes);
            sb.append(", btreeMaxHeight=").append(btreeMaxHeight);
            sb.append(", btreeAvgHeight=").append(btreeAvgHeight);
        }
        sb.append(", totalTombstones=").append(totalTombstones);
        sb.append(", tombstoneRatio=").append(tombstoneRatio);
        sb.append(", maxSstDensity=").append(maxSstDensity);
        sb.append(", maxSstDensityLevel=").append(maxSstDensityLevel);
        sb.append(", walBytesWritten=").append(walBytesWritten);
        sb.append(", flushBytesWritten=").append(flushBytesWritten);
        sb.append(", compactionBytesWritten=").append(compactionBytesWritten);
        sb.append(", compactionBytesRead=").append(compactionBytesRead);
        sb.append(", userBytesWritten=").append(userBytesWritten);
        sb.append(", flushCount=").append(flushCount);
        sb.append(", compactionCount=").append(compactionCount);
        if (levelSizes != null) {
            sb.append(", levelSizes=[");
            for (int i = 0; i < levelSizes.length; i++) {
                if (i > 0) sb.append(", ");
                sb.append(levelSizes[i]);
            }
            sb.append("]");
        }
        if (levelNumSSTables != null) {
            sb.append(", levelNumSSTables=[");
            for (int i = 0; i < levelNumSSTables.length; i++) {
                if (i > 0) sb.append(", ");
                sb.append(levelNumSSTables[i]);
            }
            sb.append("]");
        }
        if (levelKeyCounts != null) {
            sb.append(", levelKeyCounts=[");
            for (int i = 0; i < levelKeyCounts.length; i++) {
                if (i > 0) sb.append(", ");
                sb.append(levelKeyCounts[i]);
            }
            sb.append("]");
        }
        if (levelTombstoneCounts != null) {
            sb.append(", levelTombstoneCounts=[");
            for (int i = 0; i < levelTombstoneCounts.length; i++) {
                if (i > 0) sb.append(", ");
                sb.append(levelTombstoneCounts[i]);
            }
            sb.append("]");
        }
        sb.append("}");
        return sb.toString();
    }
}
