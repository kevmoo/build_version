![Pub](https://img.shields.io/pub/v/build_version.svg)
[![Build Status](https://travis-ci.org/kevmoo/build_version.svg?branch=master)](https://travis-ci.org/kevmoo/build_version)

Include the version of your package in our source code.

1. Add `build_version` to `pubspec.yaml`. Also make sure there is a `version`
   field.

    ```yaml
    name: my_pkg
    version: 1.2.3
    dev_dependencies:
      build_runner: ^1.0.0
      build_version: ^2.0.0
    ```

2. Run a build.

    ```console
    > pub run build_runner build
    ```

    `lib/src/version.dart` will be generated with content:

    ```dart
    /// Generated code. Do not modify.
    const String packageVersion = '1.2.3';
    ```
