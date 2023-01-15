import 'package:sidekick_core/sidekick_core.dart';

class TestSidekickContextCommand extends Command {
  @override
  String get name => 'test-sidekick-context';

  @override
  String get description => 'Tests the sidekick context';

  @override
  Future<void> run() async {
    // print('repository: ${SidekickContext.repository}');
    print(
      'sidekickPackage: ${relative(SidekickContext.sidekickPackage.root.path)}',
    );
    print('entryPoint: ${relative(SidekickContext.entryPoint.file.path)}');
  }
}
