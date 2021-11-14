import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason/mason.dart';
import 'package:sidekick/src/init/project_structure_detector.dart';
import 'package:sidekick/src/templates/templates.dart';

/// A method which returns a [Future<MasonGenerator>] given a [MasonBundle].
typedef GeneratorBuilder = Future<MasonGenerator> Function(MasonBundle);

class InitCommand extends Command {
  @override
  String get description => 'Creates a new sidekick CLI';

  @override
  String get name => 'init';

  /// Holds all Sidekick Templates
  final _templates = SidekickTemplate();

  InitCommand() {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'The path to the Dart/Flutter project the sidekick cli should be created for',
      )
      ..addOption(
        'cliName',
        abbr: 'n',
        help: 'The name of the CLI to be created \n The `_cli` prefix, will be define automaticaly',
      );
  }

  @override
  Future<void> run() async {
    final cwd = Directory.current;
    final Directory projectDir = () {
      final path = argResults!['path'] as String?;
      if (path != null) {
        final dir = Directory(path);
        if (!dir.existsSync()) {
          throw '${dir.path} is not a valid path to a Dart/Flutter project';
        }
        return dir;
      }
      // fallback to cwd
      return cwd;
    }();
    final cliName = argResults!['cliName'] as String?;
    if (cliName == null) {
      throw 'No CLI name provided';
    }

    final detector = ProjectStructureDetector();
    final type = detector.detectProjectType(projectDir);

    switch (type) {
      case ProjectStructure.simple:
        createSidekickPackage(path: projectDir, cliName: cliName);
        break;
      case ProjectStructure.multiPackage:
        throw 'The multi package project layout is not yet supported';
      case ProjectStructure.rootWithPackages:
        print('Detected a Dart/Flutter project with a /packages dictionary');
        createSidekickPackage(path: projectDir, cliName: cliName);
        break;
      case ProjectStructure.unknown:
        print(
          'The project structure is not yet supported. '
          'Please open an issue at https://github.com/phntmxyz/sidekick/issues with details about your project structure',
        );
        exit(1);
    }
  }

  Future<void> createSidekickPackage({required Directory path, required String cliName}) async {
    final generator = await MasonGenerator.fromBundle(_templates.bundle);
    final generatorTarget = DirectoryGeneratorTarget(path, Logger(), FileConflictResolution.prompt);
    generator.generate(
      generatorTarget,
      vars: <String, dynamic>{
        'name': cliName,
      },
    );
  }
}
