package com.microsoft.migration.assets.worker.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ImageProcessingMessage {
    private String key;
    private String contentType;
    private String storageType; // "s3" or "local"
    private long size;
}