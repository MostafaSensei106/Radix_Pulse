# Benchmark Results

This document tracks the performance of Radix Pulse sorting algorithms compared to the standard `List.sort()`.

## Environment

- **Dart SDK:** 3.9.2
- **Machine:** (Results from a typical development machine)

## Results

Benchmarks are run on lists of 1,000,000 elements.

### Sorting `List<int>` (1,000,000 Random 32-bit Signed Integers)

| Method                  | Average Time (ms) | Speedup vs. `List.sort()` |
| ----------------------- | ----------------- | ------------------------- |
| **Before (List.sort)**  | ~1020             | 1.0x                      |
| **After (radixSortInt)**| ~281              | **~3.6x faster**          |

### Sorting `List<double>` (1,000,000 Random Doubles)

| Method                    | Average Time (ms) | Speedup vs. `List.sort()` |
| ------------------------- | ----------------- | ------------------------- |
| **Before (List.sort)**    | ~4083             | 1.0x                      |
| **After (radixSortDouble)**| ~776              | **~5.3x faster**          |

### Sorting `List<BigInt>` (1,000,000 Random BigInts)

| Method                    | Average Time (ms) | Speedup vs. `List.sort()` |
| ------------------------- | ----------------- | ------------------------- |
| **Before (List.sort)**    | ~8666             | 1.0x                      |
| **After (radixSortBigInt)**| ~1481             | **~5.8x faster**          |

---

*To run the benchmarks yourself, navigate to the `test` directory and run `dart test/benchmark.dart`.*