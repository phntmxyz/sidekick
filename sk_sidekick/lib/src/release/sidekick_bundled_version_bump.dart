import 'package:sidekick_core/sidekick_core.dart';
import 'package:sk_sidekick/sk_sidekick.dart';

/// Updates the version in sidekick/lib/sidekick_core.dart
void sidekickBundledVersionBump(
  DartPackage package,
  Version oldVersion,
  Version newVersion,
) {
  if (package != skProject.sidekickPackage) {
    return;
  }

  // Update version for sidekick package
  final sidekickFile = skProject.sidekickPackage.root.file('lib/sidekick.dart');
  sidekickFile.replaceSectionWith(
    startTag: 'final Version version = Version.parse(',
    endTag: ');',
    content: "'$newVersion'",
  );
  if (!sidekickFile.readAsStringSync().contains(newVersion.toString())) {
    throw 'Failed to update version in ${sidekickFile.path}';
  }
}
