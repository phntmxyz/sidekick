import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/157_fix_usage_message.patch.dart';

/// Migration steps from git patches
List<MigrationStep> patchMigrations = [
  fixUsageMessagePatch157,
];
