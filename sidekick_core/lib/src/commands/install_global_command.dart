import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/global_sidekick_root.dart';

class InstallGlobalCommand extends Command {
  @override
  final String description = 'Installs the sidekick CLI globally';

  @override
  final String name = 'install-global';

  InstallGlobalCommand() {
    argParser.addOption('sidekick-entry-point');
  }

  @override
  Future<void> run() async {
    if (isProgramInstalled(cliName)) {
      print('program $cliName is already globally installed');
      exit(0);
    }

    /// The entrypoint injects its location
    final injectedEntryPointPath = env['SIDEKICK_ENTRYPOINT_HOME'];
    final entrypoint = File(normalize('$injectedEntryPointPath/$cliName'));
    if (injectedEntryPointPath == null) {
      error('$cliName not called via entrypoint executable');
    } else {
      if (!entrypoint.existsSync()) {
        error('Entrypoint does not exist at ${entrypoint.absolute.path}');
      }
    }

    GlobalSidekickRoot.linkBinary(entrypoint);

    final binDirPath = GlobalSidekickRoot.binDirWithHomeEnv;
    if (dcli.isOnPATH(binDirPath)) {
      print(
        '\n'
        "You can now use '$cliName' from everywhere\n"
        '\n',
      );
      return;
    }

    _addBinDirToPathOrPrint();
  }

  void _addBinDirToPathOrPrint() {
    final binDirPath = GlobalSidekickRoot.binDirWithHomeEnv;
    final added = Shell.current.appendToPATH(binDirPath);
    if (added) {
      printerr('Added $binDirPath to PATH');
      return;
    }

    print(
      '\n'
      'Please add $binDirPath to your PATH. \n'
      "Add this to your shell's config file (.zshrc, .bashrc, .bash_profile, ...)\n"
      '\n'
      "  ${dcli.green('export PATH="\$PATH":"$binDirPath"')}\n"
      '\n'
      'Then, restart your terminal',
    );
  }
}
