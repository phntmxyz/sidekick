import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/src/add_import.dart';

/// Registers the command to the [SidekickCommandRunner]
Future<void> registerPlugin({
  required DartPackage sidekickCli,
  required String command,
  String? import,
}) async {
  // find file where the runner is created. Usually in lib/<cliName>_sidekick.dart
  final cliName = sidekickCli.name;
  final commandRegisteringFile = sidekickCli.libDir.file('$cliName.dart');

  if (import != null) {
    await addImport(commandRegisteringFile, import);
  }
  await _addCommand(commandRegisteringFile, command);
}

/// Adds the command to the [SidekickCommandRunner]
///
/// Assuming the default syntax with the cascade operator is used.
Future<void> _addCommand(File file, String command) async {
  final collection = AnalysisContextCollection(includedPaths: [file.path]);

  final context = collection.contextFor(file.path);
  final parsed = context.currentSession.getParsedUnit(file.path);

  if (parsed is ParsedUnitResult) {
    final visitor = _AddCommandVisitor(file, command);
    visitor.visitAllNodes(parsed.unit);
  }
}

class _AddCommandVisitor extends BreadthFirstVisitor<void> {
  final File file;
  final String commandText;
  _AddCommandVisitor(this.file, this.commandText);

  @override
  void visitCascadeExpression(CascadeExpression node) {
    final block = node.parent?.parent;
    if (block is Block) {
      final blockSrc = block.toSource();
      // check we are in the correct method
      if (blockSrc.contains('initializeSidekick')) {
        final lastCommand = node.cascadeSections.lastOrNullWhere(
          (it) => it is MethodInvocation && it.methodName.name == 'addCommand',
        );
        final compilationUnit = node.root as CompilationUnit;
        // check if this is the correct cascade
        if (lastCommand != null) {
          final injectionPosition = lastCommand.endToken.end;

          final beginToken = lastCommand.beginToken.offset;
          final lineInfo = compilationUnit.lineInfo;
          final line = lineInfo.getLocation(beginToken).lineNumber;
          final lineStart = lineInfo.getOffsetOfLine(line - 1);
          final indent = beginToken - lineStart;
          final contents = file.readAsStringSync();
          final update = contents.replaceRange(
            injectionPosition,
            injectionPosition,
            '\n${' ' * indent}..addCommand($commandText)',
          );
          file.writeAsStringSync(update);
        }
      }
    }
    super.visitCascadeExpression(node);
  }
}
