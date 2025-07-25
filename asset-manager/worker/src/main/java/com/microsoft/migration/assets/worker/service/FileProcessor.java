package com.microsoft.migration.assets.worker.service;

import java.nio.file.Path;

public interface FileProcessor {
    void downloadOriginal(String key, Path destination) throws Exception;
    void uploadThumbnail(Path source, String key, String contentType) throws Exception;
    String getStorageType();
}