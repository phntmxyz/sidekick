import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  setUp(() {
    tempDir = Directory.systemTemp.createTempSync();
    print(tempDir.path);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  for (final cliName in const ['dashi', 'foo_bar']) {
    test('template generates expected files with cliName $cliName', () async {
      final template = SidekickTemplate();
      final props = SidekickTemplateProperties(
        name: cliName,
        entrypointLocation: tempDir.file(cliName),
        packageLocation: tempDir,
        mainProjectPath: '.',
        shouldSetFlutterSdkPath: true,
        isMainProjectRoot: true,
        hasNestedPackagesPath: true,
      );

      template.generate(props);

      final generatedFiles = tempDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.readAsStringSync().isNotEmpty)
          .map((e) => relative(e.path, from: tempDir.path))
          .toSet();
      final expectedFiles = {
        cliName,
        '.gitignore',
        'pubspec.yaml',
        'analysis_options.yaml',
        'bin/main.dart',
        'lib/src/commands/clean_command.dart',
        'lib/src/${cliName}_project.dart',
        'lib/${cliName}_sidekick.dart',
        'tool/install.sh',
        'tool/run.sh',
        'tool/download_dart.sh',
        'tool/sidekick_config.sh'
      };

      expect(generatedFiles, expectedFiles);

      run('dart pub get', workingDirectory: tempDir.path);
      if (analyzeGeneratedCode) {
        run('dart analyze --fatal-infos ${tempDir.path}');
        run('dart format --set-exit-if-changed ${tempDir.path}');
      } else {
        run('dart analyze ${tempDir.path}');
      }
    });
  }
}
