// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_dropbox_suppression.dart';

const _tracerName = 'dartastic_otel_libs_dropbox';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Dropbox API endpoint call in a CLIENT span. [endpoint]
/// is the dotted RPC name (e.g. `files.upload`, `sharing.list_folder
/// _members`, `users.get_current_account`).
Future<T> tracedDropbox<T>({
  required String endpoint,
  required Future<T> Function() invoke,
  String? pathLower,
  int? sizeBytes,
}) async {
  if (dropboxInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'dropbox.endpoint': endpoint,
    'dropbox.operation': endpoint,
  };
  if (pathLower != null) m['dropbox.path_lower'] = pathLower;
  if (sizeBytes != null) m['dropbox.size'] = sizeBytes;

  final span = _tracer().startSpan(
    'dropbox $endpoint',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
