package com.example.demo.service;

import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class CounterService {
    
    private final AtomicLong requestCounter = new AtomicLong(0);
    private final Map<String, AtomicLong> endpointCounters = new HashMap<>();

    public long incrementRequestCount() {
        return requestCounter.incrementAndGet();
    }

    public long getRequestCount() {
        return requestCounter.get();
    }

    public long incrementEndpointCount(String endpoint) {
        return endpointCounters.computeIfAbsent(endpoint, k -> new AtomicLong(0))
                .incrementAndGet();
    }

    public Map<String, Long> getAllEndpointCounts() {
        Map<String, Long> counts = new HashMap<>();
        endpointCounters.forEach((endpoint, counter) -> counts.put(endpoint, counter.get()));
        return counts;
    }
}