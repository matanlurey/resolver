// Copyright (c) 2016, resolver authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:resolver/src/analyzer.dart';

/// A Dart source code resolver.
///
/// Acts a simple frontend to `package:analyzer` when the goal is to _resolve_
/// Dart source code into an element structure - i.e. with types, symbols,
/// imports loaded and applied.
///
/// This is useful when creating tooling that requires "live" source code.
abstract class Resolver {
  /// Creates a new [Resolver] only able to resolve absolute URIs.
  ///
  /// Imports of `package:...` files will not be resolved.
  factory Resolver({
    bool analyzeFunctionBodies: false,
  }) {
    final context = createAnalysisContext()
      ..analysisOptions = createAnalysisOptions(
        analyzeFunctionBodies: analyzeFunctionBodies,
      )
      ..sourceFactory = createSourceFactory();
    return new _ContextResolver(context, false);
  }

  /// Creates a new [Resolver] able to resolve package and absolute URIs.
  ///
  /// Imports of `package:...` files will use the `.packages` mapping defined in
  /// the [packagePath] - this assumes that `pub get` (or equivalent) has
  /// already completed for this package.
  factory Resolver.forPackage(
    String packagePath, {
    bool analyzeFunctionBodies: false,
  }) {
    final context = createAnalysisContext()
      ..analysisOptions = createAnalysisOptions(
        analyzeFunctionBodies: analyzeFunctionBodies,
      )
      ..sourceFactory = createSourceFactory(addResolvers: [
        createPackagesResolver(packagePath),
      ]);
    return new _ContextResolver(context, true);
  }

  /// Returns resolved [LibraryElement] representing the file at [absoluteUri].
  Future<LibraryElement> resolveAbsoluteUri(String absoluteUri);

  /// Returns resolved [LibraryElement] representing [packageName]:[fileName].
  Future<LibraryElement> resolvePackageUri(String packageName, String fileName);

  /// Returns resolved [LibraryElement] representing [sourceCode].
  Future<LibraryElement> resolveSourceCode(String sourceCode);
}

/// Implements [Resolver] on top of an [AnalysisContext].
class _ContextResolver implements Resolver {
  final AnalysisContext _context;
  final bool _supportsPackageUris;

  const _ContextResolver(this._context, this._supportsPackageUris);

  @override
  Future<LibraryElement> resolveAbsoluteUri(String absoluteUri) async {
    final assetUri = new Uri(scheme: 'file', path: absoluteUri);
    final source = _context.sourceFactory.forUri2(assetUri);
    if (source == null) {
      throw new ArgumentError('Not a valid URI: ${assetUri}');
    }
    return _context.computeLibraryElement(source);
  }

  @override
  Future<LibraryElement> resolvePackageUri(
    String packageName,
    String fileName,
  ) async {
    if (!_supportsPackageUris) {
      throw new UnsupportedError('Use Resolver.forPackage to use this method');
    }
    final assetUri = new Uri(scheme: 'package', path: '$packageName/$fileName');
    final source = _context.sourceFactory.forUri2(assetUri);
    if (source == null) {
      throw new ArgumentError('Not a valid URI: ${assetUri}');
    }
    return _context.computeLibraryElement(source);
  }

  @override
  Future<LibraryElement> resolveSourceCode(String sourceCode) async {
    final source = new InMemorySource(sourceCode);
    return _context.computeLibraryElement(source);
  }
}
