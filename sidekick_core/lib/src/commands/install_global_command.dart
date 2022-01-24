import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/global_sidekick_root.dart';

class InstallGlobalCommand extends Command {
  @override
  final String description = 'Installs the sidekick CLI globally';

  @override
  final String name = 'install-global';

  @override
  Future<void> run() async {
    _addBinDirToPath();

    // Get link to entrypoint
    final entryPoint = repository.entryPoint;
    // TODO inverse condition, or it won't make sense
    if (entryPoint != null) {
      GlobalSidekickRoot.linkBinary(entryPoint);
    }

    // repository.

    // dcli.ProcessHelper
    //
    // final os = Platform.operatingSystem;
    // final File installLocation = (){
    //
    //   File('/usr/local/bin/$cliName');
    //   File('/opt/sidekick/bin/$cliName'),
    // }();
    //
    // for ()

    ///   if [ ! -f "/usr/local/bin/$name" ] ; then
    ///     # when not linked globally
    ///     if [ -t 0 ] ; then
    ///       # stdin exits, human ist interacting with script
    ///       read -p "Do you want to install the $name sidekick globally? (y/n) " x
    ///       if [ "$x" = "y" ] ; then
    ///         sudo rm /usr/local/bin/$name > /dev/null 2>&1 || true
    ///         SH="$(realpath "${REPO_ROOT}${name}")"
    ///         sudo ln -s "${SH}" /usr/local/bin/$name
    ///         echo ""
    ///         echo "You can now use '$name' from everywhere"
    ///         echo ""
    ///       fi
    ///     fi
    ///   fi
    ///

    print(
      '\n'
      "You can now use '$cliName' from everywhere\n"
      '\n',
    );
  }

  void _addBinDirToPath() {
    final binDir = GlobalSidekickRoot.binDir;
    if (!dcli.isOnPATH(binDir.path)) {
      final added = Shell.current.appendToPATH(binDir.path);
      if (added) {
        printerr('Added ${binDir.path} to PATH');
      } else {
        print(
          '\n'
          'Please add ${binDir.path} to your PATH. \n'
          "Add this to your shell's config file (.zshrc, .bashrc, .bash_profile, ...)\n"
          '\n'
          "  ${dcli.green('export PATH="\$PATH":"${binDir.path}"')}\n"
          '\n'
          'Then, restart your terminal',
        );
      }
    }
  }
}
