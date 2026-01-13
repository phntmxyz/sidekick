import 'dart:math';

import 'package:sidekick_core/sidekick_core.dart';

/// Runs tests in all packages, a single package, or a specific file/directory.
///
/// Usage:
/// - `<cli> test` - Run all tests in all packages
/// - `<cli> test --fast` - Run all tests with minimal output
/// - `<cli> test --fast -p my_package` - Run tests in package by name
/// - `<cli> test --fast packages/my_package/test/some_test.dart` - Run specific test file
/// - `<cli> test --fast packages/my_package/test/` - Run all tests in a test directory
/// - `<cli> test --fast packages/my_package/` - Run all tests in a package directory
/// - `<cli> test --fast -n "my test"` - Run tests matching name filter
class TestCommand extends Command {
  @override
  final String description =
      'Runs all tests in all packages, a single package, or a specific file/directory';

  @override
  final String name = 'test';

  @override
  final String invocation = '${SidekickContext.cliName} test [<path>]';

  TestCommand() {
    argParser
      ..addFlag('all', hide: true, help: 'deprecated')
      ..addFlag(
        'fast',
        help: 'Run tests with minimal output, only showing failures',
      )
      ..addOption(
        'package',
        abbr: 'p',
        help: 'Run tests for a specific package by name',
      )
      ..addOption(
        'name',
        abbr: 'n',
        help: 'Run only tests whose name contains the given substring',
      );
  }

  bool get _fastFlag => argResults?['fast'] as bool? ?? false;

  String? get _nameOption => argResults?['name'] as String?;

  @override
  Future<void> run() async {
    final collector = _TestResultCollector();

    final String? packageArg = argResults?['package'] as String?;
    final List<String> rest = argResults?.rest ?? [];

    // If a path is provided as rest argument (file or directory)
    if (rest.isNotEmpty) {
      final path = rest.first;
      final result = await _runTestsAtPath(path);
      // noTests is an error when user explicitly requested a path
      collector.add(result, isError: result == _TestResult.noTests);
      exitCode = collector.exitCode;
      return;
    }

    if (packageArg != null) {
      // only run tests in selected package
      final result = await _runTestsInPackageNamed(packageArg);
      // noTests is an error when user explicitly requested a package
      collector.add(result, isError: result == _TestResult.noTests);
      exitCode = collector.exitCode;
      return;
    }

    // outside of package, fallback to all packages
    for (final package in findAllPackages(SidekickContext.projectRoot)) {
      final result = await _executeTests(package, requireTests: false);
      collector.add(result);
      if (!_fastFlag) print('\n');
    }

    exitCode = collector.exitCode;
  }

  Future<_TestResult> _runTestsAtPath(String inputPath) async {
    final isDirectory = FileSystemEntity.isDirectorySync(inputPath);
    final entity = isDirectory ? Directory(inputPath) : File(inputPath);
    final absolutePath = entity.absolute.path;
    final searchDir =
        isDirectory ? entity.absolute as Directory : entity.absolute.parent;

    // Find the package root
    final package = _findPackageRoot(searchDir);

    if (package == null) {
      error(
        'Could not determine package for path: $inputPath\n'
        'No pubspec.yaml found in parent directories.',
      );
    }

    // Normalize paths by removing trailing slashes for comparison
    final normalizedPath = absolutePath.endsWith('/')
        ? absolutePath.substring(0, absolutePath.length - 1)
        : absolutePath;
    final packageRootPath = package.root.absolute.path;

    // If the path IS the package root, run all tests
    if (normalizedPath == packageRootPath) {
      return await _executeTests(package, requireTests: true);
    }

    // Get the relative path from the package root
    final relativePath = normalizedPath.substring(packageRootPath.length + 1);

    return await _executeTests(
      package,
      relativePath: relativePath,
      requireTests: true,
    );
  }

  Future<_TestResult> _runTestsInPackageNamed(String name) async {
    // only run tests in selected package
    final allPackages = findAllPackages(SidekickContext.projectRoot);
    final package = allPackages.firstOrNullWhere((it) => it.name == name);
    if (package == null) {
      final packageOptions =
          allPackages.map((it) => it.name).toList(growable: false);
      error(
        'Could not find package $name. '
        'Please use one of ${packageOptions.joinToString()}',
      );
    }
    return await _executeTests(package, requireTests: true);
  }

