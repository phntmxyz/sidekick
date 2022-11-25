// ignore_for_file: avoid_classes_with_only_static_members

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

/// Global parameters passed from sidekick into the plugin installer
class PluginContext {
  /// The sidekick cli package the plugin is going to be installed into
  static SidekickPackage get sidekickPackage {
    if (_sidekickPackage == null) {
      final home = env['SIDEKICK_PACKAGE_HOME'];
      if (home == null) {
        throw "env.SIDEKICK_PACKAGE_HOME is not set";
      }
      final dir = Directory(home);
      if (!dir.existsSync()) {
        throw "Directory at ${dir.absolute.path} (env.SIDEKICK_PACKAGE_HOME) does not exist";
      }
      _sidekickPackage = SidekickPackage.fromDirectory(Directory(home));
      if (_sidekickPackage == null) {
        throw "Directory at ${dir.absolute.path} (env.SIDEKICK_PACKAGE_HOME) is not a dart package";
      }
    }
    return _sidekickPackage!;
  }

  static SidekickPackage? _sidekickPackage;

  /// This is the plugin package that is getting installed from local source
  ///
  /// Plugin installer might need to know the local location during development,
  /// to link the plugin dependency to a local path, instead of pub.dev where
  /// the plugin is not yet published. (See [pubAddLocalDependency])
  ///
  /// Returns `null` when the plugin is not installed from local source, but
  /// from a remote source (pub or git)
  static DartPackage? get localPlugin {
    if (_localPlugin == null) {
      final path = env['SIDEKICK_LOCAL_PLUGIN_PATH'];
      if (path == null) {
        return null;
      }
      final dir = Directory(path);
      if (!dir.existsSync()) {
        throw "Directory at ${dir.absolute.path} (env.SIDEKICK_LOCAL_PLUGIN_PATH) does not exist";
      }
      _localPlugin = DartPackage.fromDirectory(dir);
      if (_localPlugin == null) {
        throw "Directory at ${dir.absolute.path} (env.SIDEKICK_LOCAL_PLUGIN_PATH) is not a dart package";
      }
    }
    return _localPlugin;
  }

  static DartPackage? _localPlugin;
}
