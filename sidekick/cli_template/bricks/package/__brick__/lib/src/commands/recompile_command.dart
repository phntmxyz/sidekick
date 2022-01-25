import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart' as dcli;
import 'package:{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick/{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick.dart';
import 'package:sidekick_core/sidekick_core.dart';

class RecompileCommand extends Command {
  @override
  final String description = 'Recompiles the {{#lowerCase}}{{name}}{{/lowerCase}} sidekick';

  @override
  final String name = 'recompile';

  @override
  Future<void> run() async {
    final installScript = {{#lowerCase}}{{name}}{{/lowerCase}}Project.root.file('packages/{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick/tool/install.sh');
    final process = dcli.start(installScript.path, nothrow: true, terminal: true);
    exit(process.exitCode ?? 0);
  }
}