  /// Runs tests in a package, optionally targeting a specific path.
  ///
  /// [relativePath] is a path relative to the package root. Can be a file
  /// (e.g., `test/foo_test.dart`) or directory (e.g., `test/unit/`).
  /// If null, runs all tests in the package.
  Future<_TestResult> _executeTests(
    DartPackage package, {
    String? relativePath,
    required bool requireTests,
  }) async {
    // Print header
    final suffix = relativePath != null ? ' $relativePath' : '';
    print('${blue('▶')} testing ${package.name}$suffix...');

    // Check for test directory (only when running whole package)
    if (relativePath == null && !package.testDir.existsSync()) {
      if (requireTests) {
        print('${red('✗')} ${package.name} (no tests)');
      } else {
        print('○ ${package.name} (no tests)');
      }
      return _TestResult.noTests;
    }

    // Build args
    final args = relativePath != null ? ['test', relativePath] : ['test'];
    if (_nameOption != null) {
      args.addAll(['--name', _nameOption!]);
    }

    if (_fastFlag) {
      return await _runFastTest(package, args, relativePath: relativePath);
    } else {
      return await _runVerboseTest(package, args, relativePath: relativePath);
    }
  }

  Future<_TestResult> _runVerboseTest(
    DartPackage package,
    List<String> args, {
    String? relativePath,
  }) async {
    final stopwatch = Stopwatch()..start();
    final result = await _runDartOrFlutter(
      package,
      args,
      progress: Progress.print(),
      nothrow: true,
    );
    stopwatch.stop();
    final duration = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(
      1,
    );

    final testPathStr = relativePath != null ? ' $relativePath' : '';

    if (result.exitCode == 0) {
      print('${green('✓')} ${package.name}$testPathStr (${duration}s)');
      return _TestResult.success;
    }
    print('${red('✗')} ${package.name}$testPathStr (${duration}s)');
    return _TestResult.failed;
  }

  Future<ProcessCompletion> _runDartOrFlutter(
    DartPackage package,
    List<String> args, {
    required Progress progress,
    bool nothrow = false,
  }) async {
    final ProcessCompletion result;
    if (package.isFlutterPackage) {
      result = await flutter(
        args,
        workingDirectory: package.root,
        progress: progress,
        nothrow: nothrow,
      );
    } else {
      result = await dart(
        args,
        workingDirectory: package.root,
        progress: progress,
        nothrow: nothrow,
      );
    }

    return result;
  }

  Future<_TestResult> _runFastTest(
    DartPackage package,
    List<String> args, {
    String? relativePath,
  }) async {
    final concurrency = max(1, Platform.numberOfProcessors - 1);
    final fullArgs = [...args, '--concurrency=$concurrency', '-r', 'compact'];

    final stopwatch = Stopwatch()..start();
    final progress = Progress.capture();

    final result = await _runDartOrFlutter(
      package,
      fullArgs,
      progress: progress,
      nothrow: true,
    );
    stopwatch.stop();
    final duration = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(
      1,
    );

    final stdout = progress.lines.join('\n');
    final exitCode = result.exitCode;

    // Extract test count from output (e.g., "+25" from "00:00 +25: All tests passed!")
    final testCount = _extractTestCount(stdout);

    final testPathStr = relativePath != null ? ' $relativePath' : '';

    if (exitCode == 0) {
      final stats = [
        if (testCount != null) '$testCount tests',
        '${duration}s',
      ].join(', ');
      print('${green('✓')} ${package.name}$testPathStr ($stats)');
      return _TestResult.success;
    }

    // Parse and show only failed tests
    final failedTests = _extractFailedTests(stdout);
    final failedCount = failedTests?.length ?? 0;
    final stats = [
      if (testCount != null) '$testCount tests',
      if (failedCount > 0) '$failedCount failed',
      '${duration}s',
    ].join(', ');
    print('${red('✗')} ${package.name}$testPathStr ($stats)');
    if (failedTests != null && failedTests.isNotEmpty) {
      print('Failing tests:');
      for (final failed in failedTests) {
        final pathStr = failed.path != null ? ' (${failed.path})' : '';
        print('  - "${failed.name}"$pathStr');
      }
    } else {
      // Other errors (compilation, test not found, etc.) - dump full output
      print(stdout);
    }

    return _TestResult.failed;
  }

