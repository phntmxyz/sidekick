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

  /// Name of the plugin package to be installed
  ///
  /// {@macro installer_parameter}
  static String get name => env['SIDEKICK_PLUGIN_NAME']!;

  /// Version constraint of the plugin package to be installed
  ///
  /// {@macro installer_parameter}
  static String? get versionConstraint =>
      env['SIDEKICK_PLUGIN_VERSION_CONSTRAINT'];

  /// Path to plugin package which is getting installed from local source
  ///
  /// {@macro installer_parameter}
  static String? get localPath => env['SIDEKICK_PLUGIN_LOCAL_PATH'];

  /// {@macro installer_parameter}
  ///
  /// When null, the default server (pub.dev) is used
  ///
  /// URL of the pub server to install the plugin package from
  static String? get hostedUrl => env['SIDEKICK_PLUGIN_HOSTED_URL'];

  /// Git URL of the plugin package
  ///
  /// {@macro installer_parameter}
  static String? get gitUrl => env['SIDEKICK_PLUGIN_GIT_URL'];

  /// Git branch or commit to be retrieved
  ///
  /// {@macro installer_parameter}
  static String? get gitRef => env['SIDEKICK_PLUGIN_GIT_REF'];

  /// Path of git package in repository
  ///
  /// {@macro installer_parameter}
  static String? get gitPath => env['SIDEKICK_PLUGIN_GIT_PATH'];
}

/// {@template installer_parameter}
/// This is a parameter for installing a plugin package in a sidekick CLI
///
/// The plugin installer needs to know the location of the plugin package
/// which can either be a local path, a remote pub server, or a remote git
/// repository. See [addDependency]
///
/// Returns `null` when the plugin is installed from another source
/// {@endtemplate}
