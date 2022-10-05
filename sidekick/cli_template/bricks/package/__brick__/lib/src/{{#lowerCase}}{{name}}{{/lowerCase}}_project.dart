import 'package:sidekick_core/sidekick_core.dart';

{{#mainProjectIsRoot}}class {{#titleCase}}{{name}}{{/titleCase}}Project extends DartPackage {
  factory {{#titleCase}}{{name}}{{/titleCase}}Project(Directory root) {
    final package = DartPackage.fromDirectory(root)!;
    return {{#titleCase}}{{name}}{{/titleCase}}Project._(package.root, package.name);
  }

  {{#titleCase}}{{name}}{{/titleCase}}Project._(Directory root, String name) : super.flutter(root, name);
{{/mainProjectIsRoot}}{{^mainProjectIsRoot}}
class {{#titleCase}}{{name}}{{/titleCase}}Project {
  {{#titleCase}}{{name}}{{/titleCase}}Project(this.root);

  final Directory root;{{/mainProjectIsRoot}}
  /// packages

  File get flutterw => root.file('flutterw');

  List<DartPackage>? _packages;
  List<DartPackage> get allPackages {
    return _packages ??= root
{{^mainProjectIsRoot}}        .directory('{{{mainProjectPath}}}'){{/mainProjectIsRoot}}
        .directory('packages')
        .listSync()
        .whereType<Directory>()
        .mapNotNull((it) => DartPackage.fromDirectory(it))
        .toList(){{^mainProjectIsRoot}};{{/mainProjectIsRoot}}
      {{#mainProjectIsRoot}}..add(this);{{/mainProjectIsRoot}}
  }
}
