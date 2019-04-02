/// Configuration for using `package:build`-compatible build systems.
///
/// This library is **not** intended to be imported by typical end-users unless
/// you are creating a custom compilation pipeline.
///
/// See [package:build_runner](https://pub.dartlang.org/packages/build_runner)
/// for more information.
library builder;

import 'dart:async';
import 'package:build/build.dart';
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:source_gen/source_gen.dart';

Builder buildVersion([BuilderOptions options]) => _VersionBuilder(options);

Builder buildVersionPart([BuilderOptions options]) => PartBuilder(
    [_VersionPartGenerator(_fieldName(options))], '.version.g.dart');

String _fieldName(BuilderOptions options) =>
    options != null && options.config.containsKey('field_name')
        ? options.config['field_name'] as String
        : 'packageVersion';

class _VersionBuilder implements Builder {
  _VersionBuilder([BuilderOptions options]) : fieldName = _fieldName(options);

  final String fieldName;

  @override
  Future build(BuildStep buildStep) async {
    await buildStep.writeAsString(
        AssetId(buildStep.inputId.package, 'lib/src/version.dart'),
        await _versionSource(buildStep, fieldName));
  }

  @override
  final buildExtensions = const {
    r'$lib$': ['src/version.dart']
  };
}

class _VersionPartGenerator extends Generator {
  _VersionPartGenerator(this.fieldName);

  final String fieldName;

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async =>
      _versionSource(buildStep, fieldName);
}

Future<String> _versionSource(BuildStep buildStep, String fieldName) async {
  final assetId = AssetId(buildStep.inputId.package, 'pubspec.yaml');
  final content = await buildStep.readAsString(assetId);
  final pubspec = Pubspec.parse(content, sourceUrl: assetId.uri);

  if (pubspec.version == null) {
    throw StateError('pubspec.yaml does not have a version defined.');
  }
  return '''
// Generated code. Do not modify.
const $fieldName = '${pubspec.version}';
''';
}
