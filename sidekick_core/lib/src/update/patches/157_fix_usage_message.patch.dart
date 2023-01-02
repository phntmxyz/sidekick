const patch = r'''
From ced7e637e677abcf3dd6d15d68500659a4669dd7 Mon Sep 17 00:00:00 2001
From: Giuseppe Cianci <giuseppe.cianci97@gmail.com>
Date: Thu, 22 Dec 2022 16:46:34 +0100
Subject: [PATCH] print all information on UsageException

---
 .../lib/src/template/sidekick_package.template.dart        | 7 +------
 1 file changed, 1 insertion(+), 6 deletions(-)

diff --git a/sidekick_core/lib/src/template/sidekick_package.template.dart b/sidekick_core/lib/src/template/sidekick_package.template.dart
index 667ccd5..03ecb8c 100644
--- a/sidekick_core/lib/src/template/sidekick_package.template.dart
+++ b/sidekick_core/lib/src/template/sidekick_package.template.dart
@@ -212,15 +212,10 @@ Future<void> run${name.pascalCase}(List<String> args) async {
   runner
 ${commands.map((cmd) => '    ..addCommand($cmd)').join('\n')};
 
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
2.36.1
''';