import 'dart:io';

import 'package:sidekick/src/util/directory_extension.dart';
import 'package:test/test.dart';

void main() {
  group('isWithinOrEqual', () {
    test('directory is outside of other directory', () {
      final dirA = Directory('/a');
      final dirB = Directory('/a/b');
      expect(dirA.isWithinOrEqual(dirB), isFalse);
    });

    test('directory is inside of other directory', () {
      final dirA = Directory('/a/b/c');
      final dirB = Directory('/a/b');
      expect(dirA.isWithinOrEqual(dirB), isTrue);
    });

    test('directory is the same as other directory', () {
      final dirA = Directory('/a/b/../b');
      final dirB = Directory('/a/b/.');
      expect(dirA.isWithinOrEqual(dirB), isTrue);
    });
  });

  group('cd', () {
    test('returns directory at absolute path', () {
      const path = '/a/b';
      final dir = Directory('/foo');
      expect(dir.cd(path).path, path);
    });

    test('returns directory at relative path', () {
      const path = 'a/b';
      final dir = Directory('/foo');
      expect(dir.cd(path).path, '/foo/a/b');
    });
  });

  group('canonicalized', () {
    test('strips extra PlatformSeparators', () {
      final dir = Directory('/a/b/c/////');
      expect(dir.canonicalized.path, '/a/b/c');
    });

    test('resolves . and ..', () {
      final dir = Directory('/a/b/c//./../././c//');
      expect(dir.canonicalized.path, '/a/b/c');
    });
  });
}
