# Sidekick

The sidekick to your Flutter app - a CLI that allows you to extend you project with custom tasks

# Project state

Woah! You found this amazing project without us ever publicly talking about it.

Stay tuned for our public announcement while we're working hard on getting this baby ready for prime time 👨‍💻

## Install sidekick

```bash
dart pub global activate sidekick
```

## Initialize project

```bash
sidekick init <path-to-repo> 
```

## Plugins

## Supported projects structures

## Writing custom tasks

## Creating sub commands

```dart
import 'package:sidekick_core/sidekick_core.dart';

class YourCommand extends Command {
  @override
  String get description => 'does foo';

  @override
  String get name => 'foo';
  
  @override
  Future<void> run() {
    // your custom code here
  }
}
```

## Add commands to your project

```dart
// Generated by `sidekick init`
Future<void> runFlg(List<String> args) async {
  final runner = initializeSidekick(name: 'flg', mainProjectPath: '.');

  flgProject = FlgProject(mainProject.root);

  runner
    ..addCommand(FlutterCommand())
    // more commands
    ..addCommand(InstallGlobalCommand())
+   ..addCommand(YourCommand()); // <-- Register your own command

  //...
```

## Development

### Install cli locally during development

That's useful when you want to test the sidekick cli during development on your machine. Tests are great, but sometimes you want to see the beast in action.

```bash
cd sidekick
dart pub global activate -s path .
```

## License

```text
Copyright 2021 phntm GmbH

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
