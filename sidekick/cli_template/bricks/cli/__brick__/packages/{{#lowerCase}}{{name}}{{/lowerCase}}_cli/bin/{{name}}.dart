import 'package:{{name}}_cli/{{name}}_cli.dart';

Future<void> main(List<String> arguments) async {
  await {{#titleCase}}{{name}}{{/titleCase}}Cli().runWithArgs(arguments);
}
