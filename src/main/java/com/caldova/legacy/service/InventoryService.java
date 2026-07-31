package com.caldova.legacy.service;

import com.caldova.legacy.model.InventoryItem;
import com.caldova.legacy.repository.InventoryRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class InventoryService {

    private final InventoryRepository inventoryRepository;

    public InventoryService(InventoryRepository inventoryRepository) {
        this.inventoryRepository = inventoryRepository;
    }

    public List<InventoryItem> getInventory() {
        return inventoryRepository.findAll();
    }
}
