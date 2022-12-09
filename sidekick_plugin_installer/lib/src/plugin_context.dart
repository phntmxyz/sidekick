// ignore_for_file: avoid_classes_with_only_static_members

import 'package:sidekick_core/sidekick_core.dart';

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
  static String? get name => env['SIDEKICK_PLUGIN_NAME'];

  /// Version constraint of the plugin package to be installed
  ///
  /// {@template installer_parameter}
  /// This is a parameter for installing a plugin package in a sidekick CLI
  ///
  /// The plugin installer needs to know the location of the plugin package
  /// which can either be a local path, a remote pub server, or a remote git
  /// repository. See [addSelfAsDependency]
  ///
  /// Returns `null` when the plugin is installed from another source
  /// {@endtemplate}
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

  /// The plugin which is currently being installed
  ///
  /// During installation, the plugin is copied to a build directory. This
  /// method returns the plugin from that location.
  ///
  /// This only works during execution a plugin's tool/install.dart,
  /// otherwise it throws
  static DartPackage get installerPlugin {
    final toolInstallScript = Platform.script;
    final pathEnd = toolInstallScript.pathSegments.takeLast(2).join('/');
    if (pathEnd != 'tool/install.dart') {
      throw 'PluginContext.buildPlugin can only be accessed inside of a '
          "plugin's tool/install.dart";
    }

    final pluginDir = File(Platform.script.path).parent.parent;
    final pluginPackage = DartPackage.fromDirectory(pluginDir);

    if (pluginPackage == null) {
      throw "Plugin at '${pluginDir.absolute.path}' is not a dart package.";
    }

    return pluginPackage;
  }
}
