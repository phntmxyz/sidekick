import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Updates the sidekick cli
///
///
class UpdateCommand extends Command {
  @override
  final String description = 'Updates the sidekick cli';

  @override
  final String name = 'update';

  @override
  Future<void> run() async {
    // TODO (?) read version with which this sidekick CLI was generated (prerequisite: write this info into new block in pubspec) + current sidekick version on pub
    // TODO read this package's sidekick_core version + current sidekick_core version on pub

    final latestSidekickCoreVersion =
        await getLatestPackageVersion('sidekick_core');

    final currentMinimumSidekickCoreVersion =
        getCurrentMinimumPackageVersion('sidekick_core');

    if (currentMinimumSidekickCoreVersion >= latestSidekickCoreVersion) {
      print('No need to update because you are already using the '
          'latest version of sidekick_core ($latestSidekickCoreVersion)');
      return;
    }

    // TODO update pubspec.yaml

    updateVersionConstraint('sidekick_core', latestSidekickCoreVersion);
    dart(['pub', 'get'], workingDirectory: Repository.requiredCliPackage);

    // TODO generate new shell scripts (just overwrite because users shouldn't have to touch these files anyways)
    // ? how to call new generator (sidekick_core/lib/src/template)? maybe with reflection?

    // TODO apply changes to CLI dart files. how to preserve changes by users? Override everything but keep imports + ..addCommand(...)?

    bool isGitDir(Directory dir) => dir.directory('.git').existsSync();
    final entrypointDir = Repository.requiredEntryPoint.parent;
    final repoRoot = entrypointDir.findParent(isGitDir) ?? entrypointDir;
    final mainProjectPath = mainProject != null
        ? relative(mainProject!.root.path, from: repoRoot.absolute.path)
        : null;
    final isMainProjectRoot =
        mainProject?.root.absolute.path == repoRoot.absolute.path;
    final hasNestedPackagesPath = mainProject != null &&
        !relative(mainProject!.root.path, from: repoRoot.absolute.path)
            .startsWith('packages');

    final updateScript =
        Repository.requiredSidekickPackage.buildDir.file('update.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:mirrors';
import 'package:sidekick_core/src/template/sidekick_package.template.dart';

Future<void> main() async {
  final templateLibrary = currentMirrorSystem().libraries[Uri.parse(
      'package:sidekick_core/src/template/sidekick_package.template.dart')]!;

  final sidekickTemplateDefinition =
      templateLibrary.declarations[#SidekickTemplate]! as ClassMirror;
  final sidekickTemplatePropertiesDefinition =
      templateLibrary.declarations[#SidekickTemplateProperties]! as ClassMirror;

  final sidekickTemplateInstance =
      sidekickTemplateDefinition.newInstance(Symbol.empty, []);
      
  final Map<Symbol, dynamic> namedArguments = {
    #name: '${Repository.requiredSidekickPackage.cliName}',
    #entrypointLocation: File('${Repository.requiredEntryPoint.path}'),
    #packageLocation: Directory('${Repository.requiredCliPackage.path}'),
    #mainProjectPath: ${mainProjectPath != null ? '${mainProjectPath}' : null},
    #shouldSetFlutterSdkPath: ${runner!.commands.containsKey('flutter')},
    #isMainProjectRoot: $isMainProjectRoot,
    #hasNestedPackagesPath: $hasNestedPackagesPath,
  };
  
  final sidekickTemplatePropertiesInstance =
      sidekickTemplatePropertiesDefinition.newInstance(
    Symbol.empty,
    [],
    namedArguments,
  );

  sidekickTemplateInstance.invoke(
    #generateTools,
    [sidekickTemplatePropertiesInstance.reflectee],
  );
  sidekickTemplateInstance.invoke(
    #generateEntrypoint,
    [sidekickTemplatePropertiesInstance.reflectee],
  );
}
''');
    final exitCode = dart([updateScript.path]);
    if(exitCode != 0) throw 'error $exitCode';
  }

  Future<Version> getLatestPackageVersion(String package) async {
    final response =
        await get(Uri.parse('https://pub.dev/api/packages/$package'));

    if (response.statusCode != HttpStatus.ok) {
      throw "Package '$package' not found on pub.dev";
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final latestVersion = body['latest']['version'] as String;

    return Version.parse(latestVersion);
  }

  Version getCurrentMinimumPackageVersion(String package) {
    final regEx = RegExp(
      '\n  $package:\\s*[\'"\\^<>= ]*(\\d+\\.\\d+\\.\\d+(?:[+-]\\S+)?)',
    );
    final pubspec =
        Repository.requiredSidekickPackage.pubspec.readAsStringSync();

    final minVersion =
        regEx.allMatches(pubspec).map((e) => e.group(1)).whereNotNull().single;

    return Version.parse(minVersion);
  }

  void updateVersionConstraint(String package, Version newMinimumVersion) {
    final pubspec = Repository.requiredSidekickPackage.pubspec;
    final lines = pubspec.readAsLinesSync();

    final newVersionConstraint = newMinimumVersion.major > 0
        ? '^${newMinimumVersion.canonicalizedVersion}'
        : "'>=${newMinimumVersion.canonicalizedVersion} <1.0.0'";

    final index = lines.indexWhere((it) => it.startsWith('  $package:'));
    assert(index > 0);
    lines[index] = '  $package: $newVersionConstraint';

    pubspec.writeAsStringSync(lines.join('\n'));
  }
}
