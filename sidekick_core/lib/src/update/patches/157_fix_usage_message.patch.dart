import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

MigrationStep getPatch157() => MigrationStep.gitPatch(
      _getPatch(),
      name: 'Fix usage message',
      targetVersion: Version(0, 13, 2),
    );

String _getPatch() {
  final cliMainFilePath = relative(
    Repository.requiredSidekickPackage.cliMainFile.absolute.path,
    from: findRepository().root.path,
  );
  return '''
From ced7e637e677abcf3dd6d15d68500659a4669dd7 Mon Sep 17 00:00:00 2001
From: Giuseppe Cianci <giuseppe.cianci97@gmail.com>
Date: Thu, 22 Dec 2022 16:46:34 +0100
Subject: [PATCH] print all information on UsageException

--- a/$cliMainFilePath
+++ b/$cliMainFilePath
@@ -2,12 +2,7 @@
-  if (args.isEmpty) {
-    print(runner.usage);
-    return;
-  }
-
   try {
     return await runner.run(args);
   } on UsageException catch (e) {
-    print(e.usage);
+    print(e);
     exit(64); // usage error
   }
 }
--
''';
}
