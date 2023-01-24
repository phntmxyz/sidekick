# sidekick_core

This package is used by [sidekick](https://github.com/phntmxyz/sidekick) CLIs to gain access to those awesome features:

- Plugin engine
- Update migrations
- Templates for new projects and plugins
- Prebuild commands
  - `AnalyzeCommand` - Dart analyzes the whole project
  - `DartCommand` - Calls the Dart SDK embedded in Flutter SDK (default system)
  - `DepsCommand` - Gets dependencies for all packages
  - `FlutterCommand` - Call the Flutter SDK associated with the project (default system)
  - `BashCommand` - Wraps a bash script and converts it to a Dart command
  - `SidekickCommand` 
    - `PluginsCommand` - To install and create plugins
    - `UpdateCommand` - To update your CLI to the latest sidekick_core version
    - `InstallGlobalCommand` - Makes the CLI available globally
    - `RecompileCommand` - Recompiles the CLI in case it didn't detect changes automatically (path dependencies)


## Usage

```dart
import 'package:sidekick_core/sidekick_core.dart';

Future<void> main(List<String> args) async {
  final runner = initializeSidekick(mainProjectPath: 'dev/integration_tests/flutter_gallery');
  runner.addCommand(YourCommand());
  runner.addCommand(SidekickCommand());
  return await runner.run(args);
}
```

## License

```text
Copyright 2023 phntm GmbH

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
