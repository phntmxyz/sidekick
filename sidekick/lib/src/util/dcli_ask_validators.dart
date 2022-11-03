import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick/src/util/directory_extension.dart';
import 'package:sidekick_core/sidekick_core.dart';

class CliNameValidator extends dcli.AskValidator {
  const CliNameValidator();

  @override
  String validate(String line) {
    if (!isValidPubPackageName(line)) {
      throw dcli.AskValidatorException(dcli.red(invalidCliNameErrorMessage));
    }

    return line;
  }
}

const invalidCliNameErrorMessage = 'The CLI name must be valid: '
    'at least one lower case letter or underscore '
    'followed by zero or more lower case letters, digits, or underscores. '
    "Furthermore, make sure that it isn't a reserved word. "
    'For details, see https://dart.dev/tools/pub/pubspec#name';

/// Validates that a given path exists as [Directory].
///
/// Relative paths are resolved from [relativeFrom] or [Directory.current].
class DirectoryExistsValidator extends dcli.AskValidator {
  const DirectoryExistsValidator([this.relativeFrom]);

  final Directory? relativeFrom;

  @override
  String validate(String line) {
    final currentDirectory = relativeFrom ?? Directory.current;
    final dir = currentDirectory.cd(line);
    if (!dir.existsSync()) {
      throw AskValidatorException(
          'The directory $line does not exist (neither as absolute path, nor '
          'as path relative from ${currentDirectory.canonicalized.path}.');
    }
    return line;
  }
}

/// Validates that a given path is a directory within or equal to [root]
class DirectoryIsWithinOrEqualValidator extends dcli.AskValidator {
  DirectoryIsWithinOrEqualValidator(this.root);

  final Directory root;

  @override
  String validate(String line) {
    final dir = root.cd(line);
    if (!dir.isWithinOrEqual(root)) {
      throw AskValidatorException(
        'The directory ${dir.path} must be within or equal to ${root.canonicalized.path}.',
      );
    }
    return line;
  }
}
