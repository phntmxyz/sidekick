import 'dart:io';

/// A file structure template that can be written to disk
abstract class TemplateGenerator {
  const TemplateGenerator();

  /// Generates the template and writes it to [TemplateProperties.pluginDirectory]
  void generate(TemplateProperties props);
}

class TemplateProperties {
  /// The name of the to be generated plugin
  final String pluginName;

  /// Where the files should be written to. This is considered as root directory
  final Directory pluginDirectory;

  const TemplateProperties({
    required this.pluginName,
    required this.pluginDirectory,
  });
}
