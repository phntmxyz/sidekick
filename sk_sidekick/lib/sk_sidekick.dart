import 'dart:async';

// sidekick_core gained its own TestCommand after 3.1.1, which collides with
// sk_sidekick's. Unrelated to exec; it surfaces as soon as sidekick_core is
// linked locally, and will break on the next sidekick_core release.
import 'package:sidekick_core/sidekick_core.dart' hide TestCommand;
import 'package:sk_sidekick/src/commands/bump_version_command.dart';
import 'package:sk_sidekick/src/commands/coverage_command.dart';
import 'package:sk_sidekick/src/commands/lock_dependencies_command.dart';
import 'package:sk_sidekick/src/commands/release_command.dart';
import 'package:sk_sidekick/src/commands/test_command.dart';
import 'package:sk_sidekick/src/commands/test_sidekick_context_command.dart';
import 'package:sk_sidekick/src/commands/verify_publish_state_command.dart';
import 'package:sk_sidekick/src/release/sidekick_bundled_version_bump.dart';
import 'package:sk_sidekick/src/release/sidekick_core_bundled_version_bump.dart';
import 'package:sk_sidekick/src/sk_project.dart';

late SkProject skProject;

Future<void> runSk(List<String> args) async {
  final runner = initializeSidekick(dartSdkPath: systemDartSdkPath());

  skProject = SkProject(SidekickContext.projectRoot);
  runner
    ..addCommand(CoverageCommand())
    ..addCommand(DartCommand())
    ..addCommand(DepsCommand(excludeGlob: ['**/templates/**']))
    ..addCommand(DartAnalyzeCommand())
    ..addCommand(FormatCommand(excludeGlob: ['**/test/templates/**']))
    ..addCommand(LockDependenciesCommand())
    ..addCommand(ReleaseCommand())
    ..addCommand(TestCommand())
    ..addCommand(VerifyPublishStateCommand())
    ..addCommand(
      BumpVersionCommand()
        ..addModification(sidekickCoreBundledVersionBump)
        ..addModification(sidekickBundledVersionBump),
    )
    ..addCommand(TestSidekickContextCommand())
    ..addCommand(SidekickCommand());

  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(64); // usage error
  }
}
