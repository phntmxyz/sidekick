import 'package:sidekick_core/sidekick_core.dart';

/// dart analyze on the whole project
class DartAnalyzeCommand extends ForwardCommand {
  @override
  final String description = 'Dart analyzes the whole project';

  @override
  final String name = 'analyze';

  @override
  Future<void> run() async {
    // running in root of project, includes all packages
    // TODO run for each package separately, with different SDK versions
    final completion = await dart(
      ['analyze', ...argResults!.arguments],
      workingDirectory: SidekickContext.projectRoot,
      nothrow: true,
    );
    exitCode = completion.exitCode ?? 1;
  }
}
