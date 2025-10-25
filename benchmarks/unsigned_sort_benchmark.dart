import 'dart:math';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:radix_pulse/src/radix_unsigned.dart';

// A common setup for our benchmarks to ensure they run on the same data.
const int listSize = 100000;
final Random random = Random(123); // Seed for reproducibility
late List<int> unsortedData;

void setupData() {
  unsortedData = List.generate(listSize, (_) => random.nextInt(0x7FFFFFFF));
}

// Benchmark for the standard List.sort()
class ListSortBenchmark extends BenchmarkBase {
  late List<int> data;

  ListSortBenchmark() : super('List.sort()');

  @override
  void setup() {
    data = List.of(unsortedData);
  }

  @override
  void run() {
    data.sort();
  }
}

// Benchmark for radixSortUnsigned without buffer reuse
class RadixSortBenchmark extends BenchmarkBase {
  late List<int> data;

  RadixSortBenchmark() : super('radixSortUnsigned (reuseBuffer: false)');

  @override
  void setup() {
    data = List.of(unsortedData);
  }

  @override
  void run() {
    radixSortUnsigned(data, reuseBuffer: false);
  }
}

// Benchmark for radixSortUnsigned with buffer reuse
class RadixSortReuseBufferBenchmark extends BenchmarkBase {
  late List<int> data;

  RadixSortReuseBufferBenchmark()
    : super('radixSortUnsigned (reuseBuffer: true)');

  @override
  void setup() {
    data = List.of(unsortedData);
  }

  @override
  void run() {
    radixSortUnsigned(data, reuseBuffer: true);
  }
}

void main() {
  // Setup the data once for all benchmarks
  setupData();

  // Run the benchmarks
  ListSortBenchmark().report();
  RadixSortBenchmark().report();
  RadixSortReuseBufferBenchmark().report();
}
