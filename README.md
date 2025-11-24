<h1 align="center">Radix Plus</h1>
<p align="center">
  <img src="https://socialify.git.ci/MostafaSensei106/Radix_Plus/image?custom_language=Dart&font=KoHo&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F138288138%3Fv%3D4&name=1&owner=1&pattern=Floating+Cogs&theme=Light" alt="Radix Plus Banner">
</p>

<p align="center">
  <strong>A high-performance, in-place Radix Sort library for Dart and Flutter.</strong><br>
  Fast. Efficient. Low-level sorting for number-intensive applications.
</p>

<p align="center">
  <a href="#about">About</a> •
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage-examples">Usage</a> •
  <a href="#benchmarks">Benchmarks</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

## About

Welcome to **Radix Plus** — a blazing-fast, in-place sorting library for Dart and Flutter.
Radix Plus provides a set of highly optimized, stable sorting algorithms that can be significantly faster than `List.sort()` for specific data types, especially large lists of numbers (`int`, `double`, and `BigInt`). It uses low-level byte manipulation to achieve top-tier performance, making it ideal for data-intensive applications, scientific computing, and real-time data processing.

---

## Features

### 🌟 Core Functionality

- **Multi-Type Support**: Sorts `List<int>`, `List<double>`, and `List<BigInt>`.
- **Stable Sort**: Preserves the relative order of equal elements.
- **Unified Integer API**: A single function, `radixSortInt`, handles both signed and unsigned integers.
- **Comprehensive Float Support**: `radixSortDouble` correctly handles positive/negative values, infinities, and zero.

### 🛠️ Advanced Capabilities

- **Parallel Sorting**: `radixSortParallelUnsigned` leverages multiple CPU cores using Isolates to sort very large lists even faster.
- **Memory Efficiency**: Includes a buffer pooling mechanism (`reuseBuffer: true`) to minimize GC pressure during frequent sorting tasks.
- **Zero-Copy Operations**: Works directly on `TypedData` lists (`Int32List`, `Float64List`, etc.) to avoid unnecessary memory copies.
- **Adaptive Algorithms**: Uses hybrid strategies (like switching to insertion sort for small sub-lists) for optimal performance across different data sizes.

---

## Installation

### 📦 Add to your project

1.  Add this to your package's `pubspec.yaml` file:

    ```yaml
    dependencies:
      radix_Pluse: ^1.0.0 # Replace with the latest version
    ```

2.  Install it from your terminal:

    ```bash
    dart pub get
    ```

    or

    ```bash
    flutter pub get
    ```

---

## 🚀 Quick Start

Import the library and call the appropriate sorting function.

```dart
import 'package:radix_Plus/radix_Plus.dart';

// Sort a list of signed integers
final numbers = [40, -1, 900, -10, 0, 5];
radixSortInt(numbers); // Automatically handles signed integers
print(numbers); // [-10, -1, 0, 5, 40, 900]
```

---

## 📋 Usage Examples

### Sorting Integers

Use `radixSortInt` for both signed and unsigned integer lists.

```dart
// Sort a list of signed integers (ascending)
final signedNumbers = [40, -1, 900, -10, 0, 5];
radixSortInt(signedNumbers, ascending: true);
print(signedNumbers); // [-10, -1, 0, 5, 40, 900]

// Sort a list of unsigned integers (descending)
final unsignedNumbers = [40, 1, 900, 10, 5];
radixSortInt(unsignedNumbers, signed: false, ascending: false);
print(unsignedNumbers); // [900, 40, 10, 5, 1]
```

### Sorting Doubles

Use `radixSortDouble` for `List<double>`.

```dart
final doubleNumbers = [10.5, -1.2, 900.0, -10.0, 0.0];
radixSortDouble(doubleNumbers);
print(doubleNumbers); // [-10.0, -1.2, 0.0, 10.5, 900.0]
```

### Sorting BigInts

Use `radixSortBigInt` for `List<BigInt>`.

```dart
final bigIntNumbers = [
  BigInt.parse('100000000000000000000'),
  BigInt.from(-100),
  BigInt.parse('-200000000000000000000'),
  BigInt.zero,
];
radixSortBigInt(bigIntNumbers);
print(bigIntNumbers);
```

### Parallel Sorting

For very large lists, `radixSortParallelUnsigned` can provide a significant speed boost.

> **Note**: Parallel sorting is not available on the Web platform.

```dart
// A large list of numbers
final largeList = List.generate(1000000, (i) => 999999 - i);

// Sort it in parallel across multiple isolates
await radixSortParallelUnsigned(largeList);

print(largeList.first); // 0
print(largeList.last); // 999999
```

---

## 🚀 Blazing Fast Performance

Performance is the core feature of Radix Plus. Our algorithms are consistently faster than the standard `List.sort()` for large numerical datasets, often by a significant margin.

To ensure accuracy, the results below are the **average of 10 separate benchmark runs** on a standard development machine, each sorting a list of **1,000,000 random elements**.

### Sorting `List<int>` (32-bit Signed Integers)

| Method             | Average Time (ms) | Speedup vs. `List.sort()` |
| ------------------ | ----------------- | ------------------------- |
| `List.sort()`      | ~1071             | 1.0x                      |
| **`radixSortInt`** | **~312**          | **~3.4x faster**          |

### Sorting `List<double>` (64-bit Doubles)

| Method                | Average Time (ms) | Speedup vs. `List.sort()` |
| --------------------- | ----------------- | ------------------------- |
| `List.sort()`         | ~3623             | 1.0x                      |
| **`radixSortDouble`** | **~916**          | **~4.0x faster**          |

### Sorting `List<BigInt>`

| Method                | Average Time (ms) | Speedup vs. `List.sort()` |
| --------------------- | ----------------- | ------------------------- |
| `List.sort()`         | ~9579             | 1.0x                      |
| **`radixSortBigInt`** | **~1621**         | **~5.9x faster**          |

---

_Your results may vary based on hardware, data distribution, and list size. For more details on the methodology, see the [benchmark/results.md](./benchmark/results.md) file._

---

## Technologies

| Technology               | Description                                                                |
| ------------------------ | -------------------------------------------------------------------------- |
| 🧠 **Dart**              | [dart.dev](https://dart.dev) — The core language for the library.          |
| ⚡ **Isolates**          | `dart:isolate` — Used for parallel sorting to leverage multiple CPU cores. |
| 💾 **TypedData**         | `dart:typed_data` — Used for low-level, efficient memory manipulation.     |
| 🧪 **benchmark_harness** | A framework for creating and running performance benchmarks.               |

---

## Contributing

Contributions are welcome! Here’s how to get started:

1.  Fork the repository.
2.  Create a new branch:
    `git checkout -b feature/YourFeature`
3.  Commit your changes:
    `git commit -m "Add amazing feature"`
4.  Push to your branch:
    `git push origin feature/YourFeature`
5.  Open a pull request.

> 💡 Please read our [Contributing Guidelines](./CONTRIBUTING.md) and open an issue first for major feature ideas or changes.

---

## License

This project is licensed under the **GPL-V3.0 License**.
See the [LICENSE](LICENSE) file for full details.

<p align="center">
  Made with ❤️ by <a href="https://github.com/MostafaSensei106">MostafaSensei106</a>
</p>
