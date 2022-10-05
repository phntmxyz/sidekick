import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Adds the dependency to [package]
void addPubDependency(
  DartPackage package,
  String dependency, {
  String? version,
}) {
  startFromArgs(
    'dart',
    ['pub', 'remove', dependency],
    workingDirectory: package.root.path,
  );

  startFromArgs(
    'dart',
    ['pub', 'add', dependency, if (version != null) version],
    workingDirectory: package.root.path,
  );
}
