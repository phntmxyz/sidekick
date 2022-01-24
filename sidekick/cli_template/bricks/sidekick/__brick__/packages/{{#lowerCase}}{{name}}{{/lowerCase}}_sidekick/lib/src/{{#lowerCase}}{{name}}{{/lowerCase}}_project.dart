import 'package:sidekick_core/sidekick_core.dart';

class {{#titleCase}}{{name}}{{/titleCase}}Project extends DartPackage {
  factory {{#titleCase}}{{name}}{{/titleCase}}Project(Directory root) {
    final package = DartPackage.fromDirectory(root)!;
    return {{#titleCase}}{{name}}{{/titleCase}}Project._(package.root, package.name);
  }

  {{#titleCase}}{{name}}{{/titleCase}}Project(Directory root) : super.flutter(root, name);

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
