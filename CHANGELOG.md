## Changelog

## 1.0.3

- change(Pakage Name)

## 1.0.2

- fix(core): Resolve linting issues and refine parallel export logic
- Update benchmark documentation in README and results.md with improved methodology and new performance data.
- Add publishing metadata and topics to pubspec.yaml.
  Update CHANGELOG for version 1.0.1.
  - fix(core): Resolve linting issues and refine parallel export logic
  - Update benchmark documentation in README and results.md with improved methodology and new performance data.
  - Add publishing metadata and topics to pubspec.yaml.
    Update CHANGELOG for version 1.0.2.

## 1.0.1

feat(core): Introduce BigInt sorting, parallel enhancements, and perf optimizations

- Add comprehensive BigInt sorting support, including radixSortBigInt and
  radixSortBigIntWithRange.
- Enhance parallel sorting with radixSortParallelSigned, adaptive thread
  management, and k-way merge optimization.
- Introduce zero-copy sorting APIs for typed lists: radixSortFloat64,
  radixSortInt32, and radixSortUint32.
- Provide advanced float handling with radixSortFloat64WithNaN for NaN placement.
- Implement adaptive core algorithms that fallback to insertion sort for small lists.
- Optimize all core radix sort algorithms (int, double, BigInt) with skip passes,
  efficient data transformations, and improved buffer reuse for performance.
- Overhaul README.md with new sections, detailed performance benchmarks, and
  expanded usage examples.
- Add dedicated benchmark/results.md and update CONTRIBUTING.md links.
- Implement web-platform stub for parallel sorting functions.
- Update .gitignore to ignore example build files and add pubspec.yaml metadata.

## 1.0.0

- Initial release.
