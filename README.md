# Radix Pulse

[![pub version](https://img.shields.io/pub/v/radix_pulse.svg)](https://pub.dev/packages/radix_pulse)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A high-performance, in-place Radix Sort implementation for Dart and Flutter.

Radix Pulse provides a set of highly optimized, stable sorting algorithms that can be significantly faster than `List.sort()` for specific data types, especially large lists of numbers.

## Features

- **High-Performance Sorting**: Optimized for speed using low-level byte operations.
- **Unified Integer API**: Sort `List<int>` with a single function, `radixSortInt`, for both signed and unsigned integers.
- **Floating-Point Support**: Sort `List<double>` with `radixSortDouble`, correctly handling positive/negative values, infinities, and zero.
- **Parallel Sorting**: `radixSortParallelUnsigned` leverages multiple CPU cores using Isolates to sort very large lists even faster.
- **Memory Efficient**: Includes options for buffer reuse to minimize GC pressure on frequent sorting tasks.
- **Stable Sort**: Preserves the relative order of equal elements.

## Getting Started

### Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  radix_pulse: ^1.0.0 # Replace with the latest version
```

Then, run `dart pub get` or `flutter pub get`.

## Usage

Import the library:

```dart
import 'package:radix_pulse/radix_pulse.dart';
```

### Sorting Integers

Use `radixSortInt` for both signed and unsigned integer lists.

```dart
// Sort a list of signed integers
final signedNumbers = [40, -1, 900, -10, 0, 5];
radixSortInt(signedNumbers, signed: true);
print(signedNumbers); // [-10, -1, 0, 5, 40, 900]

// Sort a list of unsigned integers
final unsignedNumbers = [40, 1, 900, 10, 5];
radixSortInt(unsignedNumbers, signed: false);
print(unsignedNumbers); // [1, 5, 10, 40, 900]
```

### Sorting Doubles

Use `radixSortDouble` for `List<double>`.

```dart
final doubleNumbers = [10.5, -1.2, 900.0, -10.0, 0.0];
radixSortDouble(doubleNumbers);
print(doubleNumbers); // [-10.0, -1.2, 0.0, 10.5, 900.0]
```

### Parallel Sorting

For very large lists, you can use `radixSortParallelUnsigned` to speed up sorting by using multiple isolates.

```dart
// A large list of numbers
final largeList = List.generate(100000, (i) => 99999 - i);

// Sort it in parallel across 4 threads
await radixSortParallelUnsigned(largeList, threads: 4);

print(largeList.first); // 0
print(largeList.last); // 99999
```

## Performance

Radix sort is not always faster than the default `List.sort()` (which uses IntroSort). It excels with large lists of numbers (integers or floats).

**Baseline Benchmark (100,000 random 31-bit integers):**

| Benchmark                               | Average Runtime (µs) | Factor vs. List.sort() |
| --------------------------------------- | -------------------- | ---------------------- |
| `List.sort()`                           | 87,165               | 1.0x                   |
| `radixSortInt (unsigned)`               | 16,742               | ~5.2x faster           |

*Lower is better. Your results may vary.*

## Additional Information

This package is under active development. For more details, please see the [API documentation](https://pub.dev/documentation/radix_pulse/latest/).

To file issues or contribute to the package, please visit the [GitHub repository](https://github.com/your_org/radix_pulse).