package com.microsoft.migration.assets.worker.repository;

import com.microsoft.migration.assets.worker.model.ImageMetadata;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ImageMetadataRepository extends JpaRepository<ImageMetadata, String> {
    // Basic CRUD operations are automatically provided by JpaRepository
}