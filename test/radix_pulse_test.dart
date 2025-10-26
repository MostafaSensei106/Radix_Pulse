import 'package:collection/collection.dart';
import 'package:radix_pulse/radix_pulse.dart';
import 'package:test/test.dart';

void main() {
  group('radixSortInt', () {
    const listEquality = ListEquality<int>();

    void testSort(
      String description,
      List<int> list, {
      required bool signed,
      bool ascending = true,
    }) {
      test('$description (signed: $signed, ascending: $ascending)', () {
        final originalList = List.of(list);
        List<int> expected;
        if (ascending) {
          expected = List.of(originalList)..sort();
        } else {
          expected = (List.of(originalList)..sort()).reversed.toList();
        }

        radixSortInt(originalList, signed: signed, ascending: ascending);
        expect(
          listEquality.equals(originalList, expected),
          isTrue,
          reason: 'Expected $expected, but got $originalList',
        );
      });
    }

    // --- Ascending Tests ---
    testSort('should correctly sort an unsorted unsigned list', [
      5,
      2,
      8,
      1,
      9,
      4,
    ], signed: false);
    testSort('should correctly sort a mixed signed list', [
      5,
      -2,
      8,
      -1,
      0,
      9,
      -4,
    ], signed: true);

    // --- Descending Tests ---
    testSort(
      'should correctly sort a list in descending order (unsigned)',
      [5, 2, 8, 1, 9, 4],
      signed: false,
      ascending: false,
    );
    testSort(
      'should correctly sort a list in descending order (signed)',
      [5, -2, 8, -1, 0, 9, -4],
      signed: true,
      ascending: false,
    );

    // --- Edge Case Tests ---
    testSort('should handle max 32-bit unsigned value', [
      10,
      5,
      0xFFFFFFFF,
      0,
      100,
    ], signed: false);
    testSort('should handle min/max signed values', [
      10,
      -5,
      0x7FFFFFFF,
      -0x80000000,
      0,
    ], signed: true);

    // --- Error Handling Tests ---
    test('should throw for unsupported bitsPerPass', () {
      expect(
        () => radixSortInt([1, 2, 3], bitsPerPass: 16),
        throwsUnimplementedError,
      );
    });
  });

  group('radixSortDouble', () {
    const listEquality = ListEquality<double>();

    void testSort(
      String description,
      List<double> list, {
      required bool reuseBuffer,
    }) {
      test('$description (reuseBuffer: $reuseBuffer)', () {
        final originalList = List.of(list);
        final expected = List.of(originalList)..sort();
        radixSortDouble(originalList, reuseBuffer: reuseBuffer);

        final nonNanOriginal = originalList.where((d) => !d.isNaN).toList();
        final nonNanExpected = expected.where((d) => !d.isNaN).toList();

        expect(
          listEquality.equals(nonNanOriginal, nonNanExpected),
          isTrue,
          reason: 'Expected $nonNanExpected, but got $nonNanOriginal',
        );

        final nanCountOriginal = originalList.where((d) => d.isNaN).length;
        final nanCountExpected = expected.where((d) => d.isNaN).length;
        expect(
          nanCountOriginal,
          nanCountExpected,
          reason: 'Mismatch in NaN count',
        );
      });
    }

    testSort('should correctly sort mixed floats', [
      5.5,
      -2.2,
      8.8,
      -1.1,
      0.0,
      9.9,
      -4.4,
    ], reuseBuffer: true);
    testSort('should handle special float values', [
      1.0,
      double.infinity,
      -2.0,
      double.negativeInfinity,
      0.0,
      -0.0,
    ], reuseBuffer: true);
    testSort('should handle NaN values', [
      1.0,
      double.nan,
      -2.0,
      5.0,
      double.nan,
    ], reuseBuffer: true);
  });

  group('radixSortParallelUnsigned', () {
    const listEquality = ListEquality<int>();

    Future<void> testParallelSort(
      String description,
      List<int> list, {
      required int threads,
    }) async {
      test(description, () async {
        final originalList = List.of(list);
        final expected = List.of(originalList)..sort();
        await radixSortParallelUnsigned(originalList, threads: threads);
        expect(
          listEquality.equals(originalList, expected),
          isTrue,
          reason: 'Expected $expected, but got $originalList',
        );
      });
    }

    final largeList = List.generate(20000, (i) => 19999 - i);
    testParallelSort(
      'should correctly sort a large list with 4 threads',
      largeList,
      threads: 4,
    );
  });

  group('BufferPool', () {
    test('clearBufferPools should not throw', () {
      expect(() => clearBufferPools(), returnsNormally);
    });
  });

  group('radixSortBigInt', () {
    const listEquality = ListEquality<BigInt>();

    void testSort(String description, List<BigInt> list) {
      test(description, () {
        final originalList = List.of(list);
        final expected = List.of(originalList)..sort();
        radixSortBigInt(originalList);
        expect(listEquality.equals(originalList, expected), isTrue,
            reason: 'Expected $expected, but got $originalList');
      });
    }

    testSort('should correctly sort a simple list of BigInts', [
      BigInt.from(100), BigInt.from(-2), BigInt.from(50), BigInt.zero
    ]);

    testSort('should correctly sort a list with large BigInts', [
      BigInt.parse('100000000000000000000'),
      BigInt.from(-100),
      BigInt.parse('-200000000000000000000'),
      BigInt.zero,
    ]);

    testSort('should correctly sort a list with duplicates', [
      BigInt.from(50), BigInt.from(-2), BigInt.from(50), BigInt.from(-2)
    ]);
  });
}
