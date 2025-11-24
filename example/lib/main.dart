import 'dart:math';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:radix_plus/radix_pulse.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radix Plus Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const BenchmarkPage(),
    );
  }
}

class BenchmarkResult {
  final String name;
  final int listSortTime;
  final int radixSortTime;
  final int listSize;

  BenchmarkResult(
    this.name,
    this.listSortTime,
    this.radixSortTime,
    this.listSize,
  );

  double get improvement =>
      ((listSortTime - radixSortTime) / listSortTime) * 100;
}

class BenchmarkPage extends StatefulWidget {
  const BenchmarkPage({super.key});

  @override
  State<BenchmarkPage> createState() => _BenchmarkPageState();
}

class _BenchmarkPageState extends State<BenchmarkPage>
    with TickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<BenchmarkResult> _results = [];
  bool _isRunning = false;
  String _message = 'Press the button to run all benchmarks.';

  late final AnimationController _bgController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat(reverse: true);

  late final Animation<Alignment> _topAlignmentAnimation = AlignmentTween(
    begin: Alignment.topLeft,
    end: Alignment.topRight,
  ).animate(_bgController);
  late final Animation<Alignment> _bottomAlignmentAnimation = AlignmentTween(
    begin: Alignment.bottomLeft,
    end: Alignment.bottomRight,
  ).animate(_bgController);

  Future<void> _runAllBenchmarks() async {
    if (_isRunning) return;

    // Clear old results
    for (var i = _results.length - 1; i >= 0; i--) {
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => const SizedBox.shrink(),
      );
    }
    _results.clear();

    setState(() {
      _isRunning = true;
      _message = 'Warming up the engines...';
    });

    final resultData = await Isolate.run(_performSorts);

    setState(() {
      _isRunning = false;
      _message = 'Benchmark Results (List size: ${resultData.first.listSize})';
    });

    for (var i = 0; i < resultData.length; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      _results.add(resultData[i]);
      _listKey.currentState?.insertItem(i);
    }
  }

  static Future<List<BenchmarkResult>> _performSorts() async {
    const size = 100000;
    final random = Random();
    final results = <BenchmarkResult>[];

    // --- 1. Signed Integers ---
    final signedInts = List.generate(
      size,
      (_) => random.nextInt(0x7FFFFFFF) - 0x40000000,
    );
    final listCopy1 = List.of(signedInts);
    final radixCopy1 = List.of(signedInts);
    final sw1 = Stopwatch()..start();
    listCopy1.sort();
    sw1.stop();
    final sw2 = Stopwatch()..start();
    radixSortInt(radixCopy1, signed: true);
    sw2.stop();
    results.add(
      BenchmarkResult(
        'Signed Integers',
        sw1.elapsedMicroseconds,
        sw2.elapsedMicroseconds,
        size,
      ),
    );

    // --- 2. Unsigned Integers ---
    final unsignedInts = List.generate(size, (_) => random.nextInt(0x7FFFFFFF));
    final listCopy2 = List.of(unsignedInts);
    final radixCopy2 = List.of(unsignedInts);
    final sw3 = Stopwatch()..start();
    listCopy2.sort();
    sw3.stop();
    final sw4 = Stopwatch()..start();
    radixSortInt(radixCopy2, signed: false);
    sw4.stop();
    results.add(
      BenchmarkResult(
        'Unsigned Integers',
        sw3.elapsedMicroseconds,
        sw4.elapsedMicroseconds,
        size,
      ),
    );

    // --- 3. Doubles ---
    final doubles = List.generate(
      size,
      (_) => (random.nextDouble() - 0.5) * 1e6,
    );
    final listCopy3 = List.of(doubles);
    final radixCopy3 = List.of(doubles);
    final sw5 = Stopwatch()..start();
    listCopy3.sort();
    sw5.stop();
    final sw6 = Stopwatch()..start();
    radixSortDouble(radixCopy3);
    sw6.stop();
    results.add(
      BenchmarkResult(
        'Doubles',
        sw5.elapsedMicroseconds,
        sw6.elapsedMicroseconds,
        size,
      ),
    );

    // --- 4. BigInts ---
    final bigInts = List.generate(
      size,
      (_) =>
          BigInt.from(random.nextInt(1 << 30)) *
          BigInt.from(random.nextInt(1 << 30)) *
          (random.nextBool() ? BigInt.one : -BigInt.one),
    );
    final listCopy4 = List.of(bigInts);
    final radixCopy4 = List.of(bigInts);
    final sw7 = Stopwatch()..start();
    listCopy4.sort();
    sw7.stop();
    final sw8 = Stopwatch()..start();
    radixSortBigInt(radixCopy4);
    sw8.stop();
    results.add(
      BenchmarkResult(
        'BigInts',
        sw7.elapsedMicroseconds,
        sw8.elapsedMicroseconds,
        size,
      ),
    );

    // --- 5. Parallel Unsigned Integers ---
    final parallelInts = List.generate(size, (_) => random.nextInt(0x7FFFFFFF));
    final listCopy5 = List.of(parallelInts);
    final radixCopy5 = List.of(parallelInts);
    final sw9 = Stopwatch()..start();
    listCopy5.sort();
    sw9.stop();
    final sw10 = Stopwatch()..start();
    await radixSortParallelUnsigned(radixCopy5, threads: 4);
    sw10.stop();
    results.add(
      BenchmarkResult(
        'Parallel Unsigned (4 Threads)',
        sw9.elapsedMicroseconds,
        sw10.elapsedMicroseconds,
        size,
      ),
    );

    return results;
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [Color(0xFF1E1E2E), Color(0xFF45456E)],
              begin: _topAlignmentAnimation.value,
              end: _bottomAlignmentAnimation.value,
            ),
          ),
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Radix Plus Benchmark'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Time Performance: Radix Plus vs List.sort()',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isRunning
                      ? Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              _message,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                          onPressed: _runAllBenchmarks,
                          icon: const Icon(Icons.rocket_launch),
                          label: const Text('Run All Benchmarks'),
                        ),
                ),
                const SizedBox(height: 24),
                if (!_isRunning && _results.isEmpty)
                  Text(_message, style: const TextStyle(fontSize: 16)),
                Expanded(
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: _results.length,
                    itemBuilder: (context, index, animation) {
                      return _buildResultCard(_results[index], animation);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BenchmarkResult result, Animation<double> animation) {
    final isPositive = result.improvement > 0;
    final improvementColor = isPositive ? Colors.greenAccent : Colors.redAccent;
    final sign = isPositive ? '+' : '';

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Divider(color: Colors.white24, height: 20),
                _buildStatRow(
                  Icons.timer_outlined,
                  'List.sort()',
                  '${result.listSortTime} µs',
                ),
                _buildStatRow(
                  Icons.flash_on,
                  'Radix Plus',
                  '${result.radixSortTime} µs',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: improvementColor, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        color: improvementColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Improvement: $sign${result.improvement.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: improvementColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
