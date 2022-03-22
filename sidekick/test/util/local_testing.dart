import 'package:path/path.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// True when dependencies should be linked to local sidekick dependencies
late bool shouldUseLocalDevs = env['SIDEKICK_LOCAL_DEPS'] == 'true';

/// Add this to the test name
String localOrPubDepsLabel = shouldUseLocalDevs ? "(local)" : "(pub)";

/// Changes the sidekick_core dependency to a local override
void overrideSidekickCoreWithLocalPath(Directory sidekickProject) {
  print('Overriding sidekick_core dependency to local');
  final pubspec = sidekickProject.file("pubspec.yaml");
  // assuming cwd when running those tests is in the sidekick package
  final corePath = absolute('../sidekick_core');
  pubspec.writeAsStringSync(
    '''

dependency_overrides:
  sidekick_core:
    path: $corePath

  ''',
    mode: FileMode.append,
  );
}
