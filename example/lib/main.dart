import 'dart:math';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:radix_pulse/radix_pulse.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radix Pulse Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BenchmarkPage(),
    );
  }
}

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage> {
  String _result = 'Press the button to run the benchmark.';
  bool _isRunning = false;

  Future<void> _runBenchmark() async {
    setState(() {
      _isRunning = true;
      _result = 'Running benchmark on 200,000 integers...';
    });

    // Run in a new isolate to avoid blocking the UI thread.
    final result = await Isolate.run(_performSorts);

    setState(() {
      _result = result;
      _isRunning = false;
    });
  }

  static String _performSorts() {
    const size = 200000;
    final random = Random();
    final originalList = List.generate(size, (_) => random.nextInt(0x7FFFFFFF) - 0x40000000);

    final list1 = List.of(originalList);
    final list2 = List.of(originalList);

    final stopwatch1 = Stopwatch()..start();
    list1.sort();
    stopwatch1.stop();
    final listSortTime = stopwatch1.elapsedMicroseconds;

    final stopwatch2 = Stopwatch()..start();
    radixSortInt(list2, signed: true);
    stopwatch2.stop();
    final radixSortTime = stopwatch2.elapsedMicroseconds;

    final factor = listSortTime / radixSortTime;

    return '''
Benchmark Complete!
List size: $size integers

List.sort(): $listSortTime µs
radixSortInt(): $radixSortTime µs

Radix Pulse was ${factor.toStringAsFixed(2)}x faster.
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radix Pulse Benchmark'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Compare Radix Pulse with List.sort()',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_isRunning)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _runBenchmark,
                  child: const Text('Run Benchmark'),
                ),
              const SizedBox(height: 24),
              Text(
                _result,
                style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
                textAlign: TextAlign.center,
              ),
            ],
          ), 
        ),
      ),
    );
  }
}