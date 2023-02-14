import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/157_fix_usage_message.patch.dart';
import 'package:sidekick_core/src/update/patches/192_add_format_command.patch.dart';
import 'package:sidekick_core/src/update/patches/208_remove_cli_name.patch.dart';

/// Migration steps from git patches
List<MigrationStep> patchMigrations = [
  ...fixUsageMessage157Patches,
  fixUsageMessage208,
  addFormatCommand192,
];
