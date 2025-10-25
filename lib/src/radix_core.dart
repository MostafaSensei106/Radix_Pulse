import 'dart:typed_data';

import 'utils.dart';

/// The core implementation of 32-bit unsigned Radix Sort.
///
/// This internal function takes a [Uint32List] and sorts it in place.
/// It is the building block for other public-facing sort functions.
void radixSortCore(Uint32List list, {bool reuseBuffer = true}) {
  if (list.length < 2) {
    return;
  }

  // Get a buffer from the pool or create a new one.
  final buffer = reuseBuffer
      ? u32BufferPool.get(list.length)
      : Uint32List(list.length);

  const bitsPerPass = 8;
  const passes = 4; // 4 passes for 32-bit integers

  var currentList = list;
  var otherList = buffer;

  for (var pass = 0; pass < passes; ++pass) {
    final shift = pass * bitsPerPass;
    final count = List.filled(1 << bitsPerPass, 0);

    // 1. Count frequencies of each byte value.
    for (final n in currentList) {
      final bucket = (n >> shift) & 0xFF;
      count[bucket]++;
    }

    // 2. Compute cumulative counts to determine positions.
    for (var i = 1; i < count.length; ++i) {
      count[i] += count[i - 1];
    }

    // 3. Place elements into the other list in sorted order.
    for (var i = currentList.length - 1; i >= 0; --i) {
      final n = currentList[i];
      final bucket = (n >> shift) & 0xFF;
      otherList[--count[bucket]] = n;
    }

    // 4. Swap lists for the next pass.
    final tempList = currentList;
    currentList = otherList;
    otherList = tempList;
  }

  // If the final sorted data is in the auxiliary buffer, copy it back.
  if (currentList != list) {
    list.setAll(0, currentList);
  }

  // Return the buffer to the pool.
  if (reuseBuffer) {
    u32BufferPool.release(buffer);
  }
}

/// The core implementation of 64-bit unsigned Radix Sort.
void radixSortCore64(Uint64List list, {bool reuseBuffer = true}) {
  if (list.length < 2) {
    return;
  }

  // Get a buffer from the pool or create a new one.
  final buffer = reuseBuffer
      ? u64BufferPool.get(list.length)
      : Uint64List(list.length);

  const bitsPerPass = 8;
  const passes = 8; // 8 passes for 64-bit integers

  var currentList = list;
  var otherList = buffer;

  for (var pass = 0; pass < passes; ++pass) {
    final shift = pass * bitsPerPass;
    final count = List.filled(1 << bitsPerPass, 0);

    for (final n in currentList) {
      final bucket = (n >> shift) & 0xFF;
      count[bucket]++;
    }

    for (var i = 1; i < count.length; ++i) {
      count[i] += count[i - 1];
    }

    for (var i = currentList.length - 1; i >= 0; --i) {
      final n = currentList[i];
      final bucket = (n >> shift) & 0xFF;
      otherList[--count[bucket]] = n;
    }

    final tempList = currentList;
    currentList = otherList;
    otherList = tempList;
  }

  if (currentList != list) {
    list.setAll(0, currentList);
  }

  if (reuseBuffer) {
    u64BufferPool.release(buffer);
  }
}
