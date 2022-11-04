import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  group('sidekick template', () {
    test('makes entrypoint executable', () {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final entrypoint = tempDir.file('dashi');
      final props = SidekickTemplateProperties(
        name: 'dashi',
        entrypointLocation: entrypoint,
        packageLocation: tempDir.directory('dashi_sidekick'),
        mainProjectPath: '.',
        shouldSetFlutterSdkPath: false,
        isMainProjectRoot: true,
        hasNestedPackagesPath: false,
      );
      SidekickTemplate().generate(props);

      expect(entrypoint.existsSync(), true);
      expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');
    });

    test('makes tool scripts executable', () {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final package = tempDir.directory('dashi_sidekick');
      final props = SidekickTemplateProperties(
        name: 'dashi',
        entrypointLocation: tempDir.file('dashi'),
        packageLocation: package,
        mainProjectPath: '.',
        shouldSetFlutterSdkPath: false,
        isMainProjectRoot: true,
        hasNestedPackagesPath: false,
      );
      SidekickTemplate().generate(props);

      expect(
        package.file('tool/download_dart.sh').statSync().modeString(),
        'rwxr-xr-x',
      );
      expect(
        package.file('tool/install.sh').statSync().modeString(),
        'rwxr-xr-x',
      );
      expect(
        package.file('tool/run.sh').statSync().modeString(),
        'rwxr-xr-x',
      );
      expect(
        package.file('tool/sidekick_config.sh').statSync().modeString(),
        'rwxr-xr-x',
      );
    });
  });
}
