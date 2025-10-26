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
/// Example:
/// ```dart
/// final numbers = [10.5, -1.2, 900.0, -10.0, 0.0, 5.8];
/// radixSortDouble(numbers);
/// print(numbers); // [-10.0, -1.2, 0.0, 5.8, 10.5, 900.0]
/// ```
///
/// - [data]: The list of doubles to be sorted.
/// - [reuseBuffer]: If `true`, the auxiliary buffer used for sorting will be
///   sourced from a global pool. This can significantly reduce garbage
///   collection pressure and improve performance when sorting many lists of
///   similar sizes.
void radixSortDouble(List<double> data, {bool reuseBuffer = true}) {
  if (data.length < 2) {
    return;
  }

  // Create a Float64List from the input data.
  final list = Float64List.fromList(data);

  // Create a Uint64List view on the same buffer to reinterpret the bits.
  final unsignedView = Uint64List.view(list.buffer);

  const signMask = 0x8000000000000000;

  // 1. Transform: Map floats to a sortable unsigned integer representation.
  for (var i = 0; i < unsignedView.length; i++) {
    final n = unsignedView[i];
    if ((n & signMask) != 0) {
      // Negative float
      unsignedView[i] = ~n;
    } else {
      // Positive float
      unsignedView[i] = n ^ signMask;
    }
  }

  // 2. Sort: Call the core 64-bit sorting logic.
  radixSortCore64(unsignedView, reuseBuffer: reuseBuffer);

  // 3. Transform back: Revert the transformation.
  for (var i = 0; i < unsignedView.length; i++) {
    final n = unsignedView[i];
    if ((n & signMask) != 0) {
      // Originally positive
      unsignedView[i] = n ^ signMask;
    } else {
      // Originally negative
      unsignedView[i] = ~n;
    }
  }

  // 4. Copy the sorted result back to the original list.
  // The `unsignedView` and `list` share the same buffer, so `list` is now sorted.
  for (var i = 0; i < data.length; i++) {
    data[i] = list[i];
  }
}
