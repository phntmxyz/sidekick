import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final fixUsageMessage157Patches = [
  _gitPatch1,
  _gitPatch2,
];

final _gitPatch1 = MigrationStep.gitPatch(
  _patch1,
  description: 'Fix usage message (1/2)',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/157',
  targetVersion: Version(0, 13, 2),
);

String _patch1() {
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
@@ -2,5 +2,1 @@
-  if (args.isEmpty) {
-    print(runner.usage);
-    return;
-  }

''';
}

final _gitPatch2 = MigrationStep.gitPatch(
  _patch2,
  description: 'Fix usage message (2/2)',
  pullRequestLink: 'https://github.com/phntmxyz/sidekick/pull/157',
  targetVersion: Version(0, 13, 2),
);

String _patch2() {
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
@@ -2,5 +2,5 @@
   } on UsageException catch (e) {
-    print(e.usage);
+    print(e);
     exit(64); // usage error
   }
 }
''';
}
