// Copyright (c) 2016, resolver authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file is the "source of truth" for importing files from package:analyzer.
//
// Because this package is not yet 1.0.0 stable, we want to limit how many
// places we reference internals of the analyzer and provide a narrow interface
// on top of them to make it easy to migrate without touching other code.

import 'dart:io';

import 'package:analyzer/file_system/file_system.dart'
    show Folder, ResourceUriResolver;
import 'package:analyzer/file_system/physical_file_system.dart'
    show PhysicalResourceProvider;
import 'package:analyzer/source/package_map_resolver.dart'
    show PackageMapUriResolver;
import 'package:analyzer/src/dart/sdk/sdk.dart' show FolderBasedDartSdk;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, AnalysisOptions, AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, SourceFactory, UriResolver;
import 'package:package_config/packages_file.dart' as packages_file;
import 'package:path/path.dart' as p;

// "Private" classes from package:analyzer we need to use elsewhere.
export 'package:analyzer/src/generated/engine.dart' show AnalysisContext;

/// Singleton instance of [AnalysisEngine].
final analysisEngine = AnalysisEngine.instance;

/// Singleton instance of [PhysicalResourceProvider].
final physicalFs = PhysicalResourceProvider.INSTANCE;

// Tracks whether we've properly initialized `analysisEngine` yet.
bool _analysisEngineInitialized = false;

/// Returns a new instance of an [AnalysisContext].
AnalysisContext createAnalysisContext() {
  if (!_analysisEngineInitialized) {
    analysisEngine.processRequiredPlugins();
    _analysisEngineInitialized = true;
  }
  return analysisEngine.createAnalysisContext();
}

/// Returns a new [AnalysisOptions] instance to configure an [AnalysisContext].
AnalysisOptions createAnalysisOptions({
  bool analyzeFunctionBodies: false,
}) =>
    new AnalysisOptionsImpl()..analyzeFunctionBodies = analyzeFunctionBodies;

/// Returns a new [SourceFactory] instance to configure an [AnalysisContext].
SourceFactory createSourceFactory({
  Iterable<UriResolver> addResolvers: const [],
}) {
  final dartUriResolver = new DartUriResolver(
    new FolderBasedDartSdk(
      physicalFs,
      FolderBasedDartSdk.defaultSdkDirectory(physicalFs),
    ),
  );
  final uriResolvers = <UriResolver>[dartUriResolver]
    ..addAll(addResolvers)
    ..addAll([new ResourceUriResolver(physicalFs)]);
  return new SourceFactory(uriResolvers);
}

/// Returns a new [UriResolver] that loads and uses `.packages` file.
UriResolver createPackagesResolver(String packageLocation) {
  final dotPackagesFile = p.join(packageLocation, '.packages');
  final rawPackagesMap = packages_file.parse(
    new File(dotPackagesFile).readAsBytesSync(),
    new Uri(scheme: 'file', path: '${packageLocation}${p.separator}'),
  );
  final packagesMap = <String, List<Folder>>{};
  rawPackagesMap.forEach((name, uri) {
    final filePath = uri.toFilePath(windows: Platform.isWindows);
    packagesMap[name] = [physicalFs.getFolder(filePath)];
  });
  return new PackageMapUriResolver(physicalFs, packagesMap);
}
