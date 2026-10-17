// Copyright (c) 2018, build_version authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pubspec_parse/pubspec_parse.dart';

const defaultOutput = 'lib/src/version.dart';

const missingVersionMessage = 'pubspec.yaml does not have a version defined.';

String caretVersionConstraint(String version) =>
    '^${version.split(RegExp(r'[-+]')).first}';

String? generateVersionContent(
  String pubspecContent, {
  Uri? sourceUrl,
  String header = '// Generated code. Do not modify.',
}) {
  final pubspec = Pubspec.parse(pubspecContent, sourceUrl: sourceUrl);
  final version = pubspec.version;
  if (version == null) {
    return null;
  }

  return '$header\n'
      "const packageVersion = '$version';\n";
}
