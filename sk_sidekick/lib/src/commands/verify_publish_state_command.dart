import 'package:sidekick_core/sidekick_core.dart';

class VerifyPublishStateCommand extends Command {
  @override
  final String description = 'Verifies a package is publishable to pub.dev';

  @override
  final String name = 'verify-publish-state';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        '[package-path]',
      );

  @override
  Future<void> run() async {
    final package = () {
      try {
        return DartPackage.fromArgResults(argResults!);
      } catch (_) {
        return null;
      }
    }();

    if (!isProgramInstalled('dartdoc')) {
      dart(['pub', 'global', 'activate', 'dartdoc', '6.1.5']);
    }

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
        verifyPackage(package);
        print("\n");
      }
    } else {
      verifyPackage(package);
    }
  }

  void verifyPackage(DartPackage package) {
    // Verify dart doc works without error
    final home = Platform.environment['HOME']!;
    '$home/.pub-cache/bin/dartdoc'.start(
      workingDirectory: package.root.path,
    );

    // dry-run publish should work without error
    final code = dart(
      ['pub', 'publish', '--dry-run'],
      workingDirectory: package.root,
      nothrow: true,
    );
    if (code != 0) {
      throw 'Publish dry-run failed';
    }
  }
}

bool _isPublishable(DartPackage package) {
  final pubspec = package.pubspec.readAsStringSync();
  return !pubspec.contains('publish_to: none');
}
