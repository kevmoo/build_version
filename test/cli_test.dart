// Copyright (c) 2018, build_version authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:build_version/src/cli.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('build_version_cli_test_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
  });

  test('writes lib/src/version.dart by default', () {
    _writePubspec(tempDir, name: 'my_pkg', version: '1.2.3');

    final result = _runCli([], tempDir);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Wrote lib/src/version.dart.'));
    expect(result.stderr, isEmpty);

    final versionFile = File.fromUri(
      tempDir.uri.resolve('lib/src/version.dart'),
    );
    expect(versionFile.existsSync(), isTrue);
    expect(
      versionFile.readAsStringSync(),
      '// Generated code. Do not modify.\n'
      "const packageVersion = '1.2.3';\n",
    );
  });

  test('writes to custom --output path', () {
    _writePubspec(tempDir, name: 'my_pkg', version: '2.0.0');

    final result = _runCli(['--output', 'bin/version.dart'], tempDir);

    expect(result.exitCode, 0);
    expect(result.stdout, contains('Wrote bin/version.dart.'));
    expect(result.stderr, isEmpty);

    final versionFile = File.fromUri(tempDir.uri.resolve('bin/version.dart'));
    expect(versionFile.existsSync(), isTrue);
    expect(
      versionFile.readAsStringSync(),
      '// Generated code. Do not modify.\n'
      "const packageVersion = '2.0.0';\n",
    );
  });

  group('--check', () {
    test('succeeds when output file matches pubspec.yaml', () {
      _writePubspec(tempDir, name: 'my_pkg', version: '1.2.3');
      _runCli([], tempDir);

      final result = _runCli(['--check'], tempDir);

      expect(result.exitCode, 0);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isEmpty);
    });

    test('succeeds with CRLF line endings in output file', () {
      _writePubspec(tempDir, name: 'my_pkg', version: '1.2.3');
      File.fromUri(tempDir.uri.resolve('lib/src/version.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '// Generated code. Do not modify.\r\n'
          "const packageVersion = '1.2.3';\r\n",
        );

      final result = _runCli(['-c'], tempDir);

      expect(result.exitCode, 0);
      expect(result.stderr, isEmpty);
    });

    test('fails when output file is missing', () {
      _writePubspec(tempDir, name: 'my_pkg', version: '1.2.3');

      final result = _runCli(['--check'], tempDir);

      expect(result.exitCode, 1);
      expect(result.stdout, isEmpty);
      expect(
        result.stderr,
        allOf(
          contains('lib/src/version.dart does not exist.'),
          contains('Run "dart run build_version" to generate it.'),
        ),
      );
      expect(
        File.fromUri(tempDir.uri.resolve('lib/src/version.dart')).existsSync(),
        isFalse,
      );
    });

    test('fails when output file has stale version', () {
      _writePubspec(tempDir, name: 'my_pkg', version: '1.0.0');
      _runCli([], tempDir);
      _writePubspec(tempDir, name: 'my_pkg', version: '2.0.0');

      final result = _runCli(['--check'], tempDir);

      expect(result.exitCode, 1);
      expect(
        result.stderr,
        allOf(
          contains('lib/src/version.dart is out of date with pubspec.yaml.'),
          contains('Run "dart run build_version" to update it.'),
        ),
      );
    });

    test('includes --output in remediation when custom path is used', () {
      _writePubspec(tempDir, name: 'my_pkg', version: '1.2.3');

      final result = _runCli(['-c', '-o', 'lib/custom_version.dart'], tempDir);

      expect(result.exitCode, 1);
      expect(
        result.stderr,
        allOf(
          contains('lib/custom_version.dart does not exist.'),
          contains(
            'Run "dart run build_version --output lib/custom_version.dart" '
            'to generate it.',
          ),
        ),
      );
    });
  });

  group('error handling', () {
    test('fails when pubspec.yaml is missing', () {
      final result = _runCli([], tempDir);

      expect(result.exitCode, 1);
      expect(result.stderr, contains('Could not find pubspec.yaml'));
    });

    test('fails when pubspec.yaml has no version field', () {
      File.fromUri(
        tempDir.uri.resolve('pubspec.yaml'),
      ).writeAsStringSync('name: my_pkg\n');

      final result = _runCli([], tempDir);

      expect(result.exitCode, 1);
      expect(
        result.stderr,
        contains('pubspec.yaml does not have a version defined.'),
      );
    });

    test('fails when pubspec.yaml has invalid version', () {
      File.fromUri(tempDir.uri.resolve('pubspec.yaml')).writeAsStringSync(
        'name: my_pkg\n'
        'version: not a version\n',
      );

      final result = _runCli([], tempDir);

      expect(result.exitCode, 1);
      expect(
        result.stderr,
        contains('Unsupported value for "version". Could not parse'),
      );
    });

    test('fails when pubspec.yaml is missing name field', () {
      File.fromUri(
        tempDir.uri.resolve('pubspec.yaml'),
      ).writeAsStringSync('version: 1.0.0\n');

      final result = _runCli([], tempDir);

      expect(result.exitCode, 1);
      expect(result.stderr, contains('Missing key "name"'));
    });

    test('rejects unknown flags and non-existent aliases', () {
      for (final flag in ['--unknown', '--write', '--verify']) {
        final result = _runCli([flag], tempDir);
        expect(result.exitCode, 64, reason: 'Expected exit 64 for $flag');
        expect(result.stderr, contains('Usage: build_version [options]'));
      }
    });

    test('rejects unexpected positional arguments', () {
      final result = _runCli(['extra_arg'], tempDir);

      expect(result.exitCode, 64);
      expect(
        result.stderr,
        allOf(
          contains('Unexpected positional arguments: extra_arg'),
          contains('Usage: build_version [options]'),
        ),
      );
    });

    test('rejects empty --output option', () {
      final result = _runCli(['--output', '  '], tempDir);

      expect(result.exitCode, 64);
      expect(result.stderr, contains('The --output option cannot be empty.'));
    });
  });

  group('--help', () {
    test('prints usage to stdout and exits 0', () {
      for (final flag in ['--help', '-h']) {
        final result = _runCli([flag], tempDir);
        expect(result.exitCode, 0, reason: 'Expected exit 0 for $flag');
        expect(
          result.stdout,
          allOf(
            contains('Usage: build_version [options]'),
            contains('-c, --check'),
            contains('-o, --output'),
            contains('-h, --help'),
          ),
        );
        expect(result.stderr, isEmpty);
      }
    });
  });

  test('bin/build_version.dart entrypoint sets exitCode properly', () async {
    _writePubspec(tempDir, name: 'my_pkg', version: '3.4.5');
    final binPath = File('bin/build_version.dart').absolute.path;

    final writeResult = await Process.run(Platform.resolvedExecutable, [
      binPath,
    ], workingDirectory: tempDir.path);
    expect(writeResult.exitCode, 0, reason: '${writeResult.stderr}');

    final checkResult = await Process.run(Platform.resolvedExecutable, [
      binPath,
      '--check',
    ], workingDirectory: tempDir.path);
    expect(checkResult.exitCode, 0, reason: '${checkResult.stderr}');

    _writePubspec(tempDir, name: 'my_pkg', version: '3.4.6');
    final staleResult = await Process.run(Platform.resolvedExecutable, [
      binPath,
      '--check',
    ], workingDirectory: tempDir.path);
    expect(staleResult.exitCode, 1);
    expect(staleResult.stderr as String, contains('is out of date'));
  });
}

void _writePubspec(
  Directory dir, {
  required String name,
  required String version,
}) {
  File.fromUri(dir.uri.resolve('pubspec.yaml')).writeAsStringSync(
    'name: $name\n'
    'version: $version\n',
  );
}

({int exitCode, String stdout, String stderr}) _runCli(
  List<String> args,
  Directory workingDirectory,
) {
  final out = StringBuffer();
  final err = StringBuffer();
  final code = runBuildVersion(
    args,
    workingDirectory: workingDirectory.path,
    out: out,
    err: err,
  );
  return (exitCode: code, stdout: out.toString(), stderr: err.toString());
}
