import 'package:args/command_runner.dart';

class {{#titleCase}}{{name}}{{/titleCase}}CommandRunner extends CommandRunner {
  {{#titleCase}}{{name}}{{/titleCase}}CommandRunner()
      : super('Sidekick', 'A convenience script that simplifies setting up and running your project project.');
}
