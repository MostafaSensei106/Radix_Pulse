import 'dart:math';
import 'dart:typed_data';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:radix_plus/radix_plus.dart';

// --- Configuration ---
const int listSize = 1000000;
const int maxIntValue = 0x7FFFFFFF;
const int benchmarkRuns = 10;

// --- Logging Utility ---
String _timestamp() {
  final now = DateTime.now();
  final h = now.hour.toString().padLeft(2, '0');
  final m = now.minute.toString().padLeft(2, '0');
  final s = now.second.toString().padLeft(2, '0');
  return '[$h:$m:$s]';
}

void log(String message) {
  print('${_timestamp()} $message');
}

// --- Base Classes for Logging ---

abstract class LoggingBenchmarkBase extends BenchmarkBase {
  LoggingBenchmarkBase(super.name);

  void generateData();

  @override
  void setup() {
    log('    setup(): generating data...');
    generateData();
    log('    setup(): data ready ($listSize items)');
  }
}

abstract class LoggingAsyncBenchmarkBase extends AsyncBenchmarkBase {
  LoggingAsyncBenchmarkBase(super.name);

  Future<void> generateData();

  @override
  Future<void> setup() async {
    log('    setup(): generating data...');
    await generateData();
    log('    setup(): data ready ($listSize items)');
  }
}

// --- Helper Functions ---
double measureAverage(LoggingBenchmarkBase benchmark) {
  log('► START benchmark: ${benchmark.name}');
  double total = 0;
  for (int i = 0; i < benchmarkRuns; i++) {
    log('  • Run ${i + 1}/$benchmarkRuns (${benchmark.name})');
    final elapsed = benchmark.measure();
    total += elapsed;
    log('    ✓ Done run ${i + 1}');
  }
  final average = total / benchmarkRuns;
  log('■ END benchmark: ${benchmark.name}');
  return average;
}

Future<double> measureAverageAsync(LoggingAsyncBenchmarkBase benchmark) async {
  log('► START benchmark: ${benchmark.name} (async)');
  double total = 0;
  for (int i = 0; i < benchmarkRuns; i++) {
    log('  • Run ${i + 1}/$benchmarkRuns (${benchmark.name})');
    final elapsed = await benchmark.measure();
    total += elapsed;
    log('    ✓ Done run ${i + 1}');
  }
  final average = total / benchmarkRuns;
  log('■ END benchmark: ${benchmark.name} (async)');
  return average;
}

// --- Integer Benchmarks ---
class ListSortIntBenchmark extends LoggingBenchmarkBase {
  ListSortIntBenchmark() : super('List.sort() (int)');
  late List<int> list;

  @override
  void generateData() {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextInt(maxIntValue));
  }

  @override
  void run() => list.sort();
}

class RadixSortIntBenchmark extends LoggingBenchmarkBase {
  RadixSortIntBenchmark() : super('radixSortInt()');
  late List<int> list;

  @override
  void generateData() {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextInt(maxIntValue));
  }

  @override
  void run() => radixSortInt(list, signed: true);
}

class ListSortInt32Benchmark extends LoggingBenchmarkBase {
  ListSortInt32Benchmark() : super('List.sort() (Int32List)');
  late Int32List list;

  @override
  void generateData() {
    final random = Random(0);
    list = Int32List.fromList(
      List.generate(listSize, (_) => random.nextInt(maxIntValue)),
    );
  }

  @override
  void run() => list.sort();
}

class RadixSortInt32Benchmark extends LoggingBenchmarkBase {
  RadixSortInt32Benchmark() : super('radixSortInt32()');
  late Int32List list;

  @override
  void generateData() {
    final random = Random(0);
    list = Int32List.fromList(
      List.generate(listSize, (_) => random.nextInt(maxIntValue)),
    );
  }

  @override
  void run() => radixSortInt32(list);
}

class ListSortUint32Benchmark extends LoggingBenchmarkBase {
  ListSortUint32Benchmark() : super('List.sort() (Uint32List)');
  late Uint32List list;

  @override
  void generateData() {
    final random = Random(0);
    list = Uint32List.fromList(
      List.generate(listSize, (_) => random.nextInt(maxIntValue)),
    );
  }

  @override
  void run() => list.sort();
}

class RadixSortUint32Benchmark extends LoggingBenchmarkBase {
  RadixSortUint32Benchmark() : super('radixSortUint32()');
  late Uint32List list;

  @override
  void generateData() {
    final random = Random(0);
    list = Uint32List.fromList(
      List.generate(listSize, (_) => random.nextInt(maxIntValue)),
    );
  }

  @override
  void run() => radixSortUint32(list);
}

// --- Double Benchmarks ---
class ListSortDoubleBenchmark extends LoggingBenchmarkBase {
  ListSortDoubleBenchmark() : super('List.sort() (double)');
  late List<double> list;

  @override
  void generateData() {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextDouble() * 1000);
  }

  @override
  void run() => list.sort();
}

class RadixSortDoubleBenchmark extends LoggingBenchmarkBase {
  RadixSortDoubleBenchmark() : super('radixSortDouble()');
  late List<double> list;

  @override
  void generateData() {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextDouble() * 1000);
  }

  @override
  void run() => radixSortDouble(list);
}

class ListSortFloat64Benchmark extends LoggingBenchmarkBase {
  ListSortFloat64Benchmark() : super('List.sort() (Float64List)');
  late Float64List list;

