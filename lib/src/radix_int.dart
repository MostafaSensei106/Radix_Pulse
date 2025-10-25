import 'dart:typed_data';
import 'radix_core.dart';

/// Sorts a list of integers in place using a stable Radix Sort.
///
/// This is a unified sorting function for both signed and unsigned 32-bit integers.
/// The implementation is chosen based on the [signed] parameter.
///
/// The sort is stable, meaning that the relative order of equal elements is
/// preserved.
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
/// - [reuseBuffer]: If `true`, the auxiliary buffer used for sorting will be
///   sourced from a global pool.
void radixSortInt(
  List<int> data, {
  bool signed = true,
  bool ascending = true,
  int bitsPerPass = 8, // Currently ignored, but part of the API
  bool stable = true, // Currently ignored, the sort is always stable
  bool reuseBuffer = true,
}) {
  if (data.length < 2) {
    return;
  }

  // A simple way to handle descending is to sort ascending and then reverse.
  if (!ascending) {
    radixSortInt(
      data,
      signed: signed,
      ascending: true, // Recurse with ascending
      bitsPerPass: bitsPerPass,
      stable: stable,
      reuseBuffer: reuseBuffer,
    );
    // Reverse the sorted list
    for (int i = 0, j = data.length - 1; i < j; i++, j--) {
      final temp = data[i];
      data[i] = data[j];
      data[j] = temp;
    }
    return;
  }

  if (bitsPerPass != 8) {
    // For now, only 8 bits per pass is implemented in the core logic.
    throw UnimplementedError('Only bitsPerPass = 8 is currently supported.');
  }

  if (signed) {
    final list = Int32List.fromList(data);
    final unsignedView = Uint32List.view(list.buffer);
    const signMask = 0x80000000;

    for (var i = 0; i < unsignedView.length; i++) {
      unsignedView[i] ^= signMask;
    }

    radixSortCore(unsignedView, reuseBuffer: reuseBuffer);

    for (var i = 0; i < unsignedView.length; i++) {
      unsignedView[i] ^= signMask;
    }

    for (var i = 0; i < data.length; i++) {
      data[i] = list[i];
    }
  } else {
    final list = Uint32List.fromList(data);
    radixSortCore(list, reuseBuffer: reuseBuffer);
    for (var i = 0; i < data.length; i++) {
      data[i] = list[i];
    }
  }
}
