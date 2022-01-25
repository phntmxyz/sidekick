import 'package:{{name}}_sidekick/{{name}}_sidekick.dart';

Future<void> main(List<String> arguments) async {
  await {{#titleCase}}{{name}}{{/titleCase}}Sidekick().runWithArgs(arguments);
}
