const patch = '''
From ced7e637e677abcf3dd6d15d68500659a4669dd7 Mon Sep 17 00:00:00 2001
From: Giuseppe Cianci <giuseppe.cianci97@gmail.com>
Date: Thu, 22 Dec 2022 16:46:34 +0100
Subject: [PATCH] print all information on UsageException

--- a/sk_sidekick/lib/sk_sidekick.dart
+++ b/sk_sidekick/lib/sk_sidekick.dart
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
