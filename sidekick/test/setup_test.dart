import 'package:sidekick/src/init/project_structure_detector.dart';
import 'package:test/test.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() {
  group('project type detection', () {
    test('minimal dart project', () {
      final project = setupTemplateProject('test/templates/minimal_dart_package');
      final detector = ProjectStructureDetector();
      final result = detector.detectProjectType(project);
      expect(result, ProjectStructure.simple);
    });
  });
}

Directory setupTemplateProject(String path) {
  final projectRoot = Directory.systemTemp.createTempSync();
  addTearDown(() {
    projectRoot.deleteSync(recursive: true);
  });
  final template = Directory(path);
  for (final entity in template.listSync(recursive: true)) {
    final relativeToRoot = relative(entity.path, from: template.path);
    final copyTo = "${projectRoot.path}/$relativeToRoot";
    if (entity is File) {
      entity.parent.createSync(recursive: true);
      entity.copySync(copyTo);
    }
    if (entity is Directory) {
      Directory(copyTo).createSync(recursive: true);
    }
  }

  return projectRoot;
}
