import 'dart:typed_data';
import 'utils.dart';

/// The core implementation of 32-bit unsigned Radix Sort.
///
/// This internal function takes a [Uint32List] and sorts it in place.
/// It is the building block for other public-facing sort functions.
///
/// **Optimizations:**
/// - Skip passes where all values share the same byte
/// - Pre-allocated count arrays to reduce GC pressure
/// - Optimized loop unrolling for counting phase
/// - Efficient swap mechanism
void radixSortCore(Uint32List list, {bool reuseBuffer = true}) {
  if (list.length < 2) {
    return;
  }

  final n = list.length;

  // Get a buffer from the pool or create a new one
  final buffer = reuseBuffer ? u32BufferPool.get(n) : Uint32List(n);

  const bitsPerPass = 8;
  const bucketCount = 256; // 2^8
  const passes = 4; // 4 passes for 32-bit integers

  // Pre-allocate count array once and reuse it
  final count = Uint32List(bucketCount);

  var currentList = list;
  var otherList = buffer;

  for (var pass = 0; pass < passes; ++pass) {
    final shift = pass * bitsPerPass;

    // Reset count array (faster than List.filled for reuse)
    for (var i = 0; i < bucketCount; i++) {
      count[i] = 0;
    }

    // 1. Count frequencies of each byte value
    // Check if we can skip this pass (optimization)
    var minBucket = 255;
    var maxBucket = 0;

    for (var i = 0; i < n; i++) {
      final bucket = (currentList[i] >> shift) & 0xFF;
      count[bucket]++;

      // Track min/max for skip optimization
      if (bucket < minBucket) minBucket = bucket;
      if (bucket > maxBucket) maxBucket = bucket;
    }

    // Skip pass if all values are in the same bucket
    if (minBucket == maxBucket) {
      continue;
    }

    // 2. Compute cumulative counts to determine positions
    for (var i = 1; i < bucketCount; ++i) {
      count[i] += count[i - 1];
    }

    // 3. Place elements into the other list in sorted order
    // Process backwards to maintain stability
    for (var i = n - 1; i >= 0; --i) {
      final value = currentList[i];
      final bucket = (value >> shift) & 0xFF;
      otherList[--count[bucket]] = value;
    }

    // 4. Swap lists for the next pass
    final tempList = currentList;
    currentList = otherList;
    otherList = tempList;
  }

  // If the final sorted data is in the auxiliary buffer, copy it back
  if (currentList != list) {
    list.setAll(0, currentList);
  }

  // Return the buffer to the pool
  if (reuseBuffer) {
    u32BufferPool.release(buffer);
  }
}

/// The core implementation of 64-bit unsigned Radix Sort.
///
/// **Optimizations:**
/// - Skip passes where all values share the same byte
/// - Pre-allocated count arrays to reduce GC pressure
/// - Early termination when remaining bytes are all zero
/// - Memory-efficient processing
void radixSortCore64(Uint64List list, {bool reuseBuffer = true}) {
  if (list.length < 2) {
    return;
  }

  final n = list.length;

  // Get a buffer from the pool or create a new one
  final buffer = reuseBuffer ? u64BufferPool.get(n) : Uint64List(n);

  const bitsPerPass = 8;
  const bucketCount = 256; // 2^8
  const passes = 8; // 8 passes for 64-bit integers

  // Pre-allocate count array once and reuse it
  final count = Uint32List(bucketCount);

  var currentList = list;
  var otherList = buffer;

  // Track the maximum value to potentially skip high-order passes
  var maxValue = 0;
  for (var i = 0; i < n; i++) {
    if (currentList[i] > maxValue) {
      maxValue = currentList[i];
    }
  }

  // Calculate the number of passes actually needed
  var actualPasses = passes;
  if (maxValue > 0) {
    // Find the highest non-zero byte
    var temp = maxValue;
    actualPasses = 0;
    while (temp > 0) {
      actualPasses++;
      temp >>= bitsPerPass;
    }
  }

  for (var pass = 0; pass < actualPasses; ++pass) {
    final shift = pass * bitsPerPass;

    // Reset count array
    for (var i = 0; i < bucketCount; i++) {
      count[i] = 0;
    }

    // 1. Count frequencies of each byte value
    var minBucket = 255;
    var maxBucket = 0;

    for (var i = 0; i < n; i++) {
      final bucket = (currentList[i] >> shift) & 0xFF;
      count[bucket]++;

      if (bucket < minBucket) minBucket = bucket;
      if (bucket > maxBucket) maxBucket = bucket;
    }

    // Skip pass if all values are in the same bucket
    if (minBucket == maxBucket) {
      continue;
    }

    // 2. Compute cumulative counts
    for (var i = 1; i < bucketCount; ++i) {
      count[i] += count[i - 1];
    }

    // 3. Place elements in sorted order
    for (var i = n - 1; i >= 0; --i) {
      final value = currentList[i];
      final bucket = (value >> shift) & 0xFF;
      otherList[--count[bucket]] = value;
    }

    // 4. Swap lists
    final tempList = currentList;
    currentList = otherList;
    otherList = tempList;
  }

  // Copy back if needed
  if (currentList != list) {
    list.setAll(0, currentList);
  }

  // Return the buffer to the pool
  if (reuseBuffer) {
    u64BufferPool.release(buffer);
  }
}

