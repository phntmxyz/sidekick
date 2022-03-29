# Sidekick Core

This project is the base for all sidekick CLIs

## Usage

```dart
import 'package:sidekick_core/sidekick_core.dart';

Future<void> main(List<String> args) async {
  final runner = initializeSidekick(name: 'flg', mainProjectPath: 'dev/integration_tests/flutter_gallery');
  runner.addCommand(YourCommand());
  return await runner.run(args);
}
```