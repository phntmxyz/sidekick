import 'package:sidekick_core/sidekick_core.dart';

class {{#titleCase}}{{name}}{{/titleCase}}Project extends DartPackage {
  {{#titleCase}}{{name}}{{/titleCase}}Project(Directory root) : super.flutter(root, '');

  DartPackage get {{#lowerCase}}{{name}}{{/lowerCase}}SidekickPackage => DartPackage.fromDirectory(root.directory('packages/{{#lowerCase}}{{name}}{{/lowerCase}}_sidekick'))!;

  File get flutterw => root.file('flutterw');

  List<DartPackage>? _packages;
  List<DartPackage> get allPackages {
    return _packages ??= root
        .directory('packages')
        .listSync()
        .whereType<Directory>()
        .mapNotNull((it) => DartPackage.fromDirectory(it))
        .toList()
      ..add(this);
  }
}