  @override
  void generateData() {
    final random = Random(0);
    list = Float64List.fromList(
      List.generate(listSize, (_) => random.nextDouble() * 1000),
    );
  }

  @override
  void run() => list.sort();
}

class RadixSortFloat64Benchmark extends LoggingBenchmarkBase {
  RadixSortFloat64Benchmark() : super('radixSortFloat64()');
  late Float64List list;

  @override
  void generateData() {
    final random = Random(0);
    list = Float64List.fromList(
      List.generate(listSize, (_) => random.nextDouble() * 1000),
    );
  }

  @override
  void run() => radixSortFloat64(list);
}

class RadixSortFloat64WithNaNBenchmark extends LoggingBenchmarkBase {
  RadixSortFloat64WithNaNBenchmark() : super('radixSortFloat64WithNaN()');
  late Float64List list;

  @override
  void generateData() {
    final random = Random(0);
    list = Float64List.fromList(
      List.generate(
        listSize,
        (i) => i.isEven ? double.nan : random.nextDouble() * 1000,
      ),
    );
  }

  @override
  void run() => radixSortFloat64WithNaN(list);
}

// --- BigInt Benchmarks ---
class ListSortBigIntBenchmark extends LoggingBenchmarkBase {
  ListSortBigIntBenchmark() : super('List.sort() (BigInt)');
  late List<BigInt> list;

  @override
  void generateData() {
    final random = Random(0);
    list = List.generate(
      listSize,
      (_) => BigInt.from(random.nextInt(maxIntValue)),
    );
  }

  @override
  void run() => list.sort();
}

class RadixSortBigIntBenchmark extends LoggingBenchmarkBase {
  RadixSortBigIntBenchmark() : super('radixSortBigInt()');
  late List<BigInt> list;

  @override
  void generateData() {
    final random = Random(0);
    list = List.generate(
      listSize,
      (_) => BigInt.from(random.nextInt(maxIntValue)),
    );
  }

  @override
  void run() => radixSortBigInt(list);
}

class RadixSortBigIntWithRangeBenchmark extends LoggingBenchmarkBase {
  RadixSortBigIntWithRangeBenchmark() : super('radixSortBigIntWithRange()');
  late List<BigInt> list;

  @override
  void generateData() {
    final random = Random(0);
    list = List.generate(
      listSize,
      (_) => BigInt.from(random.nextInt(1 << 30)), // maxBitLength = 30
    );
  }

  @override
  void run() => radixSortBigIntWithRange(list, maxBitLength: 30);
}

// --- Parallel Benchmarks ---
class RadixSortParallelUnsignedBenchmark extends LoggingAsyncBenchmarkBase {
  RadixSortParallelUnsignedBenchmark() : super('radixSortParallelUnsigned()');
  late List<int> list;

  @override
  Future<void> generateData() async {
    final random = Random(0);
    list = List.generate(listSize, (_) => random.nextInt(maxIntValue));
  }

  @override
  Future<void> run() => radixSortParallelUnsigned(list);
}

class RadixSortParallelSignedBenchmark extends LoggingAsyncBenchmarkBase {
  RadixSortParallelSignedBenchmark() : super('radixSortParallelSigned()');
  late List<int> list;

  @override
  Future<void> generateData() async {
    final random = Random(0);
    list = List.generate(
      listSize,
      (_) => random.nextInt(maxIntValue) - (maxIntValue >> 1),
    );
  }

  @override
  Future<void> run() => radixSortParallelSigned(list);
}

void main() async {
  log('Initializing benchmarks (average of $benchmarkRuns runs)..\n');

  final results = <String, double>{};

  // Integer
  results['List.sort() (int)'] = measureAverage(ListSortIntBenchmark());
  results['radixSortInt()'] = measureAverage(RadixSortIntBenchmark());
  results['List.sort() (Int32List)'] = measureAverage(ListSortInt32Benchmark());
  results['radixSortInt32()'] = measureAverage(RadixSortInt32Benchmark());
  results['List.sort() (Uint32List)'] = measureAverage(
    ListSortUint32Benchmark(),
  );
  results['radixSortUint32()'] = measureAverage(RadixSortUint32Benchmark());

  // Double
  results['List.sort() (double)'] = measureAverage(ListSortDoubleBenchmark());
  results['radixSortDouble()'] = measureAverage(RadixSortDoubleBenchmark());
  results['List.sort() (Float64List)'] = measureAverage(
    ListSortFloat64Benchmark(),
  );
  results['radixSortFloat64()'] = measureAverage(RadixSortFloat64Benchmark());
  results['radixSortFloat64WithNaN()'] = measureAverage(
    RadixSortFloat64WithNaNBenchmark(),
  );

  // BigInt
  results['List.sort() (BigInt)'] = measureAverage(ListSortBigIntBenchmark());
  results['radixSortBigInt()'] = measureAverage(RadixSortBigIntBenchmark());
  results['radixSortBigIntWithRange()'] = measureAverage(
    RadixSortBigIntWithRangeBenchmark(),
  );

  // Parallel
  results['radixSortParallelUnsigned()'] = await measureAverageAsync(
    RadixSortParallelUnsignedBenchmark(),
  );
  results['radixSortParallelSigned()'] = await measureAverageAsync(
    RadixSortParallelSignedBenchmark(),
  );

  print('\n--- Final Benchmark Results ---');
  results.forEach((name, time) {
    print('${name.padRight(35)}: ${time.toStringAsFixed(2).padLeft(10)} us');
  });
}
