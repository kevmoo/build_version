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
    // Generated code. Do not modify.
    const packageVersion = '1.2.3';
    ```

3. To customize the name of the version constant, a `build.yaml` option can be used.

    ```yaml
    targets:
      $default:
        builders:
          build_version:
            options:
              field_name: 'myVersion' # defaults to 'packageVersion'
    ```
    
4. It is also possible to generate the version string as a part of an existing library 
   in your package. In such a case, the default version builder needs to be disabled and 
   the version part builder should be used.
   
    ```yaml
    targets:
      $default:
        builders:
          build_version:
            enabled: false
          build_version|build_version_part:
            enabled: true
            generate_for: ['lib/src/my_lib.dart']
            options:
              field_name: 'myLibraryVersion' # defaults to 'packageVersion'
    ```

   Assuming that `lib/src/my_lib.dart` contains `part 'my_lib.version.g.dart';`,
   `lib/src/my_lib.version.g.dart` will be generated with content:

    ```dart
    // GENERATED CODE - DO NOT MODIFY BY HAND
    
    part of 'my_lib.dart';
    
    // **************************************************************************
    // _VersionPartGenerator
    // **************************************************************************
    
    // Generated code. Do not modify.
    const packageVersion = '1.2.3';
    ```