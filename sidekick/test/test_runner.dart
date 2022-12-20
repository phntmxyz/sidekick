import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:test/test.dart';

import 'dcli_ask_validators_test.dart' as dcli_ask_validators_test;
import 'directory_extension_test.dart' as directory_extension_test;
import 'init_test.dart' as init_test;
import 'plugins_test.dart' as plugins_test;
import 'recompile_test.dart' as recompile_test;

/// This file is a wrapper which contains all test files
///
/// This speeds up execution of tests because e.g. cached sidekick CLI's are
/// shared between all tests instead of each file needing its own instances
void main() {
  test('test_runner contains all tests', () {
    final testRunner = File(DartScript.self.pathToScript).readAsStringSync();

    final actualTestFiles = Directory('.')
        .listSync(recursive: true)
        .whereType<File>()
        .where((it) => it.path.endsWith('_test.dart'))
        .map((e) => basenameWithoutExtension(e.path))
        .toSet();
    final testsInTestRunner = RegExp(r"group\(\s*'(.*)',\s*(.*).main,?\s*\);")
        .allMatches(testRunner)
        .map((e) => {e.group(1)!, e.group(2)!}.single)
        .toSet();

    expect(testsInTestRunner, actualTestFiles);
  });

  group('dcli_ask_validators_test', dcli_ask_validators_test.main);
  group('directory_extension_test', directory_extension_test.main);
  group('init_test', init_test.main);
  group('plugins_test', plugins_test.main);
  group('recompile_test', recompile_test.main);
}
