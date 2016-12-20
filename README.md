# `resolver`

**WARNING:** _This is not an official Google or Dart project_

A very simple frontend for resolving Dart code using `package:analyzer`.
As the API for using these mostly Dart-internal packages improves, this
package will become obsolete.

Until then, it exists to help new and experienced Dart developers alike
get started with tooling they want to write that requires a _resolved_
AST (i.e. with types, imports, metadata available).

> This package is _not_ meant to be used to do source/code generation -
> you should look at [package:source_gen][pkg_source_gen] or the
> lower-level [package:build][pkg_build], which already has a very
> simplified model for resolving code.

[pkg_source_gen]: https://pub.dartlang.org/packages/source_gen
[pkg_build]: https://pub.dartlang.org/packages/build

## Getting Started

This package is meant to be used along with `package:analyzer`, so
you'll likely want to import both packages when writing a tool. So, for
a quick-start example:

```dart
import 'package:analyzer/analyzer.dart';
import 'package:resolver/resolver.dart';

main() async {
  final resolver = new Resolver();
  final library = await resolver.resolveAbsoluteUri('local/file.dart');
  ...
}
```

To be able to resolve files that include `package:`, use `forPackage`:

```dart
import 'package:analyzer/analyzer.dart';
import 'package:resolver/resolver.dart';

main() async {
  final resolver = new Resolver.forPackage('local/path/package');
  final library = await resolver.resolvePackageUri(
    'package', 
    'file.dart',
  );
  ...
}
```
