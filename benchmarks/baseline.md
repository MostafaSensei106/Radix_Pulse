# Baseline Benchmark Results

These results were captured on the initial implementation of `radixSortUnsigned` to establish a performance baseline.

## Environment

- **Date:** 2025-10-26
- **List Size:** 100,000 integers
- **Data:** Random 31-bit positive integers

## Results (in microseconds - µs)

| Benchmark                               | Average Runtime (µs) | Factor vs. List.sort() |
| --------------------------------------- | -------------------- | ---------------------- |
| `List.sort()`                           | 87,165               | 1.0x                   |
| `radixSortUnsigned (reuseBuffer: false)`| 20,757               | ~4.2x faster           |
| `radixSortUnsigned (reuseBuffer: true)` | 16,742               | ~5.2x faster           |

*Lower is better.*
