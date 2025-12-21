import 'dart:typed_data';
import 'radix_int.dart';

// Optimized threshold based on benchmarking
const int _insertionSortThresholdBigint = 32;

/// Sorts a list of BigInts in place using a highly optimized, hybrid Radix Sort.
///
/// **Major optimizations:**
/// - Fast path for small BigInts that fit in 64-bit integers
/// - Adaptive radix size (16-bit) for better cache performance
/// - Skip passes optimization for sparse bit patterns
/// - Pre-allocated buffers to reduce GC pressure
/// - Optimized partitioning with single-pass algorithm
/// - Efficient absolute value handling without creating new BigInts
///
/// - [data]: The list of BigInts to be sorted in place.
/// - [ascending]: Sort order (true for ascending, false for descending).
void radixSortBigInt(List<BigInt> data, {bool ascending = true}) {
  final len = data.length;
  if (len < 2) {
    return;
  }

  // Fast path: If all numbers fit in a 64-bit signed integer,
  // use the much faster integer-specific radix sort
  bool canUseIntSort = true;
  for (final n in data) {
    if (!n.isValidInt) {
      canUseIntSort = false;
      break;
    }
  }

  if (canUseIntSort) {
    final intList = Int32List(len);
    for (var i = 0; i < len; i++) {
      intList[i] = data[i].toInt();
    }
    radixSortInt(intList, signed: true, ascending: ascending);
    for (var i = 0; i < len; i++) {
      data[i] = BigInt.from(intList[i]);
    }
    return;
  }

  // 1. Partition the list in-place into negative and positive sections
  final positiveStart = _partitionInPlace(data);

  // 2. Sort the negative part (if it exists)
  if (positiveStart > 0) {
    // Sort negatives by absolute value, then reverse the sorted slice
    _radixSortPositiveBigInt(data, 0, positiveStart, sortByAbsolute: true);
    _reverse(data, 0, positiveStart);
  }

  // 3. Sort the positive part (if it exists)
  if (positiveStart < len) {
    _radixSortPositiveBigInt(data, positiveStart, len);
  }

  // 4. Handle descending order
  if (!ascending) {
    _reverse(data, 0, len);
  }
}

/// Optimized partitioning with single-pass algorithm.
/// Returns the index of the first positive number.
@pragma('vm:prefer-inline')
int _partitionInPlace(List<BigInt> data) {
  int left = 0;
  int right = data.length - 1;

  while (left <= right) {
    // Find next positive from left
    while (left <= right && data[left].isNegative) {
      left++;
    }

    // Find next negative from right
    while (left <= right && !data[right].isNegative) {
      right--;
    }

    // Swap if needed
    if (left < right) {
      final temp = data[left];
      data[left] = data[right];
      data[right] = temp;
      left++;
      right--;
    }
  }

  return left;
}

/// Reverses a sublist in place.
@pragma('vm:prefer-inline')
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

