import 'package:sidekick/src/init/project_structure_detector.dart';
import 'package:test/test.dart';

import 'templates/templates.dart';

void main() {
  group('project type detection', () {
    test('minimal dart project', () {
      final project =
          setupTemplateProject('test/templates/minimal_dart_package');
      final detector = ProjectStructureDetector();
      final result = detector.detectProjectType(project);
      expect(result, ProjectStructure.simple);
    });

    test('multi package', () {
      final project = setupTemplateProject('test/templates/multi_package');
      final detector = ProjectStructureDetector();
      final result = detector.detectProjectType(project);
      expect(result, ProjectStructure.multiPackage);
    });

    test('root with packages', () {
      final project = setupTemplateProject('test/templates/root_with_packages');
      final detector = ProjectStructureDetector();
      final result = detector.detectProjectType(project);
      expect(result, ProjectStructure.rootWithPackages);
    });
  });
}
