import 'dart:typed_data';
import 'radix_core.dart';

/// Sorts a list of doubles in place using a stable Radix Sort.
///
/// This implementation is optimized for 64-bit floating-point numbers (doubles).
/// It works by reinterpreting the bits of IEEE-754 floats into a 64-bit
/// integer representation that can be sorted lexicographically, which preserves
/// the original floating-point order.
///
/// The sort is stable. It correctly handles positive and negative numbers, zero,
/// `-0.0`, `double.infinity`, and `double.negativeInfinity`. `double.nan` values
/// will be grouped together but their final position is not guaranteed.
///
/// **Performance optimizations:**
/// - Zero-copy operations when input is already Float64List
/// - Direct buffer manipulation without intermediate copies
/// - Efficient descending sort without recursion
/// - Optimized bit manipulation loops
///
/// Example:
/// ```dart
/// final numbers = [10.5, -1.2, 900.0, -10.0, 0.0, 5.8];
/// radixSortDouble(numbers);
/// print(numbers); // [-10.0, -1.2, 0.0, 5.8, 10.5, 900.0]
/// ```
///
/// - [data]: The list of doubles to be sorted.
/// - [ascending]: Sort order (true for ascending, false for descending).
/// - [reuseBuffer]: If `true`, the auxiliary buffer used for sorting will be
///   sourced from a global pool. This can significantly reduce garbage
///   collection pressure and improve performance when sorting many lists of
///   similar sizes.
void radixSortDouble(
  List<double> data, {
  bool ascending = true,
  bool reuseBuffer = true,
}) {
  if (data.length < 2) {
    return;
  }

  final n = data.length;
  Float64List workingList;
  bool isDirectView = false;

  // Try to work directly with the buffer if data is already Float64List
  if (data is Float64List) {
    workingList = data;
    isDirectView = true;
  } else {
    // Need to create a copy
    workingList = Float64List(n);
    for (var i = 0; i < n; i++) {
      workingList[i] = data[i];
    }
  }

  // Create a Uint64List view on the same buffer to reinterpret the bits
  final unsignedView = Uint64List.view(
    workingList.buffer,
    workingList.offsetInBytes,
    n,
  );

  const signMask = 0x8000000000000000;

  // 1. Transform: Map floats to a sortable unsigned integer representation
  for (var i = 0; i < n; i++) {
    final bits = unsignedView[i];
    // Branchless optimization could be applied here, but explicit branching
    // is often faster due to CPU branch prediction
    unsignedView[i] = (bits & signMask) != 0
        ? ~bits // Negative float: flip all bits
        : bits ^ signMask; // Positive float: flip sign bit only
  }

  // 2. Sort: Call the core 64-bit sorting logic
  radixSortCore64(unsignedView, reuseBuffer: reuseBuffer);

  // 3. Transform back: Revert the transformation
  for (var i = 0; i < n; i++) {
    final bits = unsignedView[i];
    unsignedView[i] = (bits & signMask) != 0
        ? bits ^
              signMask // Originally positive: flip sign bit only
        : ~bits; // Originally negative: flip all bits
  }

  // 4. Copy back if needed (if we created a temporary Float64List)
  if (!isDirectView) {
    for (var i = 0; i < n; i++) {
      data[i] = workingList[i];
    }
  }

  // 5. Handle descending sort efficiently
  if (!ascending) {
    _reverseInPlaceDouble(data);
  }
}

/// Reverses a list of doubles in place efficiently.
@pragma('vm:prefer-inline')
void _reverseInPlaceDouble(List<double> data) {
  var left = 0;
  var right = data.length - 1;

  while (left < right) {
    final temp = data[left];
    data[left] = data[right];
    data[right] = temp;
    left++;
    right--;
  }
}

