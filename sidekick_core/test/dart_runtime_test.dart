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
    final progress = Progress.capture();
    await withEnvironmentAsync(() async {
      env['PATH'] = null;
      env['SIDEKICK_RUNTIME_TEST'] = 'scoped';
      await runtime.dart([script.path], progress: progress);
    }, environment: {});

    expect(progress.toList(), ['has PATH: false', 'scoped: scoped']);
    expect(env['PATH'], parentPath);

    final restoredProgress = Progress.capture();
    await runtime.dart([script.path], progress: restoredProgress);
    expect(restoredProgress.toList(), [
      'has PATH: true',
      'scoped: $originalScopedValue',
    ]);
  });
}