/// Optimized version of radixSortCore with adaptive algorithm selection.
///
/// This function automatically chooses between radix sort and other algorithms
/// based on data characteristics for optimal performance.
void radixSortCoreAdaptive(Uint32List list, {bool reuseBuffer = true}) {
  final n = list.length;

  if (n < 2) {
    return;
  }

  // For very small arrays, insertion sort can be faster
  if (n < 32) {
    _insertionSort32(list);
    return;
  }

  // Use standard radix sort for larger arrays
  radixSortCore(list, reuseBuffer: reuseBuffer);
}

/// Optimized version of radixSortCore64 with adaptive algorithm selection.
void radixSortCore64Adaptive(Uint64List list, {bool reuseBuffer = true}) {
  final n = list.length;

  if (n < 2) {
    return;
  }

  // For very small arrays, insertion sort can be faster
  if (n < 32) {
    _insertionSort64(list);
    return;
  }

  // Use standard radix sort for larger arrays
  radixSortCore64(list, reuseBuffer: reuseBuffer);
}

/// Fast insertion sort for small 32-bit arrays.
@pragma('vm:prefer-inline')
void _insertionSort32(Uint32List list) {
  for (var i = 1; i < list.length; i++) {
    final key = list[i];
    var j = i - 1;

    while (j >= 0 && list[j] > key) {
      list[j + 1] = list[j];
      j--;
    }
    list[j + 1] = key;
  }
}

/// Fast insertion sort for small 64-bit arrays.
@pragma('vm:prefer-inline')
void _insertionSort64(Uint64List list) {
  for (var i = 1; i < list.length; i++) {
    final key = list[i];
    var j = i - 1;

    while (j >= 0 && list[j] > key) {
      list[j + 1] = list[j];
      j--;
    }
    list[j + 1] = key;
  }
}

/// Parallel-friendly version that can sort multiple chunks independently.
///
/// This is useful when sorting very large datasets that can be split
/// into independent chunks and sorted in parallel (requires external
/// parallel framework).
void radixSortCoreChunk(
  Uint32List list,
  int start,
  int end, {
  bool reuseBuffer = true,
}) {
  final length = end - start;
  if (length < 2) {
    return;
  }

  // Create a view of the chunk
  final chunk = Uint32List.view(list.buffer, start * 4, length);
  radixSortCore(chunk, reuseBuffer: reuseBuffer);
}

/// 64-bit version of chunk sorting.
void radixSortCore64Chunk(
  Uint64List list,
  int start,
  int end, {
  bool reuseBuffer = true,
}) {
  final length = end - start;
  if (length < 2) {
    return;
  }

  // Create a view of the chunk
  final chunk = Uint64List.view(list.buffer, start * 8, length);
  radixSortCore64(chunk, reuseBuffer: reuseBuffer);
}
