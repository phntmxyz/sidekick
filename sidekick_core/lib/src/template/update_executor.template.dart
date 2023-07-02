import 'package:meta/meta.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// The UpdateExecutor writes a dart package with just the sidekick_core
/// dependency and allows executing the update_sidekick_cli.dart script.
class UpdateExecutorTemplate {
  @visibleForTesting
  static UpdateExecutorTemplate Function({
    required Directory location,
    required Version dartSdkVersion,
    required Version newSidekickCoreVersion,
    required Version oldSidekickCoreVersion,
  })? testFakeCreateUpdateExecutorTemplate;

  factory UpdateExecutorTemplate({
    required Directory location,
    required Version dartSdkVersion,
    required Version newSidekickCoreVersion,
    required Version oldSidekickCoreVersion,
  }) {
    if (testFakeCreateUpdateExecutorTemplate != null) {
      return testFakeCreateUpdateExecutorTemplate!(
        location: location,
        dartSdkVersion: dartSdkVersion,
        oldSidekickCoreVersion: oldSidekickCoreVersion,
        newSidekickCoreVersion: newSidekickCoreVersion,
      );
    }
    return UpdateExecutorTemplate.raw(
      location: location,
      dartSdkVersion: dartSdkVersion,
      oldSidekickCoreVersion: oldSidekickCoreVersion,
      newSidekickCoreVersion: newSidekickCoreVersion,
    );
  }

  UpdateExecutorTemplate.raw({
    required this.location,
    required this.dartSdkVersion,
    required this.oldSidekickCoreVersion,
    required this.newSidekickCoreVersion,
  });

  final Directory location;
  final Version dartSdkVersion;
  final Version oldSidekickCoreVersion;
  final Version newSidekickCoreVersion;

  void generate() {
    location.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: ${makeValidPubPackageName('update_${newSidekickCoreVersion.canonicalizedVersion}')}
environment:
  sdk: '>=${dartSdkVersion.canonicalizedVersion} <${dartSdkVersion.nextBreaking.canonicalizedVersion}'
dependencies:
  sidekick_core: ${newSidekickCoreVersion.canonicalizedVersion}
dependency_overrides:
  # `pubspec2` is a transitive dependency of `dcli`, but `pubspec2` v2.5.0 breaks `dcli` v2 (see https://github.com/onepub-dev/dcli/issues/218)
  pubspec2: '>=2.0.0 <2.5.0'
''');

    final updateScript = location.file('bin/update.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:sidekick_core/src/update_sidekick_cli.dart' as update;
Future<void> main(List<String> args) async {
  await update.main(args);
}
  ''');
    assert(updateScript.existsSync());
  }
}
