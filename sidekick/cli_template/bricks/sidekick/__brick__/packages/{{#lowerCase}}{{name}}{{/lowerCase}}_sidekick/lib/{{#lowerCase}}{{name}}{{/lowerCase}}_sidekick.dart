import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick/src/commands/deps_command.dart';
import 'package:{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick/src/commands/update_sidekick_command.dart';
import 'package:{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick/src/{{#lowerCase}}{{name}}{{/lowerCase}}_command_runner.dart';
import 'package:{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick/src/{{#lowerCase}}{{name}}{{/lowerCase}}_project.dart';
import 'package:sidekick_core/sidekick_core.dart';

late {{#titleCase}}{{name}}{{/titleCase}}Project {{#lowerCase}}{{name}}{{/lowerCase}}Project;

class {{#titleCase}}{{name}}{{/titleCase}}Sidekick {
  /// Parses args and executes commands
  Future<void> runWithArgs(List<String> args) async {
    initializeSidekick(
      name: '{{name}}',
      mainProjectPath: '.',
    );

    {{#lowerCase}}{{name}}{{/lowerCase}}Project = {{#titleCase}}{{name}}{{/titleCase}}Project(mainProject.root);

    final runner = {{#titleCase}}{{name}}{{/titleCase}}CommandRunner()
      ..addCommand(UpdateSidekickCommand())
      ..addCommand(FlutterCommand())
      ..addCommand(DartCommand())
      ..addCommand(DepsCommand())
      ..addCommand(DartAnalyzeCommand());

    if (args.isEmpty) {
      print(runner.usage);
      exit(0);
    }

    try {
      await runner.run(args);
    } on UsageException catch (e) {
      print(e.usage);
      exit(1);
    }
  }
}
