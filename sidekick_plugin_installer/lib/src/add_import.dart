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
    // find position to insert import alphabetically
    final after = imports
        .firstOrNullWhere((line) => line.toSource().compareTo(import) > 0);
    final position = after?.end ?? imports.lastOrNull?.end ?? 0;
    final content = file.readAsStringSync();
    if (content.contains(import)) {
      return;
    }
    final update = content.replaceRange(position, position, '\n$import');
    file.writeAsStringSync(update);
  }
}
