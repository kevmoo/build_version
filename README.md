[![Pub](https://img.shields.io/pub/v/build_version.svg)](https://pub.dev/packages/build_version)

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
    > dart pub run build_runner build
    ```

    `lib/src/version.dart` will be generated with content:

    ```dart
    // Generated code. Do not modify.
    const packageVersion = '1.2.3';
    ```

To change the path of the generated file, create a [`build.yaml`](build config)
in the root of your package.
By changing the `output` option of this builder, the path can be customized:

```yaml
targets:
  $default:
    builders:
      build_version:
        options:
          output: lib/src/custom/path/to/version.dart
```

[build config]: https://pub.dev/packages/build_config
