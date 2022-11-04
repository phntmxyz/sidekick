import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:path/path.dart';

extension DirectoryExtension on Directory {
  bool isWithinOrEqual(Directory dir) {
    return this.isWithin(dir) ||
        // canonicalize is necessary, otherwise '/a/b/c' != '/a/b/c/' != '/a/b/c/.' != '/a/b/c/../c'
        dir.canonicalized.path == canonicalized.path;
  }

  /// When [path] is absolute, returns the directory at that path.
  /// Else resolves the [path] relative to this directory.
  Directory resolveAbsoluteOrRelativeDirPath(String path) =>
      (Directory(path).isAbsolute ? Directory(path) : directory(path))
          .canonicalized;

  /// A [Directory] whose path is the canonicalized path of [this].
  Directory get canonicalized => Directory(canonicalize(path));
}
