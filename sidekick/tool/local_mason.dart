import 'package:mason_cli/src/command_runner.dart';

/// Allows execution of the bundled mason version
///
/// Installing the mason CLI on the system doesn't produce a stable output.
/// - mason has terrible versioning and doesn't follow semver
/// - pub global activate pulls the latest dependencies. Due to breaking changes
///   inside mason, using the latest dependencies doesn't work
/// - pinning exact versions in the pubspec.yaml here is the only way to ensure
///   it compiles forever
Future<void> main(List<String> args) async {
  await MasonCommandRunner().run(args);
}
