package com.caldova.legacy.service;

import com.caldova.legacy.model.InventoryItem;
import com.caldova.legacy.model.OrderRequest;
import com.caldova.legacy.model.Product;
import com.caldova.legacy.model.PurchaseOrder;
import com.caldova.legacy.repository.InventoryRepository;
import com.caldova.legacy.repository.ProductRepository;
import com.caldova.legacy.repository.PurchaseOrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class OrderService {

    private final PurchaseOrderRepository purchaseOrderRepository;
    private final ProductRepository productRepository;
    private final InventoryRepository inventoryRepository;

    public OrderService(
        PurchaseOrderRepository purchaseOrderRepository,
        ProductRepository productRepository,
        InventoryRepository inventoryRepository
    ) {
        this.purchaseOrderRepository = purchaseOrderRepository;
        this.productRepository = productRepository;
        this.inventoryRepository = inventoryRepository;
    }

    public List<PurchaseOrder> getOrders() {
        return purchaseOrderRepository.findAll();
    }

    @Transactional
    public Optional<PurchaseOrder> createOrder(OrderRequest request) {
        Optional<Product> productOptional = productRepository.findById(request.getProductId());
        if (productOptional.isEmpty()) {
            return Optional.empty();
        }

        Product product = productOptional.get();
        InventoryItem inventoryItem = inventoryRepository.findAll()
            .stream()
            .filter(i -> i.getProduct().getId().equals(product.getId()))
            .findFirst()
            .orElse(null);

        if (inventoryItem == null || inventoryItem.getQuantityOnHand() < request.getQuantity()) {
            return Optional.empty();
        }

        inventoryItem.setQuantityOnHand(inventoryItem.getQuantityOnHand() - request.getQuantity());
        inventoryItem.setLastUpdated(LocalDateTime.now());
        inventoryRepository.save(inventoryItem);

        PurchaseOrder order = new PurchaseOrder();
        order.setProduct(product);
        order.setQuantity(request.getQuantity());
        order.setUnitPrice(product.getUnitPrice());
        order.setTotalPrice(product.getUnitPrice() * request.getQuantity());
        order.setStatus("CREATED");
        order.setCustomerName(request.getCustomerName());
        order.setCreatedAt(LocalDateTime.now());

        return Optional.of(purchaseOrderRepository.save(order));
    }
}
