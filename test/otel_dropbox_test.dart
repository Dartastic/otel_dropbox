// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_dropbox/otel_dropbox.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_dropbox-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('files.upload records CLIENT span', () async {
    await tracedDropbox<String>(
      endpoint: 'files.upload',
      pathLower: '/docs/report.pdf',
      sizeBytes: 51200,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('dropbox files.upload')!);
    expect(a['dropbox.endpoint'], 'files.upload');
    expect(a['dropbox.path_lower'], '/docs/report.pdf');
    expect(a['dropbox.size'], 51200);
  });

  test('suppression skips spans', () async {
    await runWithoutDropboxInstrumentationAsync(() async {
      await tracedDropbox<String>(
        endpoint: 'files.list',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('dropbox '), isEmpty);
  });
}
