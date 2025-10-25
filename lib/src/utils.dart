import 'dart:typed_data';

/// A simple pool for reusing Uint32List buffers.
final class U32BufferPool {
  final _pool = <int, List<Uint32List>>{};

  Uint32List get(int size) {
    if (_pool.containsKey(size) && _pool[size]!.isNotEmpty) {
      return _pool[size]!.removeLast();
    }
    return Uint32List(size);
  }

  void release(Uint32List buffer) {
    final size = buffer.length;
    if (!_pool.containsKey(size)) {
      _pool[size] = [];
    }
    _pool[size]!.add(buffer);
  }

  void clear() {
    _pool.clear();
  }
}

/// A simple pool for reusing Uint64List buffers.
final class U64BufferPool {
  final _pool = <int, List<Uint64List>>{};

  Uint64List get(int size) {
    if (_pool.containsKey(size) && _pool[size]!.isNotEmpty) {
      return _pool[size]!.removeLast();
    }
    return Uint64List(size);
  }

  void release(Uint64List buffer) {
    final size = buffer.length;
    if (!_pool.containsKey(size)) {
      _pool[size] = [];
    }
    _pool[size]!.add(buffer);
  }

  void clear() {
    _pool.clear();
  }
}

/// Global buffer pool for Uint32List.
final u32BufferPool = U32BufferPool();

/// Global buffer pool for Uint64List.
final u64BufferPool = U64BufferPool();

/// A top-level function to clear all global buffer pools.
///
/// This releases all `Uint32List` and `Uint64List` buffers that have been
/// cached by the sorting functions when `reuseBuffer: true` was used.
///
/// Call this function if you have finished a batch of sorting operations and
/// want to release the memory held by the pools.
void clearBufferPools() {
  u32BufferPool.clear();
  u64BufferPool.clear();
}
