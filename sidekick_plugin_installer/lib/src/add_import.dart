import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Adds a dart import to [file]
Future<void> addImport(File file, String import) async {
  if (!file.existsSync()) {
    throw Exception('File ${file.path} does not exist');
  }
  if (!file.name.endsWith('.dart')) {
    throw Exception('File ${file.path} is not a dart file');
  }
  final collection = AnalysisContextCollection(includedPaths: [file.path]);
  final context = collection.contextFor(file.path);
  final parsed = context.currentSession.getParsedUnit(file.path);

  if (parsed is ParsedUnitResult) {
    final imports = parsed.unit.directives.whereType<ImportDirective>();
    if (imports.map((e) => e.toSource()).contains(import)) {
      return;
    }
    // find position to insert import alphabetically
    final after = imports.firstOrNullWhere((line) {
      return line.toSource() > import;
    });
    final position = after?.beginToken.offset ?? imports.lastOrNull?.end ?? 0;
    final content = file.readAsStringSync();

    final positionedImport = () {
      if (position == 0) {
        return '$import\n';
      }
      final insertAfterLastImport = after == null;
      final hasPreviousImport = after != null;
      return '${insertAfterLastImport ? '\n' : ''}$import${hasPreviousImport ? '\n' : ''}';
    }();

    final update = content.replaceRange(position, position, positionedImport);
    file.writeAsStringSync(update);
  }
}
