import 'dart:math';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:radix_pulse/radix_pulse.dart';

const int listSize = 1000000;
const int maxIntValue = 0x7FFFFFFF;
const int benchmarkRuns = 10;

// Helper function to run a benchmark multiple times and return the average
double measureAverage(BenchmarkBase benchmark) {
  double total = 0;
  for (int i = 0; i < benchmarkRuns; i++) {
    total += benchmark.measure();
  }
  return total / benchmarkRuns;
}

// --- Integer Benchmarks ---
class ListSortIntBenchmark extends BenchmarkBase {
  ListSortIntBenchmark() : super('List.sort() (int)');
  late List<int> list;

  @override
  void setup() {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextInt(maxIntValue));
  }

  @override
  void run() => list.sort();
}

class RadixSortIntBenchmark extends BenchmarkBase {
  RadixSortIntBenchmark() : super('radixSortInt()');
  late List<int> list;

  @override
  void setup() {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextInt(maxIntValue));
  }

  @override
  void run() => radixSortInt(list, signed: true);
}

// --- Double Benchmarks ---
class ListSortDoubleBenchmark extends BenchmarkBase {
  ListSortDoubleBenchmark() : super('List.sort() (double)');
  late List<double> list;

  @override
  void setup() {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextDouble() * 1000);
  }

  @override
  void run() => list.sort();
}

class RadixSortDoubleBenchmark extends BenchmarkBase {
  RadixSortDoubleBenchmark() : super('radixSortDouble()');
  late List<double> list;

  @override
  void setup() {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextDouble() * 1000);
  }

  @override
  void run() => radixSortDouble(list);
}

// --- BigInt Benchmarks ---
class ListSortBigIntBenchmark extends BenchmarkBase {
  ListSortBigIntBenchmark() : super('List.sort() (BigInt)');
  late List<BigInt> list;

  @override
  void setup() {
    final random = Random(0);
    list = List.generate(
      listSize,
      (_) => BigInt.from(random.nextInt(maxIntValue)),
    );
  }

  @override
  void run() => list.sort();
}

class RadixSortBigIntBenchmark extends BenchmarkBase {
  RadixSortBigIntBenchmark() : super('radixSortBigInt()');
  late List<BigInt> list;

  @override
  void setup() {
    final random = Random(0);
    list = List.generate(
      listSize,
      (_) => BigInt.from(random.nextInt(maxIntValue)),
    );
  }

  @override
  void run() => radixSortBigInt(list);
}

void main() {
  print('Running benchmarks (average of $benchmarkRuns runs)..\n');

  final results = <String, double>{};

  // Integer
  results['List.sort() (int)'] = measureAverage(ListSortIntBenchmark());
  results['radixSortInt()'] = measureAverage(RadixSortIntBenchmark());

  // Double
  results['List.sort() (double)'] = measureAverage(ListSortDoubleBenchmark());
  results['radixSortDouble()'] = measureAverage(RadixSortDoubleBenchmark());

  // BigInt
  results['List.sort() (BigInt)'] = measureAverage(ListSortBigIntBenchmark());
  results['radixSortBigInt()'] = measureAverage(RadixSortBigIntBenchmark());

  print('--- Benchmark Results ---');
  results.forEach((name, time) {
    print('$name: ${time.toStringAsFixed(2)} us');
  });
}
