import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Recompiles the sidekick cli
///
/// Usually the cli recompiles itself when code changes. But some code changes
/// can't be picked up automatically, i.e. when code of path dependencies changes
class RecompileCommand extends Command {
  @override
  final String description = 'Recompiles the sidekick cli';

  @override
  final String name = 'recompile';

  @override
  Future<void> run() async {
    final installScript =
        SidekickContext.sidekickPackage.root.file('tool/install.sh');
    final bash = which('bash');
    final String bashExe;
    if (bash.found) {
      bashExe = bash.path!;
    } else {
      bashExe = '/usr/bin/bash';
    }
    final progress = startFromArgs(
      bashExe,
      [installScript.path],
      nothrow: true,
      terminal: true,
    );
    exitCode = progress.exitCode ?? -1;
  }
}
