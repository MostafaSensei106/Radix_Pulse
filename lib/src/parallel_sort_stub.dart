import 'dart:async';
import 'dart:typed_data';
import 'radix_core.dart';

Future<void> radixSortParallelUnsigned(List<int> data, {int? threads}) async {
  final list = Uint32List.fromList(data);
  radixSortCore(list);
  for (var i = 0; i < data.length; i++) {
    data[i] = list[i];
  }
}

Future<void> radixSortParallelSigned(List<int> data, {int? threads}) async {
  final len = data.length;
  if (len < 2) return;

  final list = Int32List.fromList(data);
  final unsignedView = Uint32List.view(list.buffer);

  const signMask = 0x80000000;
  for (var i = 0; i < len; i++) {
    unsignedView[i] ^= signMask;
  }

  radixSortCore(unsignedView);

  for (var i = 0; i < len; i++) {
    unsignedView[i] ^= signMask;
  }

  for (var i = 0; i < len; i++) {
    data[i] = list[i];
  }
}
