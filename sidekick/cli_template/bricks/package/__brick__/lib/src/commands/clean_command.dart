import 'package:sidekick_core/sidekick_core.dart';

class CleanCommand extends Command {
  @override
  final String description = 'Cleans the project';

  @override
  final String name = 'clean';

  @override
  Future<void> run() async {
    {{#hasMainProject}}flutter(['clean'], workingDirectory: mainProject?.root);{{/hasMainProject}}
    // TODO Please add your own project clean logic here

    print('✔️Cleaned project');
  }
}
