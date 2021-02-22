
import 'dart:convert';
import 'dart:io';

void main() {
  final localConfigFile = File("tool/local.json");
  Map<String, dynamic> configMap;
  if (localConfigFile.existsSync()) {
    configMap = json.decode(localConfigFile.readAsStringSync());
  } else {
    configMap = {
      "cognitoUserPoolId": Platform.environment["COGNITO_USER_POOL_ID"],
      "cognitoAppClientId": Platform.environment["COGNITO_APP_CLIENT_ID"],
      "cognitoAppSecret": Platform.environment["COGNITO_APP_SECRET"],
      "cognitoRegion": Platform.environment["COGNITO_REGION"],
    };
  }

  Directory("lib/generated").createSync(recursive: true);

  final encoder = JsonEncoder.withIndent('  ');

  final access = File("lib/generated/env.dart").openSync(mode: FileMode.write);

  access.writeStringSync("// GENERATED CODE - DO NOT MODIFY BY HAND\n\n");

  final map = encoder.convert(configMap).split("\n").map((e) => "  $e").join("\n").trim();

  access.writeStringSync("const environment = Env();\n\n");

  access.writeStringSync("class Env {\n"
      + "  final _env = const $map;\n\n");

  access.writeStringSync("  const Env();\n\n");

  configMap.forEach((key, value) {
    access.writeStringSync("  String get${capitalizeFirstLetter(key)}() => _env['$key'];\n\n");
  });

  access.writeStringSync("}\n");

  access.flushSync();
  access.closeSync();
}

String capitalizeFirstLetter(String s) {
  if (s == null) return null;
  if (s.trim().isEmpty) return null;
  return s.substring(0, 1).toUpperCase() + s.substring(1);
}