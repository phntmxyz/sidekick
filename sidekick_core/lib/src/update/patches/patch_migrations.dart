import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/157_fix_usage_message.patch.dart';
import 'package:sidekick_core/src/update/patches/192_add_format_command.patch.dart';
import 'package:sidekick_core/src/update/patches/208_remove_cli_name.patch.dart';
import 'package:sidekick_core/src/update/patches/253_add_lock_file.patch.dart';
import 'package:sidekick_core/src/update/patches/255_dcli_4.patch.dart';
import 'package:sidekick_core/src/update/patches/272_add_sdk_initializer.patch.dart';

/// Migration steps from git patches
List<MigrationStep> patchMigrations = [
  ...fixUsageMessage157Patches,
  fixUsageMessage208,
  addFormatCommand192,
  forceAddPubspecLock253,
  migrateDcli4_255,
  migrateAddSdkInitializer_272,
];