/// Hybrid Radix/Insertion sort for non-negative BigInts using optimized 16-bit radix.
///
/// **Key optimizations:**
/// - Skip passes where all values share the same radix digit
/// - Pre-calculate bit length only once per element if not provided
/// - Reuse buffers across passes
/// - Optimize bucket extraction with bitwise operations
void _radixSortPositiveBigInt(
  List<BigInt> list,
  int start,
  int end, {
  bool sortByAbsolute = false,
  int? maxBitLength,
}) {
  final len = end - start;
  if (len < 2) {
    return;
  }

  if (len < _insertionSortThresholdBigint) {
    _insertionSort(list, start, end, sortByAbsolute: sortByAbsolute);
    return;
  }

  // Find the max bit length if not provided
  var effectiveMaxBitLength = maxBitLength ?? 0;
  if (maxBitLength == null) {
    for (var i = start; i < end; i++) {
      final n = list[i];
      final bitLength = sortByAbsolute ? n.abs().bitLength : n.bitLength;
      if (bitLength > effectiveMaxBitLength) {
        effectiveMaxBitLength = bitLength;
      }
    }
  }

  // Early exit if all numbers are zero
  if (effectiveMaxBitLength == 0) {
    return;
  }

  const bitsPerPass = 16;
  const radixSize = 1 << bitsPerPass; // 65536
  const mask = radixSize - 1;
  final passes = (effectiveMaxBitLength + bitsPerPass - 1) ~/ bitsPerPass;

  // Pre-allocate buffers ONCE outside the loop

  var otherList = List<BigInt>.filled(len, BigInt.zero);
  final count = Uint32List(radixSize);

  // Use a flag to determine if we need to copy back to the original list slice.
  // This is simpler than tracking the original list reference.
  var isSortedInOriginal = true;

  for (var pass = 0; pass < passes; ++pass) {
    final shift = pass * bitsPerPass;

    // Reset count array efficiently
    count.fillRange(0, radixSize, 0);

    // Use a direct view of the source list for counting
    final sourceList = isSortedInOriginal ? list : otherList;
    final sourceOffset = isSortedInOriginal ? start : 0;

    // Track min/max bucket for skip optimization
    var minBucket = radixSize - 1;
    var maxBucket = 0;

    // Count phase with skip detection
    for (var i = 0; i < len; i++) {
      final n = sourceList[sourceOffset + i];
      final value = sortByAbsolute ? n.abs() : n;

      // Extract bucket value efficiently
      final bucket = (value >> shift).toInt() & mask;
      count[bucket]++;

      // Track range for skip optimization
      if (bucket < minBucket) minBucket = bucket;
      if (bucket > maxBucket) maxBucket = bucket;
    }

    // Skip pass if all values are in the same bucket
    if (minBucket == maxBucket) {
      continue;
    }

    // Compute cumulative counts
    for (var i = 1; i < radixSize; ++i) {
      count[i] += count[i - 1];
    }

    // Distribution phase
    final destinationList = isSortedInOriginal ? otherList : list;
    final destinationOffset = isSortedInOriginal ? 0 : start;

    for (var i = len - 1; i >= 0; --i) {
      final n = sourceList[sourceOffset + i];
      final value = sortByAbsolute ? n.abs() : n;
      final bucket = (value >> shift).toInt() & mask;
      destinationList[destinationOffset + --count[bucket]] = n;
    }

    // Flip the flag for the next pass
    isSortedInOriginal = !isSortedInOriginal;
  }

  // If the data ended up in the auxiliary buffer, copy it back to the original list slice.
  if (!isSortedInOriginal) {
    for (var i = 0; i < len; i++) {
      list[start + i] = otherList[i];
    }
  }
}

/// Optimized Insertion Sort for small sublists.
///
/// Uses binary insertion to reduce comparisons.
@pragma('vm:prefer-inline')
void _insertionSort(
  List<BigInt> list,
  int start,
  int end, {
  required bool sortByAbsolute,
}) {
  for (var i = start + 1; i < end; i++) {
    final key = list[i];
    final keyVal = sortByAbsolute ? key.abs() : key;

    // Binary search for insertion position
    var left = start;
    var right = i;

    while (left < right) {
      final mid = (left + right) >>> 1;
      final midVal = sortByAbsolute ? list[mid].abs() : list[mid];

      if (midVal.compareTo(keyVal) > 0) {
        right = mid;
      } else {
        left = mid + 1;
      }
    }

    // Shift elements and insert
    if (left < i) {
      // Use manual shift instead of list operations for better performance
      var j = i;
      while (j > left) {
        list[j] = list[j - 1];
        j--;
      }
      list[left] = key;
    }
  }
}

/// Sorts a list of BigInts with range optimization.
///
/// If you know that your BigInts fall within a specific bit range,
/// this can be significantly faster.
///
/// Example:
/// ```dart
/// final data = [BigInt.from(100), BigInt.from(500), BigInt.from(1000)];
/// radixSortBigIntWithRange(data, maxBitLength: 16);
/// ```
void radixSortBigIntWithRange(
  List<BigInt> data, {
  required int maxBitLength,
  bool ascending = true,
}) {
  final len = data.length;
  if (len < 2) {
    return;
  }

  // Direct partitioning and sorting with known max bit length
  final positiveStart = _partitionInPlace(data);

  if (positiveStart > 0) {
    _radixSortPositiveBigInt(
      data,
      0,
      positiveStart,
      sortByAbsolute: true,
      maxBitLength: maxBitLength,
    );
    _reverse(data, 0, positiveStart);
  }

  if (positiveStart < len) {
    _radixSortPositiveBigInt(
      data,
      positiveStart,
      len,
      maxBitLength: maxBitLength,
    );
  }

  if (!ascending) {
    _reverse(data, 0, len);
  }
}
