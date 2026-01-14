import 'dart:math';

import 'package:meta/meta.dart';
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
      ..addMultiOption(
        'package',
        abbr: 'p',
        help: 'Run tests for specific packages by name (can be repeated)',
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
    collector.setHasNameFilter(_nameOption != null);

    final List<String> packageArgs =
        argResults?['package'] as List<String>? ?? [];
    final List<String> rest = argResults?.rest ?? [];

    // If a path is provided as rest argument (file or directory)
    if (rest.isNotEmpty) {
      final path = rest.first;
      final execResult = await _runTestsAtPath(path);
      // noTests and noMatchingTests are errors when user explicitly requested a path
      collector.add(
        execResult.result,
        isError: execResult.result == TestResult.noTests ||
            execResult.result == TestResult.noMatchingTests,
        packageName: null, // Package name would require parsing path
        failedTests: execResult.failedTests,
        testCount: execResult.testCount,
      );
      exitCode = collector.exitCode;
      _printSummary(collector);
      return;
    }

    if (packageArgs.isNotEmpty) {
      // Run tests in specified packages
      for (final packageName in packageArgs) {
        final execResult = await _runTestsInPackageNamed(packageName);
        // noTests and noMatchingTests are errors when user explicitly requested a package
        collector.add(
          execResult.result,
          isError: execResult.result == TestResult.noTests ||
              execResult.result == TestResult.noMatchingTests,
          packageName: packageName,
          failedTests: execResult.failedTests,
          testCount: execResult.testCount,
        );
        if (!_fastFlag) print('\n');
      }
      exitCode = collector.exitCode;
      _printSummary(collector);
      return;
    }

    // outside of package, fallback to all packages
    final allPackages = findAllPackages(SidekickContext.projectRoot);
    final isOnlyPackage = allPackages.length == 1;
    for (final package in allPackages) {
      // Treat single package as explicitly selected
      final explicitlySelected = isOnlyPackage;
      final execResult = await _executeTests(
        package,
        explicitlySelected: explicitlySelected,
      );
      // Don't add packages without tests to summary unless explicitly selected
      if (execResult.result == TestResult.noTests && !explicitlySelected) {
        continue;
      }
      collector.add(
        execResult.result,
        packageName: package.name,
        failedTests: execResult.failedTests,
        testCount: execResult.testCount,
      );
      if (!_fastFlag) print('\n');
    }

    exitCode = collector.exitCode;
    _printSummary(collector);
  }

  void _printSummary(_TestResultCollector collector) {
    final code = collector.exitCode;
    final packageResults = collector.packageResults;
    final allFailedTests = collector.allFailedTests;
    final totalTests = collector.totalTestsRun;

    // Print separator
    print('\n${'=' * 60}');

    // Print test count summary
    if (totalTests > 0) {
      final passedTests = totalTests - allFailedTests.length;
      print(
          'Tests: $totalTests run, $passedTests passed, ${allFailedTests.length} failed');
      print('');
    }

    // Determine overall status
    final hasAnyFailures = packageResults.any(
      (pkg) => pkg.result == TestResult.failed,
    );
    final hasAnySuccess = packageResults.any(
      (pkg) => pkg.result == TestResult.success,
    );

    // Print package results if we have multiple packages
    if (packageResults.length > 1) {
      print('Package Results:');
      for (final pkg in packageResults) {
        final icon = switch (pkg.result) {
          TestResult.success => green('✓'),
          TestResult.failed => red('✗'),
          TestResult.noTests => '○',
          TestResult.noMatchingTests => '○',
        };
        final status = switch (pkg.result) {
          TestResult.success => 'passed',
          TestResult.failed => 'failed',
          TestResult.noTests => 'no tests',
          TestResult.noMatchingTests => 'no matching tests',
        };
        final testInfo = pkg.testCount != null && pkg.testCount! > 0
            ? ' (${pkg.testCount} tests)'
            : '';
        print('  $icon ${pkg.packageName} - $status$testInfo');
      }
      print('');
    }

    // Print failed tests summary if any
    if (allFailedTests.isNotEmpty) {
      print('${red('Failed Tests:')}');
      for (final failed in allFailedTests) {
        final pathStr = failed.path != null ? ' (${failed.path})' : '';
        print('  - "${failed.name}"$pathStr');
      }
      print('');
    }

    // Print overall result

    // Show warning when using filter and some packages failed but we found tests
    if (_nameOption != null && hasAnySuccess && hasAnyFailures) {
      final failedPackages = packageResults
          .where((pkg) => pkg.result == TestResult.failed)
          .map((pkg) => pkg.packageName)
          .join(', ');
      print(
          '${yellow('⚠')} Warning: Some packages could not be tested: $failedPackages');
      print(
          '  These packages might contain matching tests but failed to compile/run.');
      print('');
    }

    if (code == 0) {
      if (totalTests > 0) {
        final testWord = totalTests == 1 ? 'test' : 'tests';
        print('${green('✓')} $totalTests $testWord passed');
      } else {
        print('${green('✓ All tests passed')}');
      }
    } else if (code == -1) {
      if (hasAnyFailures) {
        print('${red('✗ Tests failed')}');
      } else if (_nameOption != null) {
        print('${red('✗ No tests matched filter')}: ${_nameOption}');
      } else {
        print('${red('✗ Tests failed')}');
      }
    } else if (code == -2) {
      print('○ No tests found');
    }

    print('=' * 60);
  }

  Future<_TestExecutionResult> _runTestsAtPath(String inputPath) async {
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
      return await _executeTests(package, explicitlySelected: true);
    }

    // Get the relative path from the package root
    final relativePath = normalizedPath.substring(packageRootPath.length + 1);

    return await _executeTests(
      package,
      relativePath: relativePath,
      explicitlySelected: true,
    );
  }

  Future<_TestExecutionResult> _runTestsInPackageNamed(String name) async {
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
    return await _executeTests(package, explicitlySelected: true);
  }

  /// Runs tests in a package, optionally targeting a specific path.
  ///
  /// [relativePath] is a path relative to the package root. Can be a file
  /// (e.g., `test/foo_test.dart`) or directory (e.g., `test/unit/`).
  /// If null, runs all tests in the package.
  ///
  /// When [explicitlySelected] is true, shows the package in output even if
  /// it has no tests. When false, silently skips packages without tests.
  Future<_TestExecutionResult> _executeTests(
    DartPackage package, {
    String? relativePath,
    required bool explicitlySelected,
  }) async {
    // Check for test directory (only when running whole package)
    if (relativePath == null && !package.testDir.existsSync()) {
      if (explicitlySelected) {
        // Explicitly selected package - show in output
        print('${red('✗')} ${package.name} (no tests)');
      }
      // Skip silently when not explicitly selected
      return _TestExecutionResult(TestResult.noTests);
    }

    // Print header
    final suffix = relativePath != null ? ' $relativePath' : '';
    print('${blue('▶')} testing ${package.name}$suffix...');

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

  Future<_TestExecutionResult> _runVerboseTest(
    DartPackage package,
    List<String> args, {
    String? relativePath,
  }) async {
    final stopwatch = Stopwatch()..start();

    // Stream output in real-time while also capturing for parsing
    final progress = Progress.print(capture: true);
    final result = await _runDartOrFlutter(
      package,
      args,
      progress: progress,
      nothrow: true,
    );

    stopwatch.stop();
    final duration = (stopwatch.elapsedMilliseconds / 1000.0).toStringAsFixed(
      1,
    );

    final stdout = progress.lines.join('\n');
    final testCount = _extractTestCount(stdout);

    final testPathStr = relativePath != null ? ' $relativePath' : '';

    // Check for "no matching tests" (exit code 79 is specific to this case)
    if (result.exitCode == 79) {
      print('○ ${package.name}$testPathStr (no matching tests)');
      return _TestExecutionResult(TestResult.noMatchingTests, testCount: 0);
    }

    if (result.exitCode == 0) {
      print('${green('✓')} ${package.name}$testPathStr (${duration}s)');
      return _TestExecutionResult(TestResult.success, testCount: testCount);
    }

    // Parse failed tests for summary
    final failedTests = _extractFailedTests(stdout);
    print('${red('✗')} ${package.name}$testPathStr (${duration}s)');
    return _TestExecutionResult(
      TestResult.failed,
      failedTests: failedTests ?? [],
      testCount: testCount,
    );
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

  Future<_TestExecutionResult> _runFastTest(
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

    // Check for "no matching tests" BEFORE checking success
    if (exitCode == 79 &&
        stdout.contains('No tests match regular expression')) {
      print('○ ${package.name}$testPathStr (no matching tests)');
      return _TestExecutionResult(TestResult.noMatchingTests, testCount: 0);
    }

    if (exitCode == 0) {
      final stats = [
        if (testCount != null) '$testCount tests',
        '${duration}s',
      ].join(', ');
      print('${green('✓')} ${package.name}$testPathStr ($stats)');
      return _TestExecutionResult(TestResult.success, testCount: testCount);
    }

    // Parse failed tests but don't show them yet (shown in summary)
    final failedTests = _extractFailedTests(stdout);
    final failedCount = failedTests?.length ?? 0;
    final stats = [
      if (testCount != null) '$testCount tests',
      if (failedCount > 0) '$failedCount failed',
      '${duration}s',
    ].join(', ');
    print('${red('✗')} ${package.name}$testPathStr ($stats)');

    // Only dump full output if this is NOT a test failure (e.g., compilation error)
    if (failedTests == null || failedTests.isEmpty) {
      print(stdout);
    }

    return _TestExecutionResult(
      TestResult.failed,
      failedTests: failedTests ?? [],
      testCount: testCount,
    );
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

/// Calculates the exit code based on test results.
/// Returns:
/// - 0: At least one test succeeded
/// - -1: Tests failed or all packages had no matching tests (when filter used)
/// - -2: No tests ran
@visibleForTesting
int calculateExitCodeFromResults(
  List<TestResult> results, {
  required int errorCount,
  required bool hasNameFilter,
}) {
  // When using name filter, success takes precedence
  // If we found and passed at least one test, that's what matters
  if (hasNameFilter && results.contains(TestResult.success)) {
    return 0;
  }

  // Actual test failures always fail
  if (results.contains(TestResult.failed)) {
    return -1;
  }

  // Explicit errors (user requested specific package with no tests)
  if (errorCount > 0) {
    return -1;
  }

  // At least one package succeeded - success!
  if (results.contains(TestResult.success)) {
    return 0;
  }

  // When using name filter, if ALL packages had noMatchingTests - fail
  if (hasNameFilter && results.contains(TestResult.noMatchingTests)) {
    return -1;
  }

  // No tests or all skipped
  return -2;
}

class _TestResultCollector {
  final List<TestResult> _results = [];
  final List<_PackageResult> _packageResults = [];
  int _errorCount = 0;
  bool _hasNameFilter = false;

  void add(
    TestResult result, {
    bool isError = false,
    String? packageName,
    List<_FailedTest>? failedTests,
    int? testCount,
  }) {
    _results.add(result);
    if (isError) _errorCount++;
    if (packageName != null) {
      _packageResults.add(
        _PackageResult(
          packageName: packageName,
          result: result,
          failedTests: failedTests ?? [],
          testCount: testCount,
        ),
      );
    }
  }

  // ignore: use_setters_to_change_properties
  void setHasNameFilter(bool value) {
    _hasNameFilter = value;
  }

  int get exitCode {
    return calculateExitCodeFromResults(
      _results,
      errorCount: _errorCount,
      hasNameFilter: _hasNameFilter,
    );
  }

  List<_PackageResult> get packageResults => _packageResults;

  List<_FailedTest> get allFailedTests {
    return _packageResults
        .expand((packageResult) => packageResult.failedTests)
        .toList();
  }

  int get totalTestsRun {
    return _packageResults
        .map((pkg) => pkg.testCount ?? 0)
        .fold(0, (sum, count) => sum + count);
  }
}

@visibleForTesting
enum TestResult {
  success, // Tests ran and passed
  failed, // Tests ran but some failed
  noTests, // No test directory
  noMatchingTests, // Tests exist but filter matched none
}

class _FailedTest {
  final String name;
  final String? path;

  _FailedTest(this.name, {this.path});
}

class _PackageResult {
  final String packageName;
  final TestResult result;
  final List<_FailedTest> failedTests;
  final int? testCount;

  _PackageResult({
    required this.packageName,
    required this.result,
    required this.failedTests,
    this.testCount,
  });
}

class _TestExecutionResult {
  final TestResult result;
  final List<_FailedTest> failedTests;
  final int? testCount;

  _TestExecutionResult(
    this.result, {
    this.failedTests = const [],
    this.testCount,
  });
}
