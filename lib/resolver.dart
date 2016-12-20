// Copyright (c) 2016, resolver authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

export 'package:resolver/src/resolver.dart' show Resolver;

/// Returns a lazy iterable of all visible function elements from [library].
///
/// Definition of **visible**:
///
/// * The function must be "public" (i.e. not prefixed with `_`)
/// * The function may be exported from an `exports` directive
Iterable<FunctionElement> getVisibleFunctions(LibraryElement library) sync* {
  yield* library.definingCompilationUnit.functions.where((f) => f.isPublic);
  yield* library.exportedLibraries.map(getVisibleFunctions).expand((i) => i);
}

/// Returns a lazy iterable of all visible class elements from [library].
///
/// Definition of **visible**:
///
/// * The class must be "public" (i.e. not prefixed with `_`)
/// * The class may be exported from an `exports` directive
Iterable<ClassElement> getVisibleClasses(LibraryElement library) sync* {
  yield* library.definingCompilationUnit.types.where((t) => t.isPublic);
  yield* library.exportedLibraries.map(getVisibleClasses).expand((i) => i);
}
