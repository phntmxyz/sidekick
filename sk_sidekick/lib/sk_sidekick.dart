import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sk_sidekick/src/commands/bump_version_command.dart';
import 'package:sk_sidekick/src/release/core_bundled_version_bump.dart';
import 'package:sk_sidekick/src/sk_project.dart';

late SkProject skProject;

Future<void> runSk(List<String> args) async {
  final runner = initializeSidekick(
    name: 'sk',
    flutterSdkPath: systemFlutterSdkPath(),
  );

  skProject = SkProject(runner.repository.root);
  runner
    ..addCommand(DartCommand())
    ..addCommand(DepsCommand(exclude: [...testPackages]))
    ..addCommand(DartAnalyzeCommand())
    ..addCommand(
      BumpVersionCommand()..addModification(coreBundledVersionBump),
    )
    ..addCommand(SidekickCommand());

  if (args.isEmpty) {
    print(runner.usage);
    return;
  }

  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e.usage);
    exit(64); // usage error
  }
}

/// sample packages for testing that should be ignored by deps command
final testPackages = [
  'sidekick/test/templates/minimal_dart_package',
  'sidekick/test/templates/root_with_packages',
  'sidekick/test/templates/root_with_packages/packages/package_b',
  'sidekick/test/templates/root_with_packages/packages/package_a',
  'sidekick/test/templates/minimal_flutter_package',
  'sidekick/test/templates/nested_package/foo/bar/nested',
  'sidekick/test/templates/multi_package/packages/package_b',
  'sidekick/test/templates/multi_package/packages/package_a',
].mapNotNull((it) => DartPackage.fromDirectory(skProject.root.directory(it)));
