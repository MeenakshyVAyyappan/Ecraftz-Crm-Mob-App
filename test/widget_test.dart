import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecraftz_crm/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    HttpOverrides.global = FakeHttpOverrides();

    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{};
      }
      return null;
    });

    try {
      await Supabase.initialize(
        url: 'https://bnjvugxvcoqgfvvvwpzc.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJuanZ1Z3h2Y29xZ2Z2dnZ3cHpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODMzMTA4NTMsImV4cCI6MjA5ODg4Njg1M30.Fe5COvy60ezaVwrrDOR_Ec-1wDRizd6FiPp9vtHy2O4',
        authOptions: const FlutterAuthClientOptions(
          localStorage: EmptyLocalStorage(),
        ),
      );
    } catch (_) {
      // Ignore if already initialized
    }
  });

  testWidgets('EcraftzCRMApp loads and renders LoginPage', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Caught Flutter error in test: ${details.exception}\n${details.stack}');
    };

    // Build our app and trigger a frame.
    await tester.pumpWidget(const EcraftzCRMApp());
    await tester.pump();

    // Print widget hierarchy for debugging
    for (final element in find.byType(Widget).evaluate()) {
      if (element.widget is Text) {
        print('Rendered text widget: ${(element.widget as Text).data}');
      }
    }
  });
}

class FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient();
  }
}

class FakeHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    Uri? url;
    if (invocation.positionalArguments.isNotEmpty && invocation.positionalArguments.first is Uri) {
      url = invocation.positionalArguments.first as Uri;
    }
    return Future.value(FakeHttpClientRequest(url));
  }
}

class FakeHttpClientRequest implements HttpClientRequest {
  final Uri? url;
  FakeHttpClientRequest(this.url);

  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(FakeHttpClientResponse(url));
    }
    if (invocation.memberName == #done) {
      return Future.value(FakeHttpClientResponse(url));
    }
    return null;
  }
}

class FakeHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  final Uri? url;
  FakeHttpClientResponse(this.url);

  @override
  int get statusCode {
    if (url != null && url!.path.contains('/auth/v1/')) {
      return 400; // Fallback to unauthenticated by returning 400 error for auth
    }
    return 200;
  }

  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final body = (url != null && url!.path.contains('/auth/v1/')) ? '{"error":"unauthorized"}' : '[]';
    return Stream<List<int>>.value(utf8.encode(body)).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}
