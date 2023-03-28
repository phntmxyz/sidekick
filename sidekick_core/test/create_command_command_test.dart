import 'package:sidekick_core/sidekick_core.dart' hide isEmpty;
import 'package:sidekick_core/src/commands/create_command_command.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  group('Create Command Command', () {
    test('writes command and registers it', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final registryFile = dir.file('packages/dash/lib/dash_sidekick.dart')
          ..createSync()
          ..writeAsStringSync('''
import 'dart:async';

import 'package:mycli_sidekick/src/commands/clean_command.dart';
import 'package:sidekick_core/sidekick_core.dart';

Future<void> runMycli(List<String> args) async {
  final runner = initializeSidekick(
    
    dartSdkPath: systemDartSdkPath(),
  );

  runner
    ..addCommand(DartCommand())
    ..addCommand(DepsCommand())
    ..addCommand(CleanCommand())
    ..addCommand(DartAnalyzeCommand())
    ..addCommand(FormatCommand())
    ..addCommand(SidekickCommand());

  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(64); // usage error
  }
}
        ''');

        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );

        runner.addCommand(CreateCommandCommand());
        await runner.run(['create-command', 'awesome-thing']);

        final commandFile = dir
            .directory('packages/dash/lib/src/commands')
            .file('awesome_thing_command.dart');
        expect(commandFile.existsSync(), isTrue);
        expect(
          commandFile.readAsStringSync(),
          contains('class AwesomeThingCommand'),
        );
        expect(
          commandFile.readAsStringSync(),
          contains('AwesomeThingCommand()'),
        );

        expect(
          registryFile.readAsStringSync(),
          contains('..addCommand(AwesomeThingCommand());'),
        );
        expect(
          registryFile.readAsStringSync(),
          contains(
            "import 'package:dash/src/commands/awesome_thing_command.dart';\n",
          ),
        );
      });
    });
  });
}
