import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sidekick/src/init/project_structure_detector.dart';
import 'package:dartx/dartx_io.dart';

class InitCommand extends Command {
  @override
  String get description => 'Creates a new sidekick CLI';

  @override
  String get name => 'init';

  InitCommand() {
    argParser.addOption('path', help: 'The path to the Dart/Flutter project the sidekick cli should be created for');
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

    final detector = ProjectStructureDetector();
    final type = await detector.detectProjectType(projectDir);

    switch (type) {
      case ProjectStructure.simple:
        throw 'A simple project layout is not yet supported';
      case ProjectStructure.multi_package:
        throw 'The multi package project layout is not yet supported';
      case ProjectStructure.root_with_packages:
        print('Detected a Dart/Flutter project with a /packages dictionary');
        createSidekickPackage(path: projectDir.directory('packages/sidekick'));
        break;
      case ProjectStructure.unknown:
        print('The project structure is not yet supported.'
            'Please open an issue at https://github.com/phntmxyz/sidekick/issues with details about your project structure');
        exit(1);
    }
  }

  void createSidekickPackage({required Directory path}) {
    throw "TODO";
  }
}
