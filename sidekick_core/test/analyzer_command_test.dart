import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('analyze command sets exitCode 1 when command fails', () async {
    await insideFakeProjectWithSidekick((dir) async {
      dir.file('dash_sidekick.dart').writeAsStringSync('''
void main() {
  print('Hello World');
}''');
      dir.file('analysis_options.yaml').writeAsStringSync('''
linter:
  rules:
    - avoid_print
''');

      final runner = initializeSidekick(dartSdkPath: systemDartSdkPath());
      runner.addCommand(DartAnalyzeCommand());
      await runner.run(['analyze', '--fatal-infos']);
      expect(exitCode, 1);
    });
  });

  test('analyze command sets exitCode 0 when command completes normally',
      () async {
    await insideFakeProjectWithSidekick((dir) async {
      dir.file('dash_sidekick.dart').writeAsStringSync('void main() {}');

      final runner = initializeSidekick(dartSdkPath: systemDartSdkPath());
      runner.addCommand(DartAnalyzeCommand());
      await runner.run(['analyze', '--fatal-infos']);
      expect(exitCode, 0);
    });
  });
}
