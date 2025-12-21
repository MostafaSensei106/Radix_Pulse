import 'dart:math';
import 'package:flutter/material.dart';
import 'package:radix_plus/radix_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radix Plus Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const RadixExamplePage(),
    );
  }
}

class RadixExamplePage extends StatefulWidget {
  const RadixExamplePage({super.key});

  @override
  State<RadixExamplePage> createState() => _RadixExamplePageState();
}

class _RadixExamplePageState extends State<RadixExamplePage> {
  final _random = Random();

  // Data for Int sort
  late List<int> _integers;
  List<int>? _sortedIntegers;

  // Data for Double sort
  late List<double> _doubles;
  List<double>? _sortedDoubles;

  // Data for BigInt sort
  late List<BigInt> _bigInts;
  List<BigInt>? _sortedBigInts;

  @override
  void initState() {
    super.initState();
    _generateNewLists();
  }

  void _generateNewLists() {
    setState(() {
      _integers = List.generate(15, (_) => _random.nextInt(201) - 100);
      _sortedIntegers = null;

      _doubles = List.generate(15, (_) => (_random.nextDouble() - 0.5) * 200);
      _sortedDoubles = null;

      _bigInts = List.generate(
        8,
        (_) =>
            BigInt.from(_random.nextInt(1 << 30)) *
            BigInt.from(_random.nextInt(1 << 15)) *
            (_random.nextBool() ? BigInt.one : -BigInt.one),
      );
      _sortedBigInts = null;
    });
  }

  void _sortIntegers() {
    final listToSort = List.of(_integers);
    // Sorts the list of integers in place.
    // The `signed` parameter should be true for lists containing negative numbers.
    radixSortInt(listToSort, signed: true);
    setState(() => _sortedIntegers = listToSort);
  }

  void _sortDoubles() {
    final listToSort = List.of(_doubles);
    // Sorts the list of doubles (Float64) in place.
    radixSortDouble(listToSort);
    setState(() => _sortedDoubles = listToSort);
  }

  void _sortBigInts() {
    final listToSort = List.of(_bigInts);
    // Sorts the list of BigInts in place.
    radixSortBigInt(listToSort);
    setState(() => _sortedBigInts = listToSort);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radix Plus API Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateNewLists,
            tooltip: 'Generate New Lists',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: <Widget>[
          _SortExampleCard<int>(
            title: 'Sorting Signed Integers',
            unsortedList: _integers,
            sortedList: _sortedIntegers,
            onSort: _sortIntegers,
            formatter: (i) => i.toString(),
            apiCall: 'radixSortInt(list, signed: true);',
          ),
          const SizedBox(height: 20),
          _SortExampleCard<double>(
            title: 'Sorting Doubles',
            unsortedList: _doubles,
            sortedList: _sortedDoubles,
            onSort: _sortDoubles,
            formatter: (d) => d.toStringAsFixed(2),
            apiCall: 'radixSortDouble(list);',
          ),
          const SizedBox(height: 20),
          _SortExampleCard<BigInt>(
            title: 'Sorting BigInts',
            unsortedList: _bigInts,
            sortedList: _sortedBigInts,
            onSort: _sortBigInts,
            formatter: (b) => b.toString(),
            apiCall: 'radixSortBigInt(list);',
          ),
        ],
      ),
    );
  }
}

/// A reusable card widget to demonstrate a sort operation.
class _SortExampleCard<T> extends StatelessWidget {
  const _SortExampleCard({
    required this.title,
    required this.unsortedList,
    required this.sortedList,
    required this.onSort,
    required this.formatter,
    required this.apiCall,
    super.key,
  });

  final String title;
  final List<T> unsortedList;
  final List<T>? sortedList;
  final VoidCallback onSort;
  final String Function(T) formatter;
  final String apiCall;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              child: Text(
                apiCall,
                style: textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
              ),
            ),
            const Divider(height: 24),
            _buildList('Unsorted', unsortedList, formatter, textTheme),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: onSort,
                icon: const Icon(Icons.sort),
                label: const Text('Sort'),
              ),
            ),
            const SizedBox(height: 16),
            if (sortedList != null)
              _buildList(
                'Sorted',
                sortedList!,
                formatter,
                textTheme,
                highlightColor: colorScheme.secondaryContainer,
                textColor: colorScheme.onSecondaryContainer,
              )
            else
              const Center(
                child: Opacity(
                  opacity: 0.7,
                  child: Text('(Press "Sort" to see the result)'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    String label,
    List<T> list,
    String Function(T) formatter,
    TextTheme textTheme, {
    Color? highlightColor,
    Color? textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Text(
            list.map(formatter).join(', '),
            style: TextStyle(height: 1.5, color: textColor),
          ),
        ),
      ],
    );
  }
}
