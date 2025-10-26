/// # radix_pulse
///
/// ⚡ A high-performance, parallelized Radix Sort library for Dart.
///
/// `radix_pulse` brings **native-like speed** to Dart’s sorting world.
/// It’s designed for developers who need *maximum performance*, *low GC pressure*,
/// and *fine-grained control* over memory and threading.
///
/// ## 🚀 Core Highlights
///
/// - **Multi-Type Sorting:** Supports `List<int>`, `List<double>`, and `List<BigInt>`.
/// - **Stable & Accurate:** Preserves order of equal elements and correctly handles
///   signed values, ±0, ±∞, and NaN.
/// - **TypedData Optimized:** Works directly with `Int32List`, `Uint32List`,
///   and `Float64List` for zero-copy performance.
/// - **Parallel Execution:** Leverages Isolates for large-scale data sorting.
/// - **Adaptive Hybrid Logic:** Automatically switches to insertion sort for
///   small segments to minimize overhead.
///
/// ## 🧠 Advanced Capabilities
///
/// - **Buffer Pooling:** Reuse pre-allocated buffers to reduce GC overhead.
/// - **Range Optimization:** Specialized `BigInt` routines with `maxBitLength` hints.
/// - **Custom Merge Strategies:** Control parallel merge behavior for massive datasets.
/// - **Performance Estimation:** Benchmark potential speedups with
///   `estimateParallelPerformance()`.
///
/// ## 🧰 API Overview
///
/// | Function | Description |
/// |-----------|--------------|
/// | `radixSortInt()` | Sorts any `List<int>` (signed/unsigned). |
/// | `radixSortDouble()` | Stable sort for doubles (handles ±∞, NaN). |
/// | `radixSortBigInt()` | Hybrid Radix Sort for arbitrary precision integers. |
/// | `radixSortFloat64()` | Zero-copy sorting for `Float64List`. |
/// | `radixSortParallelUnsigned()` | Multi-core sorting for large unsigned integer lists. |
/// | `clearBufferPools()` | Frees all global buffer pools to release memory. |
///
/// ## ⚙️ Example
///
/// ```dart
/// import 'package:radix_pulse/radix_pulse.dart';
///
/// void main() {
///   final data = List.generate(1000000, (i) => 1000000 - i);
///
///   // High-performance parallel radix sort
///   await radixSortParallelUnsigned(data);
///
///   print(data.take(10));
/// }
/// ```
///
///
library;

export 'src/radix_int.dart';
export 'src/radix_bigint.dart';
export 'src/radix_float.dart';
export 'src/parallel_sort_stub.dart'
    if (dart.library.io) 'src/parallel_sort.dart';
export 'src/utils.dart' show clearBufferPools;
