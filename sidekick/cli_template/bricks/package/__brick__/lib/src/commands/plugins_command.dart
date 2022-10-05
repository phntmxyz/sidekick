import 'package:sidekick_core/sidekick_core.dart';

// TODO move into sidekick_core
class PluginsCommand extends Command {
  @override
  final String description = 'Manages plugins for external commands';

  @override
  final String name = 'plugins';

  PluginsCommand() {
    addSubcommand(AddPluginsCommand());
  }
}

class AddPluginsCommand extends Command {
  @override
  final String description = 'Adds a new command to this sidekick cli';

  @override
  final String name = 'add';

  @override
  Future<void> run() async {
    final rest = argResults!.rest.firstOrNull;
    if (rest == null || rest.isEmpty) {
      printerr(red('Please provide then name of the plugin'));
      return;
    }
    final split = rest.split('@');
    final String name = split[0];
    final String? version = split.length > 1 ? split[1] : null;

    print(green("Installing $name"));

    // TODO
    // Run plugin installer
    // Research how pub global activate downloads the package.
    // Use pub package to download packages. All is done, only SystemCache has to be pointed to /build
    // https://github.com/dart-lang/pub/blob/master/lib/src/command/global_activate.dart
    // https://github.com/dart-lang/pub/blob/master/lib/src/global_packages.dart
    // https://github.com/dart-lang/pub/blob/bc32a30ea5c86653e2a1899613c0a19d91b9a21c/lib/src/system_cache.dart
    // https://github.com/dart-lang/pub/blob/610ce7f280189f39ec411eb0a8592a191940d8d2/lib/src/solver/result.dart
    // Save it in /build/plugins
    // run dart pub get on plugin
    // Execute their bin/install.dart file
    // Run dart pub get on sidekick cli
    // Show errors warning, further instructions
  }
}
