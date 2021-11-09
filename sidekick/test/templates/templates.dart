import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

Directory setupTemplateProject(String path) {
  final projectRoot = Directory.systemTemp.createTempSync();
  addTearDown(() {
    projectRoot.deleteSync(recursive: true);
  });
  final template = Directory(path);
  for (final entity in template.listSync(recursive: true)) {
    final relativeToRoot = relative(entity.path, from: template.path);
    final copyTo = "${projectRoot.path}/$relativeToRoot";
    if (entity is File) {
      entity.parent.createSync(recursive: true);
      entity.copySync(copyTo);
    }
    if (entity is Directory) {
      Directory(copyTo).createSync(recursive: true);
    }
  }

  return projectRoot;
}
