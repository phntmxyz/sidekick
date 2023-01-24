import 'dart:async';

import 'package:dcli/dcli.dart';
import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// A single migration that can be executed with [migrate]
///
/// This step is executed when a user updates to a version that is greater
/// or equal to [targetVersion].
abstract class MigrationStep {
  /// The version this migration step will migrate to.
  final Version targetVersion;

  /// A human readable name for this migration.
  final String name;

  /// Don't call this constructor directly, instead extend [MigrationStep] or
  /// use [MigrationStep.inline].
  const MigrationStep({
    required this.name,
    required this.targetVersion,
  });

  /// For simple steps a single function is enough
  const factory MigrationStep.inline(
    FutureOr<void> Function(MigrationContext) block, {
    required String name,
    required Version targetVersion,
    String pullRequestLink,
  }) = _InlineMigrationStep;

  factory MigrationStep.gitPatch(
    String Function() patch, {
    required String description,
    String pullRequestLink,
    required Version targetVersion,
    required Directory Function() workingDirectory,
  }) = GitPatchMigrationStep;

  /// This method is called to do the action migration of this step.
  Future<void> migrate(MigrationContext context);

  @override
  String toString() {
    return 'MigrationStep{$name to $targetVersion}';
  }
}

/// A version of MigrationStep that doesn't require extending the class
class _InlineMigrationStep extends MigrationStep {
  const _InlineMigrationStep(
    this.block, {
    required String name,
    required Version targetVersion,
    this.pullRequestLink,
  }) : super(name: name, targetVersion: targetVersion);

  /// Link to the pull request on GitHub introducing this patch
  final String? pullRequestLink;

  /// The code to execute for this migration step
  final FutureOr<void> Function(MigrationContext) block;

  @override
  Future<void> migrate(MigrationContext context) async {
    try {
      await block(context);
    } catch (e, s) {
      throw "Couldn't apply migration step '$name'.\n"
          '${pullRequestLink != null ? 'Check $pullRequestLink for further information.\n' : ''}'
          'Error: $e\n$s';
    }
  }
}

class GitPatchMigrationStep extends MigrationStep {
  GitPatchMigrationStep(
    this.patch, {
    required this.description,
    this.pullRequestLink,
    required Version targetVersion,
    required this.workingDirectory,
  }) : super(
          name:
              '$description${pullRequestLink != null ? ' ($pullRequestLink)' : ''}',
          targetVersion: targetVersion,
        );

  /// A function that returns the git patch to be applied for this migration step
  final String Function() patch;

  /// Description of the patch
  final String description;

  /// Link to the pull request on GitHub introducing this patch
  final String? pullRequestLink;

  final Directory Function() workingDirectory;

  @override
  Future<void> migrate(MigrationContext context) async {
    final patchFile = Directory.systemTemp
        .createTempSync()
        .file('${description.snakeCase}.sidekick.patch');
    final text = patch();
    patchFile.writeAsStringSync(text);

    final exitCode = startFromArgs(
          'git',
          ['apply', patchFile.absolute.path],
          workingDirectory: workingDirectory().absolute.path,
          // A more detailed error will be thrown on exitCode != 0
          nothrow: true,
        ).exitCode ??
        -1;
    if (exitCode != 0) {
      throw '${red("Couldn't apply git patch ${patchFile.absolute.path} for migration step $description.")}\n'
          '${pullRequestLink != null ? 'Check $pullRequestLink for further information.\n' : ''}'
          '${red('Try applying the patch manually if necessary.')}\n'
          'The patch content is:\n\n$text\n';
    }
    // delete file only if patch was applied successfully
    patchFile.deleteSync();
  }
}

/// Information about the full migration while doing a migration.
class MigrationContext {
  /// The current step of the migration.
  final MigrationStep step;

  /// The initial version where the migration has been started
  final Version from;

  /// The version the migration is migrating to
  final Version to;

  Object? _exception;

  /// In case of an error during this step, this will contain the exception
  Object? get exception => _exception;

  /// In case of an error during this step, this will contain the stacktrace
  StackTrace? _stackTrace;

  StackTrace? get stackTrace => _stackTrace;

  MigrationContext({
    required this.step,
    required this.from,
    required this.to,
  });
}

/// Starts a migration from [from] to [to] using the given [migrations].
///
/// Migrations are only executed if [MigrationStep.targetVersion] is greater
/// than [from] and less than or equal to [to].
///
/// Use the [onMigrationStepStart] and [onMigrationStepEnd] callbacks to execute
/// code before and after each step.
///
/// React to errors of each step with [onMigrationStepError], and decide whether
/// to skip or retry individual steps or abort the whole migration.
Future<void> migrate({
  required Version from,
  required Version to,
  required List<MigrationStep> migrations,
  FutureOr<void> Function(MigrationContext)? onMigrationStepStart,
  FutureOr<void> Function(MigrationContext)? onMigrationStepEnd,
  FutureOr<MigrationErrorHandling> Function(MigrationContext)?
      onMigrationStepError,
}) async {
  final migrationsToExecute = migrations
      .where((m) => m.targetVersion > from && m.targetVersion <= to)
      .sortedBy((m) => m.targetVersion)
      .toList();

  for (final step in migrationsToExecute) {
    final context = MigrationContext(step: step, from: from, to: to);
    await onMigrationStepStart?.call(context);
    bool retry = true;
    while (retry) {
      retry = false;
      try {
        await step.migrate(context);
      } catch (e, s) {
        context._exception = e;
        context._stackTrace = s;
        if (onMigrationStepError == null) {
          printerr("Migration '${step.name}' (${step.targetVersion}) failed:");
          printerr(e.toString());
          printerr(s.toString());
        }
        final handling =
            onMigrationStepError?.call(context) ?? MigrationErrorHandling.skip;
        switch (handling) {
          case MigrationErrorHandling.skip:
            continue;
          case MigrationErrorHandling.abort:
            rethrow;
          case MigrationErrorHandling.retry:
            retry = true;
        }
      }
    }

    await onMigrationStepEnd?.call(context);
  }
}

enum MigrationErrorHandling {
  /// The migration will be skipped and the next migration will be executed.
  skip,

  /// The migration will be retried.
  retry,

  /// The migration will be aborted and no further migrations will be executed.
  abort,
}
