import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:build_version/build_version.dart';
import 'package:test/test.dart';

void main() {
  test('no name provided', () async {
    final logs = <String>[];
    final result = await testBuilder(
      buildVersion(),
      _createPackageStub({'version': '1.0.0'}),
      onLog: (log) => logs.add(log.message),
    );

    expect(result.buildResult.failureType, isNotNull);
    expect(
      logs,
      contains(
        allOf(contains('ParsedYamlException'), contains('Missing key "name')),
      ),
    );
  });
  test('no version provided', () async {
    final logs = <String>[];
    final result = await testBuilder(
      buildVersion(),
      _createPackageStub({'name': 'pkg'}),
      onLog: (log) => logs.add(log.message),
    );

    expect(result.buildResult.failureType, isNotNull);
    expect(
      logs,
      contains(
        allOf(contains('pubspec.yaml does not have a version defined.')),
      ),
    );
  });
  test('bad version provided', () async {
    final logs = <String>[];
    final result = await testBuilder(
      buildVersion(),
      _createPackageStub({'name': 'pkg', 'version': 'not a version'}),
      onLog: (log) => logs.add(log.message),
    );

    expect(result.buildResult.failureType, isNotNull);
    expect(
      logs,
      contains(
        allOf(contains('Unsupported value for "version". Could not parse')),
      ),
    );
  });
  test('valid input', () async {
    await testBuilder(
      buildVersion(),
      _createPackageStub({'name': 'pkg', 'version': '1.0.0'}),
      outputs: {
        'pkg|lib/src/version.dart': r'''
// Generated code. Do not modify.
const packageVersion = '1.0.0';
''',
      },
    );
  });

  test('valid input, custom output location', () async {
    await testBuilder(
      buildVersion(const BuilderOptions({'output': 'bin/version.dart'})),
      _createPackageStub({'name': 'pkg', 'version': '1.0.0'}),
      outputs: {
        'pkg|bin/version.dart': r'''
// Generated code. Do not modify.
const packageVersion = '1.0.0';
''',
      },
    );
  });
}

Map<String, String> _createPackageStub(Map<String, dynamic> pubspecContent) => {
  'pkg|pubspec.yaml': jsonEncode(pubspecContent),
};
