import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'radix_core.dart';

// A data class to pass arguments to the sorting isolate.
class _IsolateSortRequest {
  final SendPort sendPort;
  final Uint32List list;
  final int start;
  final int end;

  _IsolateSortRequest(this.sendPort, this.list, this.start, this.end);
}

// The entry point for the isolate.
void _isolateSortEntrypoint(_IsolateSortRequest request) {
  // Create a view of the sub-list for sorting.
  final sublist = request.list.sublist(request.start, request.end);

  // Sort the sub-list in place.
  radixSortCore(sublist, reuseBuffer: false);

  // Send the sorted sub-list back to the main isolate.
  request.sendPort.send(sublist);
}

/// Sorts a list of non-negative integers in parallel using Radix Sort.
///
/// This function divides the list into chunks and sorts each chunk in a separate
/// isolate, leveraging multiple CPU cores. The sorted chunks are then merged
/// back together in the main isolate.
///
/// For small lists (currently less than 4096 items) or if `threads` is 1,
/// this function will fall back to the single-threaded `radixSortUnsigned`
/// to avoid the overhead of isolate management.
///
/// Example:
/// ```dart
/// final numbers = List.generate(100000, (i) => 99999 - i);
/// await radixSortParallelUnsigned(numbers, threads: 4);
/// print(numbers.first); // 0
/// print(numbers.last); // 99999
/// ```
///
/// - [data]: The list of non-negative integers to be sorted.
/// - [threads]: The number of parallel isolates to use. Defaults to 4.
///   Higher numbers are effective for very large lists on machines with many
///   CPU cores.
Future<void> radixSortParallelUnsigned(
  List<int> data, {
  int threads = 4,
}) async {
  final len = data.length;
  if (len < 4096 || threads <= 1) {
    final list = Uint32List.fromList(data);
    radixSortCore(list);
    for (var i = 0; i < len; i++) {
      data[i] = list[i];
    }
    return;
  }

  final receivePort = ReceivePort();
  final originalList = Uint32List.fromList(data);
  final futures = <Future<void>>[];
  final numThreads = max(1, threads);
  final chunkSize = (len / numThreads).ceil();

  for (var i = 0; i < numThreads; i++) {
    final start = i * chunkSize;
    if (start >= len) break;
    final end = min(start + chunkSize, len);

    final request = _IsolateSortRequest(
      receivePort.sendPort,
      originalList,
      start,
      end,
    );
    futures.add(Isolate.spawn(_isolateSortEntrypoint, request));
  }

  final sortedChunks = <Uint32List>[];
  await for (final message in receivePort.take(futures.length)) {
    sortedChunks.add(message as Uint32List);
  }

  receivePort.close();
  await Future.wait(futures);

  // K-way merge of the sorted chunks.
  final pointers = List.filled(sortedChunks.length, 0);
  for (var i = 0; i < len; i++) {
    int? minVal;
    int? minChunkIndex;

    for (var j = 0; j < sortedChunks.length; j++) {
      if (pointers[j] < sortedChunks[j].length) {
        final currentVal = sortedChunks[j][pointers[j]];
        if (minVal == null || currentVal < minVal) {
          minVal = currentVal;
          minChunkIndex = j;
        }
      }
    }

    if (minChunkIndex != null) {
      data[i] = minVal!;
      pointers[minChunkIndex]++;
    } else {
      break;
    }
  }
}
