import 'dart:typed_data';

import 'radix_int.dart';

const int _INSERTION_SORT_THRESHOLD_BIGINT = 32;

/// Sorts a list of BigInts in place using a highly optimized, hybrid Radix Sort.
void radixSortBigInt(List<BigInt> data) {
  final len = data.length;
  if (len < 2) {
    return;
  }

  // Fast path escape hatch: If all numbers fit in a 64-bit signed integer,
  // use the much faster integer-specific radix sort.
  bool canUseIntSort = true;
  for (final n in data) {
    if (!n.isValidInt) {
      canUseIntSort = false;
      break;
    }
  }

  if (canUseIntSort) {
    final intList = data.map((e) => e.toInt()).toList();
    radixSortInt(intList, signed: true);
    for (var i = 0; i < len; i++) {
      data[i] = BigInt.from(intList[i]);
    }
    return;
  }

  // 1. Partition the list in-place into negative and positive sections.
  int positiveStart = _partitionInPlace(data);

  // 2. Sort the negative part (if it exists).
  if (positiveStart > 0) {
    // Sort negatives by absolute value, then reverse the sorted slice.
    _radixSortPositiveBigInt(data, 0, positiveStart, sortByAbsolute: true);
    _reverse(data, 0, positiveStart);
  }

  // 3. Sort the positive part (if it exists).
  if (positiveStart < len) {
    _radixSortPositiveBigInt(data, positiveStart, len);
  }
}

/// Partitions the list in-place, moving all negative numbers to the beginning.
/// Returns the index of the first positive number.
int _partitionInPlace(List<BigInt> data) {
  int left = 0;
  int right = data.length - 1;
  while (left <= right) {
    if (data[left].isNegative) {
      left++;
    } else {
      // Swap positive number at [left] with number at [right]
      final temp = data[left];
      data[left] = data[right];
      data[right] = temp;
      right--;
    }
  }
  return left;
}

/// Reverses a sublist in place.
void _reverse(List<BigInt> list, int start, int end) {
  int i = start;
  int j = end - 1;
  while (i < j) {
    final temp = list[i];
    list[i] = list[j];
    list[j] = temp;
    i++;
    j--;
  }
}

/// Hybrid Radix/Insertion sort for non-negative BigInts using a 16-bit radix.
void _radixSortPositiveBigInt(
  List<BigInt> list,
  int start,
  int end, {
  bool sortByAbsolute = false,
}) {
  final len = end - start;
  if (len < 2) {
    return;
  }

  // Hybrid approach: Use insertion sort for small lists.
  if (len < _INSERTION_SORT_THRESHOLD_BIGINT) {
    _insertionSort(list, start, end, sortByAbsolute: sortByAbsolute);
    return;
  }

  // Find the max bit length to determine the number of passes.
  var maxBitLength = 0;
  for (var i = start; i < end; i++) {
    final n = list[i];
    final bitLength = (sortByAbsolute ? n.abs() : n).bitLength;
    if (bitLength > maxBitLength) {
      maxBitLength = bitLength;
    }
  }

  const bitsPerPass = 16;
  const radixSize = 1 << bitsPerPass;
  const mask = radixSize - 1;
  final passes = (maxBitLength / bitsPerPass).ceil();

  var currentList = list;
  var otherList = List<BigInt>.filled(len, BigInt.zero);
  final count = Uint32List(radixSize);

  for (var pass = 0; pass < passes; ++pass) {
    final shift = pass * bitsPerPass;
    count.fillRange(0, radixSize, 0);

    for (var i = 0; i < len; i++) {
      final n = currentList == list ? currentList[start + i] : currentList[i];
      final value = sortByAbsolute ? n.abs() : n;
      final bucket = (value >> shift).toUnsigned(mask).toInt();
      count[bucket]++;
    }

    for (var i = 1; i < radixSize; ++i) {
      count[i] += count[i - 1];
    }

    for (var i = len - 1; i >= 0; --i) {
      final n = currentList == list ? currentList[start + i] : currentList[i];
      final value = sortByAbsolute ? n.abs() : n;
      final bucket = (value >> shift).toUnsigned(mask).toInt();
      otherList[--count[bucket]] = n;
    }

    final tempList = currentList;
    currentList = otherList;
    // After the first pass, otherList becomes the primary buffer.
    if (tempList == list) {
      otherList = List<BigInt>.filled(len, BigInt.zero);
    } else {
      otherList = tempList;
    }
  }

  if (currentList != list) {
    list.setAll(start, currentList);
  }
}

/// Simple Insertion Sort for small sublists.
void _insertionSort(
  List<BigInt> list,
  int start,
  int end, {
  required bool sortByAbsolute,
}) {
  for (var i = start + 1; i < end; i++) {
    final key = list[i];
    var j = i - 1;
    final keyVal = sortByAbsolute ? key.abs() : key;

    while (j >= start) {
      final currentVal = sortByAbsolute ? list[j].abs() : list[j];
      if (currentVal.compareTo(keyVal) > 0) {
        list[j + 1] = list[j];
        j--;
      } else {
        break;
      }
    }
    list[j + 1] = key;
  }
}
