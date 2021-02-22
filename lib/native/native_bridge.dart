
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shadows/model/exceptions.dart';
import 'package:rxdart/rxdart.dart';

typedef FlutterMethodHandler = Future<Map<String, dynamic>> Function(Map<String, dynamic>);

typedef FlutterStreamHandler = Stream<Map<String, dynamic>> Function(Map<String, dynamic>);

class NativeBridge {
  String _channelName;
  MethodChannel _methodChannel;
  final Map<String, FlutterMethodHandler> _methodHandlers = {};
  final Map<String, FlutterStreamHandler> _streamHandlers = {};

  final Map<int, StreamController<Map<String, dynamic>>> _nativeControllers = {};

  final Map<int, StreamSubscription> _flutterStreamSubscriptions = {};

  NativeBridge(String channelName) {
    this._channelName = channelName;
  }

  /// Register a Flutter method handler which can be called from the native code.
  ///
  /// [name] handler identifier that must be specified in the native code to be called
  /// [handler] method handler to be invoked from the native code
  void registerInvocationHandler(String name, FlutterMethodHandler handler) {
    _methodHandlers[name] = handler;
  }

  /// Register a Flutter stream handler which maps Dart streams into
  /// native streams (RxJava Observable streams for Android).
  ///
  /// [name] stream handler name that is also specified on the native side.
  /// [handler] stream factory
  void registerStreamHandler(String name, FlutterStreamHandler handler) {
    _streamHandlers[name] = handler;
  }

  /// Invoke the native method from the Flutter.
  ///
  /// [name] native method handler identifier
  /// [argument] arguments for native method
  Future<Map<String, dynamic>> invokeNativeMethod(String name, Map<String, dynamic> argument) async {
    final serializedArgument = jsonEncode(argument);

    try {
      print("NativeBridge: Calling native method '$name' with arguments: $serializedArgument");
      final serializedResponse = await _methodChannel.invokeMethod(
          name, serializedArgument) as String;
      final decodedResponse = jsonDecode(serializedResponse);
      return decodedResponse;
    } on PlatformException catch (e) {
      throw RemoteException(e.code, e.message);
    }
  }

  /// Create a native stream and map it to the Dart Stream.
  ///
  /// Now only one subscription is allowed for the stream returned by this call.
  /// But you can call this method with same arguments more than once in order
  /// to have multiple stream subscriptions.
  ///
  /// Note! Do not forget to unsubscribe from the native stream when it is not
  /// needed anymore.
  ///
  /// Actually native stream creation logic may expose the same native stream instance
  /// more than once but from the Dart's point of view they all are mapped to different
  /// Dart Stream instances and it is ok due to Dart subscription model.
  ///
  /// [name] native stream handler name
  /// [argument] arguments for creating native stream
  Stream<Map<String, dynamic>> invokeNativeStream(String name, Map<String, dynamic> argument) {
    return setupStream(() async {
      var response = await invokeNativeMethod("stream:createId", {});
      var streamId = response['id'];
      return _createNativeStream(name, argument, streamId);
    });
  }

  Stream<Map<String, dynamic>> _createNativeStream(String name, Map<String, dynamic> argument, int id) {
    StreamController<Map<String, dynamic>> controller;

    void startStream() {
      _nativeControllers[id] = controller;
      final finalArgs = {
        "name": name,
        "args" : argument,
        "id": id
      };
      invokeNativeMethod("stream:start", finalArgs);
    }

    void stopStream() {
      controller.close();
      final args = {
        "id": id
      };
      invokeNativeMethod("stream:stop", args);
    }

    controller = StreamController<Map<String, dynamic>>(
        onListen: startStream,
        onCancel: stopStream
    );

    return controller.stream;
  }

  /// Initialize native bridge
  ///
  /// This method must be called after runApp() call.
  void start() {
    _methodChannel = MethodChannel(_channelName);
    _methodChannel.setMethodCallHandler(_onMethodCalled);

    registerInvocationHandler("stream:onEvent", (args) async {
      final id = args['id'];
      final data = args['data'];

      StreamController controller = _nativeControllers[id];
      if (controller != null) {
        controller.add(data);
      }

      return {};
    });

    registerInvocationHandler("stream:onComplete", (args) async {
      final id = args['id'];
      StreamController controller = _nativeControllers[id];
      if (controller != null) {
        controller.close();
        _nativeControllers.remove(id);
      }
      return {};
    });

    registerInvocationHandler("stream:onError", (args) async {
      final id = args['id'];
      final errorCode = args['code'];
      final errorMessage = args['message'];
      StreamController controller = _nativeControllers[id];
      if (controller != null) {
        controller.addError(RemoteException(errorCode, errorMessage));
        controller.close();
        _nativeControllers.remove(id);
      }
      return {};
    });

    registerInvocationHandler("flutterStream:start", (args) async {
      final id = args['id'];
      final name = args['name'];
      final data = args['args'];

      final handler = _streamHandlers[name];
      if (handler == null) throw RemoteException("FlutterException", "Stream handler not found");

      final flutterStream = handler.call(data);
      print("NativeBridge: Flutter stream #$id subscribed");

      final subscription = flutterStream.listen( // ignore: cancel_subscriptions
              (event) {
            print("NativeBridge: Flutter stream #$id fired event: $event");
            invokeNativeMethod("flutterStream:onEvent", {
              "id": id,
              "data": event
            });
          }, onError: (error, stackTrace) {
        print(stackTrace);
        print("NativeBridge: Flutter stream #$id failed with error: $error");

        final errorCode = error is RemoteException ? error.code : error.runtimeType.toString();
        final errorMessage = error is RemoteException ? error.message : error.runtimeType.toString();
        _clearSubscription(id);
        invokeNativeMethod("flutterStream:onError", {
          "id": id,
          "code": errorCode,
          "error": errorMessage
        });
      }, onDone: () {
        print("NativeBridge: Flutter stream #$id completed");
        _clearSubscription(id);
        invokeNativeMethod("flutterStream:onComplete", {
          "id": id
        });
      });

      _flutterStreamSubscriptions[id] = subscription;

      return {};
    });

    registerInvocationHandler("flutterStream:stop", (args) async {
      final id = args['id'];
      final subscription = _flutterStreamSubscriptions[id];
      if (subscription != null) {
        print("NativeBridge: Flutter stream #$id subscription disposed");
        subscription.cancel();
        _clearSubscription(id);
      }
      return {};
    });

    invokeNativeMethod("onFlutterInitialized", {});
  }

  Future<dynamic> _onMethodCalled(MethodCall methodCall) async {
    final name = methodCall.method;
    final handler = _methodHandlers[name];
    if (handler == null) {
      throw PlatformException(code: "FlutterException", message: "Method '$name' is not implemented on the Flutter side");
    }

    final decodedArg = jsonDecode(methodCall.arguments as String);

    print("NativeBridge: Got call from Native: '$name' with args: $decodedArg");

    final result = await handler.call(decodedArg);
    final serializedResult = jsonEncode(result);

    if (result.isNotEmpty) {
      print(
          "NativeBridge: Sending response from Flutter method: '$name' to native: $serializedResult");
    }

    return serializedResult;
  }

  void _clearSubscription(int id) {
    _flutterStreamSubscriptions.remove(id);
  }
}

Stream<T> setupStream<T>(Future<Stream<T>> Function() creator) {
  return Stream
      .fromFuture(creator.call())
      .flatMap((value) => value);
}