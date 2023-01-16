import 'dart:io';
import 'package:path/path.dart' as p;

extension DirectoryExt on Directory {
  /// Recursively goes up and tries to find a [Directory] matching [predicate]
  ///
  /// Returns `null` when reaching root (/) without a match
  Directory? findParent(bool Function(Directory dir) predicate) {
    var dir = this;
    // ignore: literal_only_boolean_expressions
    while (true) {
      if (predicate(dir)) {
        return dir;
      }
      final parent = dir.parent;
      if (dir.toString() == parent.toString()) {
        // not found
        return null;
      }
      dir = dir.parent;
    }
  }

  Iterable<Directory> allSubDirectories(
    bool Function(Directory dir) predicate,
  ) sync* {
    yield this;
    for (final dir in listSync().whereType<Directory>().where(predicate)) {
      yield* dir.allSubDirectories(predicate);
    }
  }

  bool isWithinOrEquals(Directory parent) {
    return p.equals(parent.path, path) || p.isWithin(parent.path, path);
  }
}
