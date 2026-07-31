package com.caldova.legacy.controller;

import com.caldova.legacy.model.OrderRequest;
import com.caldova.legacy.model.PurchaseOrder;
import com.caldova.legacy.service.OrderService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import javax.servlet.http.HttpServletRequest;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@RestController
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping("/orders")
    public List<PurchaseOrder> getOrders() {
        return orderService.getOrders();
    }

    @PostMapping("/orders")
    public ResponseEntity<PurchaseOrder> createOrder(
        @Valid @RequestBody OrderRequest request,
        HttpServletRequest servletRequest
    ) {
        Optional<PurchaseOrder> created = orderService.createOrder(request);
        if (created.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        return ResponseEntity.ok()
            .header("X-Legacy-Client-IP", servletRequest.getRemoteAddr())
            .body(created.get());
    }
}
