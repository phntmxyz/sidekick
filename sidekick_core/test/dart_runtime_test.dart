import 'package:exec/exec.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  test('dart respects scoped environment removals and additions', () async {
    final parentPath = Platform.environment['PATH'];
    final originalScopedValue = env['SIDEKICK_RUNTIME_TEST'];
    expect(parentPath, isNotNull);
    final package = Directory.systemTemp.createTempSync('sidekick_runtime_');
    addTearDown(() => package.deleteSync(recursive: true));
    final runtime = SidekickDartRuntime(package);
    Link(package.file('build/cache/dart-sdk').path).createSync(
      File(Platform.resolvedExecutable).parent.parent.path,
      recursive: true,
    );
    final script = package.file('environment.dart')..writeAsStringSync(r'''
import 'dart:io';

void main() {
  print('has PATH: ${Platform.environment.containsKey("PATH")}');
  print('scoped: ${Platform.environment["SIDEKICK_RUNTIME_TEST"]}');
}
''');
    late final ExecResult scoped;
    await withEnvironmentAsync(() async {
      env['PATH'] = null;
      env['SIDEKICK_RUNTIME_TEST'] = 'scoped';
      scoped = await runtime.dart([script.path], output: ExecOutput.capture);
    }, environment: {});

    expect(scoped.stdoutLines, ['has PATH: false', 'scoped: scoped']);
    expect(env['PATH'], parentPath);

    final restored =
        await runtime.dart([script.path], output: ExecOutput.capture);
    expect(restored.stdoutLines, [
      'has PATH: true',
      'scoped: $originalScopedValue',
    ]);
  });
}
