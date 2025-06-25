import 'package:sidekick_core/sidekick_core.dart';

class VerifyPublishStateCommand extends Command {
  @override
  final String description = 'Verifies a package is publishable to pub.dev';

  @override
  final String name = 'verify-publish-state';

  @override
  String get invocation =>
      super.invocation.replaceFirst('[arguments]', '[package-path]');

  @override
  Future<void> run() async {
    final package = () {
      try {
        return DartPackage.fromArgResults(argResults!);
      } catch (_) {
        return null;
      }
    }();

    if (package == null) {
      final allPackages = findAllPackages(SidekickContext.projectRoot)
          .where((it) => !it.root.path.contains('/templates/'))
          .where(_isPublishable)
          .toList();

      print(
        "Verifying packages ${allPackages.joinToString(transform: (it) => it.name)} "
        "to be publishable",
      );
      for (final package in allPackages) {
        print(yellow('=== package ${package.name} ==='));
        await verifyPackage(package);
        print("\n");
      }
    } else {
      await verifyPackage(package);
    }
  }

  Future<void> verifyPackage(DartPackage package) async {
    // Verify dart doc works without error
    dart(
      ['doc', '--dry-run'],
      throwOnError: () => 'Generating dart doc failed',
      workingDirectory: package.root,
    );

    await dryRunPubPublish(package);
  }

  /// Runs `dart pub publish --dry-run` and checks for warnings,
  /// manually ignoring some due to https://github.com/dart-lang/pub/issues/3807
  Future<void> dryRunPubPublish(DartPackage package) async {
    final progress = Progress.print(capture: true);
    dart(
      ['pub', 'publish', '--dry-run'],
      workingDirectory: package.root,
      progress: progress,
      nothrow: true,
    );

    final output = progress.lines.join('\n');

    // Parse "Package has X warning(s)." or "Package has X warnings." from entire output
    final warningMatch = RegExp(
      r'Package has (\d+) warning',
    ).firstMatch(output);
    if (warningMatch == null) {
      // No warning summary found - check if output contains error indicators
      if (output.toLowerCase().contains('error') ||
          output.toLowerCase().contains('failed')) {
        throw 'Publish dry-run failed:\n'
            '$output';
      }
      // If no errors and no warning summary, assume success
      return;
    }

    int warningCount = int.parse(warningMatch.group(1)!);

    // Check for known acceptable warnings and decrement count
    const preReleaseVersionWarning =
        'Packages dependent on a pre-release of another package should themselves';
    if (output.contains(preReleaseVersionWarning)) {
      print(
        '🫣 Ignoring warning publishing-prereleases: $preReleaseVersionWarning...',
      );
      warningCount--;
    }

    if (warningCount > 0) {
      throw 'Publish dry-run failed with $warningCount unacceptable warning(s)';
    }
  }
}

bool _isPublishable(DartPackage package) {
  final pubspec = package.pubspec.readAsStringSync();
  return !pubspec.contains('publish_to: none');
}
