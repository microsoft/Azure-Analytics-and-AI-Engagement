package com.caldova.legacy.controller;

import com.caldova.legacy.model.InventoryItem;
import com.caldova.legacy.service.InventoryService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class InventoryController {

    private final InventoryService inventoryService;

    public InventoryController(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @GetMapping("/inventory")
    public List<InventoryItem> getInventory() {
        return inventoryService.getInventory();
    }
}
