import 'dart:collection';

/// Sorts a list of BigInts in place using Radix Sort.
///
/// This implementation handles both positive and negative BigInts.
/// It works by separating negative and positive numbers, sorting each group
/// using an LSB-first radix sort approach, and then combining them.
///
/// Note: This is a simplified implementation for demonstration and may not be as
/// performant as the integer and double sorters for very large numbers.
void radixSortBigInt(List<BigInt> data) {
  if (data.length < 2) {
    return;
  }
  print('Initial data: $data');

  final negatives = data.where((n) => n.isNegative).toList();
  final positives = data.where((n) => !n.isNegative).toList();
  print('Split negatives: $negatives');
  print('Split positives: $positives');

  // Sort positive numbers ascending
  _radixSortPositiveBigInt(positives);
  print('Sorted positives: $positives');

  // Sort negative numbers by their absolute value, then reverse to get descending
  _radixSortPositiveBigInt(negatives, sortByAbsolute: true);
  print('Sorted negatives (by abs): $negatives');
  negatives.setAll(0, negatives.reversed);
  print('Reversed negatives: $negatives');

  // Combine the sorted lists
  data.clear();
  data.addAll(negatives);
  data.addAll(positives);
  print('Final combined data: $data');
}

void _radixSortPositiveBigInt(List<BigInt> list, {bool sortByAbsolute = false}) {
  if (list.length < 2) {
    return;
  }

  // Find the max bit length to determine the number of passes
  var maxBitLength = 0;
  for (final n in list) {
    final bitLength = (sortByAbsolute ? n.abs() : n).bitLength;
    if (bitLength > maxBitLength) {
      maxBitLength = bitLength;
    }
  }

  final maxBytes = (maxBitLength / 8).ceil();

  // Radix sort, byte by byte
  for (var pass = 0; pass < maxBytes; pass++) {
    final shift = pass * 8;
    // Create 256 buckets for each possible byte value
    final buckets = List.generate(256, (_) => Queue<BigInt>());

    // Iterate over a copy of the list to avoid modification issues
    for (final n in List.of(list)) {
      final value = sortByAbsolute ? n.abs() : n;
      final bucketIndex = (value >> shift).toUnsigned(8).toInt();
      buckets[bucketIndex].add(n);
    }

    // Re-collect from buckets into the original list
    var i = 0;
    for (final bucket in buckets) {
      while (bucket.isNotEmpty) {
        list[i++] = bucket.removeFirst();
      }
    }
  }
}
