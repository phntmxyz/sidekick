import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:path/path.dart';

extension DirectoryExtension on Directory {
  bool isWithinOrEqual(Directory dir) {
    return this.isWithin(dir) ||
        // canonicalize is necessary, otherwise '/a/b/c' != '/a/b/c/' != '/a/b/c/.' != '/a/b/c/../c'
        dir.canonicalized.path == canonicalized.path;
  }

  /// Returns the directory you would get when calling `cd` in this directory.
  ///
  /// When [path] is absolute, returns the directory at that path.
  /// Else appends the [path] to this directory.
  Directory cd(String path) =>
      (Directory(path).isAbsolute ? Directory(path) : directory(path))
          .canonicalized;

  /// A [Directory] whose path is the canonicalized path of [this].
  Directory get canonicalized => Directory(canonicalize(path));
}
