import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sk_sidekick/sk_sidekick.dart';

/// Updates the version in sidekick_core/lib/sidekick_core.dart
void coreBundledVersionBump(
    DartPackage package, Version oldVersion, Version newVersion) {
  if (package != skProject.sidekickCorePackage) {
    return;
  }

  // Update version for core package
  final coreFile =
      skProject.sidekickCorePackage.root.file('lib/sidekick_core.dart');
  coreFile.replaceSectionWith(
    startTag: 'final Version version = Version.parse(',
    endTag: ');',
    content: "'$newVersion'",
  );
  if (!coreFile.readAsStringSync().contains(newVersion.toString())) {
    throw 'Failed to update version in ${coreFile.path}';
  }
}
