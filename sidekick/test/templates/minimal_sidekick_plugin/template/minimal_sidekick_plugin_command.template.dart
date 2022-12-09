import 'package:minimal_sidekick_plugin/minimal_sidekick_plugin.dart';
import 'package:sidekick_core/sidekick_core.dart';

class MinimalSidekickPluginCommand extends Command {
  @override
  final String description = 'Sample command';

  @override
  final String name = 'minimal-sidekick-plugin';

  MinimalSidekickPluginCommand() {
    // add parameters here with argParser.addOption
  }

  @override
  Future<void> run() async {
    // please implement me
    final hello = getGreetings().shuffled().first;
    print('$hello from PHNTM!');

    final bye = getFarewells().shuffled().first;
    print('$bye from PHNTM!');
  }
}
