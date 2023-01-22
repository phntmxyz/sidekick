import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/global_sidekick_root.dart';

class InstallGlobalCommand extends Command {
  @override
  final String description = 'Installs this custom sidekick CLI globally';

  @override
  final String name = 'install-global';

  InstallGlobalCommand() {
    argParser.addOption('sidekick-entry-point');
  }

  @override
  Future<void> run() async {
    if (isProgramInstalled(SidekickContext.cliName)) {
      print('program ${SidekickContext.cliName} is already globally installed');
      exit(0);
    }

    /// The entrypoint injects its location
    GlobalSidekickRoot.linkBinary(SidekickContext.entryPoint);

    if (dcli.isOnPATH(GlobalSidekickRoot.binDir.path)) {
      print(
        '\n'
        "You can now use '${SidekickContext.cliName}' from everywhere\n"
        '\n',
      );
      return;
    }

    _addBinDirToPathOrPrint();
  }

  void _addBinDirToPathOrPrint() {
    final binDirPath = GlobalSidekickRoot.binDirWithHomeEnv;
    try {
      // depending on the shell and dcli version, this can throw.
      // E.g. dcli-1.30.3 zsh_shell.dart: UnsupportedError('Not supported in zsh')
      final added = Shell.current.appendToPATH(binDirPath);
      if (added) {
        printerr('Added $binDirPath to PATH');
        return;
      }
    } catch (_) {
      // ignore
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
