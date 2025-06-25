import 'package:sidekick_core/sidekick_core.dart';

class CoverageCommand extends Command {
  @override
  String get description => 'Runs code coverage for a single file or package';

  @override
  String get name => 'coverage';

  @override
  Future<void> run() async {
    if (!_isPubGlobalInstalled('coverage')) {
      dart(['pub', 'global', 'activate', 'coverage']);
    }
    if (!isProgramInstalled('genhtml')) {
      if (Platform.isMacOS) {
        'brew install lcov'.run;
      } else {
        throw 'genhtml is not installed. Please install lcov';
      }
    }

    final package = () {
      try {
        return DartPackage.fromArgResults(argResults!);
      } catch (e) {
        return null;
      }
    }();
    if (package != null) {
      _runCoverage(package);
      return;
    } else {
      final file = File(argResults!.rest.first);
      if (!file.existsSync()) {
        throw 'Test file does not exist: ${file.path}';
      }
      final packageDir = file.parent.findParent(
        (dir) => DartPackage.fromDirectory(dir) != null,
      );
      if (packageDir == null) {
        throw '${file.path} is not within a dart package (could not find pubspec.yaml)';
      }
      final package = DartPackage.fromDirectory(packageDir)!;
      print(package);
      _runCoverage(package, file: file);
    }
  }
}

void _runCoverage(DartPackage package, {File? file}) {
  final coverageDir = package.root.directory('coverage');
  if (coverageDir.existsSync()) {
    coverageDir.deleteSync(recursive: true);
  }

  dart([
    'pub',
    'global',
    'run',
    'coverage:test_with_coverage',
    if (file != null) file.absolute.path,
  ], workingDirectory: package.root);

  'genhtml coverage/lcov.info -o coverage'.start(
    workingDirectory: package.root.path,
  );
  'open coverage/index.html'.start(workingDirectory: package.root.path);
}

bool _isPubGlobalInstalled(String packageName) {
  final p = Progress.capture();
  dart(['pub', 'global', 'list'], progress: p);
  final output = p.lines.join('\n');
  final regex = RegExp(r'(.+) \d.+');
  final matches = regex.allMatches(output);
  final packages = matches.map((m) => m.group(1)!).toList();
  return packages.contains(packageName);
}
