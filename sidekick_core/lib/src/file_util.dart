import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';

extension FileModifier on File {
  /// Replaces the content between [startTag] and [endTag] with [content]
  void replaceSectionWith({
    required String startTag,
    required String endTag,
    required String content,
  }) {
    final original = readAsStringSync();
    final startIndex = original.indexOf(startTag);
    if (startIndex == -1) {
      throw "startTag $startTag not found in ${absolute.path}";
    }
    final start = startIndex + startTag.length;
    final end = original.indexOf(endTag, start);
    if (end == -1) {
      throw "endTag $endTag not found in ${absolute.path}";
    }
    final mutated = original.replaceRange(start, end, content);
    writeAsStringSync(mutated);
  }

  /// Writes [content] before [tag]
  void addBefore({required String tag, required String content}) {
    final original = readAsStringSync();
    final startIndex = original.indexOf(tag);
    if (startIndex == -1) {
      throw "startTag $tag not found in ${absolute.path}";
    }
    final mutated = original.replaceRange(startIndex, startIndex, content);
    writeAsStringSync(mutated);
  }

  void replaceFirst(String text, String replacement) {
    final original = readAsStringSync();
    final startIndex = original.indexOf(text);
    if (startIndex == -1) {
      throw "String '$text' not found in ${absolute.path}";
    }
    final mutated = original.replaceRange(
      startIndex,
      startIndex + text.length,
      replacement,
    );
    writeAsStringSync(mutated);
  }

  void replaceAll(String text, String replacement) {
    String content = readAsStringSync();
    int index = 0;
    // ignore: literal_only_boolean_expressions
    while (true) {
      index = content.indexOf(text, index);
      if (index == -1) {
        // found all
        break;
      }
      content = content.replaceRange(index, index + text.length, replacement);
    }
    writeAsStringSync(content);
  }
}

extension FileSystemEntityExt on FileSystemEntity {
  void verifyExistsOrThrow() {
    if (!existsSync()) {
      error("File $name doesn't exist. Expected at location ${absolute.path}");
    }
  }
}

extension DeleteDirContents on Directory {
  void deleteContentsSync() {
    for (final file in listSync()) {
      file.deleteSync(recursive: true);
    }
  }
}

extension MakeExecutable on FileSystemEntity {
  /// Makes a file executable 'rwxr-xr-x' (755)
  Future<void> makeExecutable() async {
    if (this is Directory) {
      throw "Can't make a Directory executable ($this)";
    }
    if (!existsSync()) {
      throw 'File not found $path';
    }
    if (Platform.isWindows) {
      // The windows file system works differently than unix based ones. exe files are automatically executable
      // But when generating sidekick on windows, it should also be executable on unix systems on checkout.
      // This is done by telling git about the file being executable.
      // https://www.scivision.dev/git-windows-chmod-executable/
      final p =
          startFromArgs('git', ['update-index', '--chmod=+x', '--add', path]);
      if (p.exitCode != 0) {
        throw 'Could not set git file permission for unix systems for file $path';
      }
    } else {
      final p = startFromArgs('chmod', ['755', absolute.path]);
      if (p.exitCode != 0) {
        throw 'Cloud not set permission 755 for file $path';
      }
    }
  }
}
