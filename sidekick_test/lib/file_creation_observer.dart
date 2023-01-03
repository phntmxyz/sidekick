import 'dart:io';

/// Observes all files created and makes them accessible via `createdFiles`.
///
/// Useful when testing file creation/deletion of temp files
///
/// This method tracks the calls to the [File] constructor, not when files are
/// created on disk. Check manually if the file exists.
R observeFileCreations<R>(R Function(List<File> createdFiles) body) {
  return IOOverrides.runZoned(() {
    final original = IOOverrides.current;
    final List<File> files = [];
    return IOOverrides.runZoned(
      () => body(files),
      createFile: (path) {
        final file = original!.createFile(path);
        files.add(file);
        return file;
      },
    );
  });
}
