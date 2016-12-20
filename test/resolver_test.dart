// Copyright (c) 2016, resolver authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as p;
import 'package:resolver/resolver.dart';
import 'package:test/test.dart';

void main() {
  group('Default resolver', () {
    final resolver = new Resolver();

    // Run a common set of basic tests.
    _runCommonTests(resolver);

    test('should partially resolve an absolute file with package:', () async {
      final testDataLibD = p.absolute(p.join('test', '_data', 'lib_d.dart'));

      final libD = await resolver.resolveAbsoluteUri(testDataLibD);
      expect(
        libD.definingCompilationUnit.functions,
        hasLength(1),
      );

      final getDefaultContext = libD.definingCompilationUnit.functions.first;
      expect(getDefaultContext.name, 'getDefaultContext');
      expect(getDefaultContext.parameters, isEmpty);
      expect(
        getDefaultContext.returnType.displayName,
        'dynamic',
        reason: 'We have not told the `Resolver` how to find package: imports.',
      );
    });
  });

  group('Package resolver', () {
    final resolver = new Resolver.forPackage(p.current);

    // Run a common set of basic tests.
    _runCommonTests(resolver);

    test('should fully resolve an absolute file with package:', () async {
      final testDataLibD = p.absolute(p.join('test', '_data', 'lib_d.dart'));

      final libD = await resolver.resolveAbsoluteUri(testDataLibD);
      expect(
        libD.definingCompilationUnit.functions,
        hasLength(1),
      );

      final getDefaultContext = libD.definingCompilationUnit.functions.first;
      expect(getDefaultContext.name, 'getDefaultContext');
      expect(getDefaultContext.parameters, isEmpty);
      expect(getDefaultContext.returnType.displayName, 'Context');
      expect(
        getDefaultContext.returnType.element.library.identifier,
        'package:path/src/context.dart',
      );
    });

    test('should fully resolve a packaged file', () async {
      // This is the same as resolving package:resolver/resolver.dart.
      final libResolver = await resolver.resolvePackageUri(
        'resolver',
        'resolver.dart',
      );

      final exportedLib = libResolver.exports.first.exportedLibrary;
      expect(exportedLib.definingCompilationUnit.types, hasLength(2));

      final resolverClass = exportedLib.definingCompilationUnit.types.first;
      expect(resolverClass.name, 'Resolver');

      // Check and see if our helpers are useful here:
      expect(getVisibleClasses(libResolver).map((t) => t.name), [
        'Resolver',
      ]);
    });

    test('should resolve an in-memory dart file', () async {
      final libFake = await resolver.resolveSourceCode(r'''
        import 'package:resolver/resolver.dart';

        Resolver getResolver() => null;
      ''');

      expect(libFake.definingCompilationUnit.functions, hasLength(1));

      final getResolverMethod = libFake.definingCompilationUnit.functions.first;
      expect(getResolverMethod.name, 'getResolver');

      final returnType = getResolverMethod.returnType;
      expect(returnType.element.name, 'Resolver');
      expect(
        returnType.element.library.identifier,
        'package:resolver/src/resolver.dart',
      );
    });
  });
}

// Runs a common set of tests that will work on all resolver types passed.
void _runCommonTests(Resolver resolver) {
  test('should resolve an absolute file with no imports', () async {
    final testDataLibA = p.absolute(p.join('test', '_data', 'lib_a.dart'));

    final libA = await resolver.resolveAbsoluteUri(testDataLibA);
    expect(
      libA.definingCompilationUnit.functions,
      hasLength(1),
    );

    final getAuthorsMethod = libA.definingCompilationUnit.functions.first;
    expect(getAuthorsMethod.name, 'getAuthors');
    expect(getAuthorsMethod.parameters, isEmpty);
    expect(getAuthorsMethod.returnType.displayName, 'List<String>');

    final returnType = getAuthorsMethod.returnType;
    expect(returnType.element.name, 'List');
    expect(returnType.element.library.name, 'dart.core');

    final paramTypeArg = (returnType as ParameterizedType).typeArguments.first;
    expect(paramTypeArg.name, 'String');
    expect(paramTypeArg.element.library.name, 'dart.core');
  });

  test('should resolve an absolute file with dart SDK imports', () async {
    final testDataLibB = p.absolute(p.join('test', '_data', 'lib_b.dart'));

    final libB = await resolver.resolveAbsoluteUri(testDataLibB);
    expect(
      libB.definingCompilationUnit.accessors,
      hasLength(1),
    );

    final defaultEncoding = libB.definingCompilationUnit.accessors.first;
    expect(defaultEncoding.name, 'defaultEncoding');
    expect(defaultEncoding.parameters, isEmpty);
    expect(defaultEncoding.returnType.displayName, 'Encoding');

    final returnType = defaultEncoding.returnType;
    expect(returnType.element.name, 'Encoding');
    expect(returnType.element.library.name, 'dart.convert');
  });

  test('should resolve an absolute file with relative imports', () async {
    final testDataLibC = p.absolute(p.join('test', '_data', 'lib_c.dart'));

    final libC = await resolver.resolveAbsoluteUri(testDataLibC);
    expect(
      libC.definingCompilationUnit.types,
      hasLength(1),
    );

    final mammal = libC.definingCompilationUnit.types.first;
    expect(mammal.name, 'Mammal');

    final animal = mammal.supertype.element;
    expect(animal.name, 'Animal');

    // This will be different per-platform, so just assert the end.
    expect(animal.library.identifier, endsWith('lib_c_import.dart'));
  });
}
