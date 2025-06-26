import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final migrateAddSdkInitializer_272 = MigrationStep.inline(
  (context) {
    final projectRoot = SidekickContext.projectRoot;

    // Find all Dart files in the project
    final dartFiles = projectRoot
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

    int updatedFiles = 0;

    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      final updatedContent = content.replaceAll(
        'addFlutterSdkInitializer',
        'addSdkInitializer',
      );

      if (content != updatedContent) {
        file.writeAsStringSync(updatedContent);
        updatedFiles++;
      }
    }

    if (updatedFiles > 0) {
      print(
        'Updated $updatedFiles Dart files to use addSdkInitializer instead of addFlutterSdkInitializer',
      );
    }
  },
  name: 'Replace addFlutterSdkInitializer with addSdkInitializer',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/272',
  targetVersion: Version(3, 0, 1),
);
