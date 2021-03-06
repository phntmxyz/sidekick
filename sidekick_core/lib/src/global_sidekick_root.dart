import 'package:sidekick_core/sidekick_core.dart';

/// Wrapper for the global ~/.sidekick directory abstracting its functionality
class GlobalSidekickRoot {
  const GlobalSidekickRoot._();

  static Directory get dir {
    final userHome = Platform.environment['HOME']!;
    return Directory('$userHome/.sidekick');
  }

  static Directory get binDir {
    return Directory('${dir.path}/bin');
  }

  static String get binDirWithHomeEnv {
    final binDir = GlobalSidekickRoot.binDir;
    final userHome = Platform.environment['HOME']!;
    return join(r'$HOME', relative(binDir.path, from: userHome));
  }

  /// Creates a symlink from [binDir] to [file]
  static void linkBinary(File file) {
    create();
    final name = file.name;
    final destination = binDir.file(name);
    if (destination.existsSync()) {
      printerr('Overriding exiting linked binary ${destination.path}');
      destination.deleteSync();
    }
    Link(destination.path).createSync(file.absolute.path, recursive: true);
  }

  /// Use [Link.resolveSymbolicLinks] to access the path the link points to
  static Link linkedBinary(String name) {
    final binaryPath = binDir.file(name).path;
    return Link(binaryPath);
  }

  static void create() {
    if (dir.existsSync()) {
      return;
    }
    dir.createSync(recursive: true);
    binDir.createSync(recursive: true);
  }
}
