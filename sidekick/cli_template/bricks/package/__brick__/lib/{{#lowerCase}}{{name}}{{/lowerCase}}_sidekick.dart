import 'dart:async';

import 'package:{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick/src/commands/clean_command.dart';
import 'package:{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick/src/{{#lowerCase}}{{name}}{{/lowerCase}}_project.dart';
import 'package:sidekick_core/sidekick_core.dart';

late {{#titleCase}}{{name}}{{/titleCase}}Project {{#lowerCase}}{{name}}{{/lowerCase}}Project;

Future<void> run{{#titleCase}}{{name}}{{/titleCase}}(List<String> args) async {
  final runner = initializeSidekick(
    name: '{{name}}',
    {{#hasMainProject}}mainProjectPath: '{{{mainProjectPath}}}',{{/hasMainProject}}
  );

  {{^mainProjectIsRoot}}{{#lowerCase}}{{name}}{{/lowerCase}}Project = {{#titleCase}}{{name}}{{/titleCase}}Project(runner.repository.root);{{/mainProjectIsRoot}}
  {{#mainProjectIsRoot}}{{#lowerCase}}{{name}}{{/lowerCase}}Project = {{#titleCase}}{{name}}{{/titleCase}}Project(runner.mainProject!.root);{{/mainProjectIsRoot}}
  runner
    ..addCommand(RecompileCommand())
    ..addCommand(FlutterCommand())
    ..addCommand(DartCommand())
    ..addCommand(DepsCommand())
    ..addCommand(CleanCommand())
    ..addCommand(PluginsCommand())
    ..addCommand(InstallGlobalCommand())
    ..addCommand(DartAnalyzeCommand());

  if (args.isEmpty) {
    print(runner.usage);
    return;
  }

  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e.usage);
    exit(64); // usage error
  }
}
