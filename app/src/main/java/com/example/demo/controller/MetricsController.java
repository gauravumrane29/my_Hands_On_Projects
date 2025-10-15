package com.example.demo.controller;

import com.example.demo.service.CounterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/metrics")
public class MetricsController {

    @Autowired
    private CounterService counterService;

    @GetMapping("/requests")
    public ResponseEntity<Map<String, Object>> getRequestMetrics() {
        Map<String, Object> metrics = new HashMap<>();
        metrics.put("totalRequests", counterService.getRequestCount());
        metrics.put("endpointCounts", counterService.getAllEndpointCounts());
        return ResponseEntity.ok(metrics);
    }
}