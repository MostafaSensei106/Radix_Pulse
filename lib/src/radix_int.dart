import 'dart:typed_data';
import 'radix_core.dart';

/// Sorts a list of integers in place using a stable Radix Sort.
///
/// This is an optimized unified sorting function for both signed and unsigned 32-bit integers.
/// The implementation is chosen based on the [signed] parameter.
///
/// The sort is stable, meaning that the relative order of equal elements is preserved.
///
/// **Performance optimizations:**
/// - Zero-copy operations when possible
/// - Direct buffer manipulation
/// - Efficient descending sort without recursion
/// - Reduced memory allocations
///
/// Example (Signed):
/// ```dart
/// final numbers = [40, -1, 900, -10, 0, 5];
/// radixSortInt(numbers, signed: true);
/// print(numbers); // [-10, -1, 0, 5, 40, 900]
/// ```
///
/// Example (Unsigned):
/// ```dart
/// final numbers = [40, 1, 900, 10, 5];
/// radixSortInt(numbers, signed: false);
/// print(numbers); // [1, 5, 10, 40, 900]
/// ```
///
/// - [data]: The list of integers to be sorted.
/// - [signed]: Whether to treat the integers as signed or unsigned.
/// - [ascending]: Sort order (true for ascending, false for descending).
/// - [bitsPerPass]: Number of bits per pass (currently only 8 is supported).
/// - [stable]: Whether the sort is stable (currently always stable).
/// - [reuseBuffer]: If `true`, reuses auxiliary buffers from a global pool.
void radixSortInt(
  List<int> data, {
  bool signed = true,
  bool ascending = true,
  int bitsPerPass = 8,
  bool stable = true,
  bool reuseBuffer = true,
}) {
  if (data.length < 2) {
    return;
  }

  if (bitsPerPass != 8) {
    throw UnimplementedError('Only bitsPerPass = 8 is currently supported.');
  }

  final n = data.length;

  if (signed) {
    // Create typed array view for efficient manipulation
    Uint32List workingList;
    bool isDirectView = false;

    // Try to work directly with the buffer if data is already a typed list
    if (data is Int32List) {
      workingList = Uint32List.view(data.buffer, data.offsetInBytes, n);
      isDirectView = true;
    } else {
      // Need to create a copy
      final list = Int32List(n);
      for (var i = 0; i < n; i++) {
        list[i] = data[i];
      }
      workingList = Uint32List.view(list.buffer);
    }

    // XOR with sign mask to convert signed to unsigned representation
    const signMask = 0x80000000;
    for (var i = 0; i < n; i++) {
      workingList[i] ^= signMask;
    }

    // Perform the sort
    radixSortCore(workingList, reuseBuffer: reuseBuffer);

    // Convert back from unsigned representation
    for (var i = 0; i < n; i++) {
      workingList[i] ^= signMask;
    }

    // Copy back if needed
    if (!isDirectView) {
      final signedView = Int32List.view(workingList.buffer);
      for (var i = 0; i < n; i++) {
        data[i] = signedView[i];
      }
    }
  } else {
    // Unsigned integers
    Uint32List workingList;
    bool isDirectView = false;

    // Try to work directly with the buffer if data is already Uint32List
    if (data is Uint32List) {
      workingList = data;
      isDirectView = true;
    } else {
      // Create typed list for efficient sorting
      workingList = Uint32List(n);
      for (var i = 0; i < n; i++) {
        workingList[i] = data[i];
      }
    }

    // Perform the sort
    radixSortCore(workingList, reuseBuffer: reuseBuffer);

    // Copy back if needed
    if (!isDirectView) {
      for (var i = 0; i < n; i++) {
        data[i] = workingList[i];
      }
    }
  }

  // Handle descending sort efficiently without recursion
  if (!ascending) {
    _reverseInPlace(data);
  }
}

/// Reverses a list in place efficiently.
@pragma('vm:prefer-inline')
void _reverseInPlace(List<int> data) {
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

/// Advanced version that works with pre-allocated typed lists for maximum performance.
///
/// Use this when you already have data in typed lists and want to avoid any copying.
///
/// Example:
/// ```dart
/// final data = Int32List.fromList([40, -1, 900, -10, 0, 5]);
/// radixSortInt32(data);
/// print(data); // [-10, -1, 0, 5, 40, 900]
/// ```
void radixSortInt32(
  Int32List data, {
  bool ascending = true,
  bool reuseBuffer = true,
}) {
  if (data.length < 2) {
    return;
  }

  final n = data.length;
  final workingList = Uint32List.view(data.buffer, data.offsetInBytes, n);

  // XOR with sign mask
  const signMask = 0x80000000;
  for (var i = 0; i < n; i++) {
    workingList[i] ^= signMask;
  }

  // Sort
  radixSortCore(workingList, reuseBuffer: reuseBuffer);

  // Convert back
  for (var i = 0; i < n; i++) {
    workingList[i] ^= signMask;
  }

  // Handle descending
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

/// Advanced version for unsigned 32-bit integers with zero-copy when possible.
///
/// Example:
/// ```dart
/// final data = Uint32List.fromList([40, 1, 900, 10, 5]);
/// radixSortUint32(data);
/// print(data); // [1, 5, 10, 40, 900]
/// ```
void radixSortUint32(
  Uint32List data, {
  bool ascending = true,
  bool reuseBuffer = true,
}) {
  if (data.length < 2) {
    return;
  }

  // Sort directly - zero copy!
  radixSortCore(data, reuseBuffer: reuseBuffer);

  // Handle descending
  if (!ascending) {
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
}
