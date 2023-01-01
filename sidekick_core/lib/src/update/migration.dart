import 'dart:async';

import 'package:dartx/dartx.dart';
import 'package:dcli/dcli.dart';
import 'package:pub_semver/pub_semver.dart';

class MigrationStep {
  /// The version after which this migration should be executed.
  final Version oldVersion;

  /// A human readable name for this migration.
  final String name;

  /// The code to execute for this migration.
  final FutureOr<void> Function(MigrationContext) block;

  const MigrationStep(
    this.block, {
    required this.name,
    required this.oldVersion,
  });
}

/// Information about the full migration while doing a migration.
class MigrationContext {
  final MigrationStep step;
  final Version from;
  final Version to;

  Object? _exception;
  Object? get exception => _exception;

  StackTrace? _stackTrace;
  StackTrace? get stackTrace => _stackTrace;

  MigrationContext({
    required this.step,
    required this.from,
    required this.to,
  });
}

Future<void> migrate({
  required Version from,
  required Version to,
  required List<MigrationStep> migrations,
  FutureOr<MigrationErrorHandling> Function(MigrationContext)? onMigrationError,
}) async {
  final migrationsToExecute = migrations
      .where((m) => m.oldVersion > from && m.oldVersion < to)
      .sortedBy((m) => m.oldVersion)
      .toList();

  for (final migration in migrationsToExecute) {
    final context = MigrationContext(step: migration, from: from, to: to);
    bool retry = true;
    while (retry) {
      retry = false;
      try {
        await migration.block(context);
      } catch (e, s) {
        context._exception = e;
        context._stackTrace = s;
        if (onMigrationError == null) {
          printerr(
              'Migration ${migration.name} (${migration.oldVersion}) failed:');
          printerr(e.toString());
          printerr(s.toString());
        }
        final handling =
            onMigrationError?.call(context) ?? MigrationErrorHandling.skip;
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
