# Benchmark Results

This document tracks the performance of Radix Pulse sorting algorithms compared to the standard `List.sort()`.

## Environment

- **Dart SDK:** 3.9.2
- **Machine:** (Results from a typical development machine)

## Methodology

To ensure accuracy, the results below are the average of **10 separate benchmark runs**. Each run sorts a list of 1,000,000 randomly generated elements.

## Results

### Sorting `List<int>` (1,000,000 Random 32-bit Signed Integers)

| Method                  | Average Time (ms) | Speedup vs. `List.sort()` |
| ----------------------- | ----------------- | ------------------------- |
| **Before (List.sort)**  | ~1071             | 1.0x                      |
| **After (radixSortInt)**| ~312              | **~3.4x faster**          |

### Sorting `List<double>` (1,000,000 Random Doubles)

| Method                    | Average Time (ms) | Speedup vs. `List.sort()` |
| ------------------------- | ----------------- | ------------------------- |
| **Before (List.sort)**    | ~3623             | 1.0x                      |
| **After (radixSortDouble)**| ~916              | **~4.0x faster**          |

### Sorting `List<BigInt>` (1,000,000 Random BigInts)

| Method                    | Average Time (ms) | Speedup vs. `List.sort()` |
| ------------------------- | ----------------- | ------------------------- |
| **Before (List.sort)**    | ~9579             | 1.0x                      |
| **After (radixSortBigInt)**| ~1621             | **~5.9x faster**          |

---

*To run the benchmarks yourself, navigate to the `test` directory and run `dart test/benchmark.dart`.*