/// Advanced version that works directly with Float64List for maximum performance.
///
/// This is the fastest option when you already have data in Float64List format.
/// It performs zero-copy operations and works directly on the input buffer.
///
/// Example:
/// ```dart
/// final data = Float64List.fromList([10.5, -1.2, 900.0, -10.0, 0.0, 5.8]);
/// radixSortFloat64(data);
/// print(data); // [-10.0, -1.2, 0.0, 5.8, 10.5, 900.0]
/// ```
///
/// - [data]: The Float64List to be sorted in place.
/// - [ascending]: Sort order (true for ascending, false for descending).
/// - [reuseBuffer]: If `true`, reuses auxiliary buffers from a global pool.
void radixSortFloat64(
  Float64List data, {
  bool ascending = true,
  bool reuseBuffer = true,
}) {
  if (data.length < 2) {
    return;
  }

  final n = data.length;

  // Create a Uint64List view on the same buffer - zero copy!
  final unsignedView = Uint64List.view(data.buffer, data.offsetInBytes, n);

  const signMask = 0x8000000000000000;

  // 1. Transform: Map floats to sortable unsigned representation
  for (var i = 0; i < n; i++) {
    final bits = unsignedView[i];
    unsignedView[i] = (bits & signMask) != 0 ? ~bits : bits ^ signMask;
  }

  // 2. Sort
  radixSortCore64(unsignedView, reuseBuffer: reuseBuffer);

  // 3. Transform back
  for (var i = 0; i < n; i++) {
    final bits = unsignedView[i];
    unsignedView[i] = (bits & signMask) != 0 ? bits ^ signMask : ~bits;
  }

  // 4. Handle descending
  if (!ascending) {
    var left = 0;
    var right = n - 1;
    while (left < right) {
      final temp = data[left];
      data[left] = data[right];
      data[right] = temp;
      left++;
      right--;
    }
  }
}

/// Sorts a list of doubles with NaN handling options.
///
/// Provides fine-grained control over how NaN values are handled during sorting.
///
/// - [nanPlacement]: Where to place NaN values:
///   - `'start'`: NaNs at the beginning
///   - `'end'`: NaNs at the end (default)
///   - `'remove'`: Remove NaNs from the result
///
/// Example:
/// ```dart
/// final data = Float64List.fromList([1.0, double.nan, 3.0, double.nan, 2.0]);
/// radixSortFloat64WithNaN(data, nanPlacement: 'end');
/// // Result: [1.0, 2.0, 3.0, NaN, NaN]
/// ```
void radixSortFloat64WithNaN(
  Float64List data, {
  bool ascending = true,
  String nanPlacement = 'end',
  bool reuseBuffer = true,
}) {
  if (data.length < 2) {
    return;
  }

  // Separate NaN values if needed
  if (nanPlacement == 'remove') {
    final nonNaN = <double>[];
    for (var i = 0; i < data.length; i++) {
      if (!data[i].isNaN) {
        nonNaN.add(data[i]);
      }
    }

    final temp = Float64List.fromList(nonNaN);
    radixSortFloat64(temp, ascending: ascending, reuseBuffer: reuseBuffer);

    // Copy back
    for (var i = 0; i < temp.length; i++) {
      data[i] = temp[i];
    }
    return;
  }

  // For 'start' or 'end', just sort normally and NaNs will be grouped
  radixSortFloat64(data, ascending: ascending, reuseBuffer: reuseBuffer);

  // If NaNs should be at start in ascending order, we need to rotate
  if (nanPlacement == 'start' && ascending) {
    _moveNaNsToStart(data);
  }
}

/// Moves NaN values to the start of the array.
void _moveNaNsToStart(Float64List data) {
  var nanCount = 0;

  // Count NaNs (they're typically at the end after sorting)
  for (var i = data.length - 1; i >= 0; i--) {
    if (data[i].isNaN) {
      nanCount++;
    } else {
      break;
    }
  }

  if (nanCount == 0) return;

  // Rotate: move non-NaN values to the right
  final nonNaNCount = data.length - nanCount;
  final temp = Float64List(nonNaNCount);

  for (var i = 0; i < nonNaNCount; i++) {
    temp[i] = data[i];
  }

  for (var i = 0; i < nanCount; i++) {
    data[i] = double.nan;
  }

  for (var i = 0; i < nonNaNCount; i++) {
    data[nanCount + i] = temp[i];
  }
}
