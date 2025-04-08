import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick/src/util/directory_extension.dart';
import 'package:sidekick_core/sidekick_core.dart';

class CliNameValidator extends dcli.AskValidator {
  const CliNameValidator();

  @override
  String validate(String line, {String? customErrorMessage}) {
    if (!isValidPubPackageName(line)) {
      throw dcli.AskValidatorException(
        dcli.red(customErrorMessage ?? invalidCliNameErrorMessage),
      );
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
class DirectoryExistsValidator extends dcli.AskValidator {
  const DirectoryExistsValidator();

  @override
  String validate(String line, {String? customErrorMessage}) {
    // TODO: this is an unnecessarily verbose version of just Directory(line).
    // However, with Directory(line) I can't get the test 'returns path when directory exists (relative path)'
    // to work because I must be missing some value in IOOverrides
    final dir =
        Directory(Context(current: Directory.current.path).canonicalize(line));
    if (!dir.existsSync()) {
      throw AskValidatorException(
        customErrorMessage ?? 'The directory $line does not exist.',
      );
    }
    return line;
  }
}

/// Validates that a given path is a directory within or equal to [root]
class DirectoryIsWithinOrEqualValidator extends dcli.AskValidator {
  DirectoryIsWithinOrEqualValidator(this.root);

  final Directory root;

  @override
  String validate(String line, {String? customErrorMessage}) {
    final dir = Directory(Context(current: root.path).canonicalize(line));
    if (!dir.isWithinOrEqual(root)) {
      throw AskValidatorException(
        customErrorMessage ??
            'The directory ${dir.path} must be within or equal to ${root.canonicalized.path}.',
      );
    }
    return line;
  }
}