  /// Extracts the test count from test output (e.g., 25 from "+25: All tests passed!")
  int? _extractTestCount(String output) {
    final cleanOutput = output.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
    // Match patterns like "+25:" or "+25 -1:" to get total passed tests
    final match = RegExp(r'\+(\d+)').allMatches(cleanOutput).lastOrNull;
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  /// Extracts failed tests from test output.
  /// Returns null if this is not a test failure (e.g., compilation error, no tests found).
  List<_FailedTest>? _extractFailedTests(String output) {
    // Strip ANSI escape codes for easier parsing
    final cleanOutput = output.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
    final lines = cleanOutput.split('\n');
    final failedTests = <_FailedTest>[];

    // Check for non-test-failure errors
    if (lines.any(
      (line) =>
          line.trim().startsWith('Failed to load') ||
          line.trim().endsWith('Does not exist.') ||
          line.trim().startsWith('No tests ran.') ||
          line.contains('No tests match regular expression'),
    )) {
      return null;
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Look for lines that contain "The test description was:" (widget tests)
      if (line.contains('The test description was:')) {
        if (i + 1 < lines.length) {
          final testNameLine = lines[i + 1].trim();
          if (testNameLine.isNotEmpty &&
              !testNameLine.startsWith('The test description was:')) {
            failedTests.add(_FailedTest(testNameLine));
          }
        }
      }
      // Look for lines ending with [E] (unit tests with compact reporter)
      // Format: "00:05 +674 -1: test/my_test.dart: My Test is failing [E]"
      else if (line.contains('[E]')) {
        final match = RegExp(r':\s+(.+?)\s+\[E\]').firstMatch(line);
        if (match != null) {
          final fullMatch = match.group(1)?.trim();
          if (fullMatch != null && fullMatch.isNotEmpty) {
            // Try to split path and test name (e.g., "test/foo.dart: Test name")
            final pathMatch = RegExp(
              r'^(test/\S+\.dart):\s*(.+)$',
            ).firstMatch(fullMatch);
            if (pathMatch != null) {
              final path = pathMatch.group(1);
              final name = pathMatch.group(2)?.trim();
              if (name != null && name.isNotEmpty) {
                failedTests.add(_FailedTest(name, path: path));
              }
            } else {
              failedTests.add(_FailedTest(fullMatch));
            }
          }
        }
      }
    }

    // Remove duplicates by name
    final seen = <String>{};
    final deduplicated = <_FailedTest>[];
    for (final test in failedTests) {
      if (!seen.contains(test.name)) {
        seen.add(test.name);
        deduplicated.add(test);
      }
    }

    // Remove tests whose names are substrings of other test names
    final result = <_FailedTest>[];
    for (final test in deduplicated) {
      bool isSubstringOfAnother = false;
      for (final other in deduplicated) {
        if (test.name != other.name && other.name.contains(test.name)) {
          isSubstringOfAnother = true;
          break;
        }
      }
      if (!isSubstringOfAnother) {
        result.add(test);
      }
    }

    return result;
  }

  /// Finds the package root for a test file.
  /// First tries to split at test directory, then falls back to walking up.
  DartPackage? _findPackageRoot(Directory dir) {
    // Try one-shot: split path at /test or /*_test and check if parent is a package
    final path = dir.absolute.path;
    final testMatches = RegExp(r'/(\w+_)?test(?=/|$)').allMatches(path);
    if (testMatches.isNotEmpty) {
      final packagePath = path.substring(0, testMatches.last.start);
      final package = DartPackage.fromDirectory(Directory(packagePath));
      if (package != null) {
        return package;
      }
    }

    // Fallback: walk up the directory tree
    Directory current = dir;
    while (true) {
      final package = DartPackage.fromDirectory(current);
      if (package != null) {
        return package;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        // Reached filesystem root
        return null;
      }
      current = parent;
    }
  }
}

class _TestResultCollector {
  final List<_TestResult> _results = [];
  int _errorCount = 0;

  void add(_TestResult result, {bool isError = false}) {
    _results.add(result);
    if (isError) _errorCount++;
  }

  int get exitCode {
    if (_results.contains(_TestResult.failed)) {
      return -1;
    }
    if (_errorCount > 0) {
      return -1;
    }
    if (_results.contains(_TestResult.success)) {
      return 0;
    }
    // no tests or all skipped
    return -2;
  }
}

enum _TestResult { success, failed, noTests }

class _FailedTest {
  final String name;
  final String? path;

  _FailedTest(this.name, {this.path});
}
