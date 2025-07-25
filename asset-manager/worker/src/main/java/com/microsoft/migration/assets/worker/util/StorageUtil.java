package com.microsoft.migration.assets.worker.util;

public class StorageUtil {
    /**
     * Get the thumbnail key for a given key
     */
    public static String getThumbnailKey(String key) {
        int dotIndex = key.lastIndexOf('.');
        if (dotIndex > 0) {
            return key.substring(0, dotIndex) + "_thumbnail" + key.substring(dotIndex);
        }
        return key + "_thumbnail";
    }

    /**
     * Get file extension from a key or filename
     */
    public static String getExtension(String filename) {
        int dotIndex = filename.lastIndexOf('.');
        return dotIndex > 0 ? filename.substring(dotIndex) : "";
    }
}