# Sidekick Plugin Installer

Contains high level helper methods around `analyzer` useful for plugin authors.
The methods can be used in the `tool/install.dart` script to actually integrate your plugin code in to the sidekick CLI.

## Example 

```dart
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  await addSelfAsDependency();
  await pubGet(package);

  await registerPlugin(
    sidekickCli: package,
    import: "import 'package:my_sidekick_plugin/my_sidekick_plugin.dart';",
    command: 'MyCommand()',
  );
}
```

## License

```text
Copyright 2022 phntm GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
