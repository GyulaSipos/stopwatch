import 'package:flutter/material.dart';

//lightweight class used as a locator for providers
final class Token<T> extends ChangeNotifier {
  //creates a new object every time, only allows tokens to be created in this file
  Token._();

  Type get type => T;

  bool get _isWatched => hasListeners;

  VoidCallback? _onDestroy;

  //here to track changes reactively in widgets
  void _notify() => notifyListeners();
}

final class Reference {
  final Token token;
  VoidCallback? onDestroy;

  Reference(this.token);

  T read<T>(Token<T> entry) => DI()._read(token, entry);
  T watch<T>(Token<T> entry) => DI()._watch(token, entry);
}

class DI {
  final Map<Token, Factory> _factories = {};
  //For the actual instances
  final Map<Token, dynamic> _container = {};

  Token<T> register<T>(Factory<T> callBack) {
    final token = Token<T>._();
    _factories[token] = callBack;
    return token;
  }

  T _read<T>(Token reader, Token<T> requested) {
    final cached = _container[requested];
    if (cached != null) {
      return cached;
    } else {
      final instance = _factories[requested]!.call(Reference(reader));
      _container[requested] = instance;
      return instance;
    }
  }

  T _watch<T>(Token reader, Token<T> requested) {
    T? instance = _container[requested];
    final reference = Reference(reader);
    if (instance == null) {
      instance = _factories[requested]!.call(reference);
      requested._onDestroy = reference.onDestroy;
      _container[requested] = instance;
    }
    void listener() {
      reader._onDestroy?.call();
      _container.remove(reader);
      reader._notify();
      if (!requested._isWatched) {
        requested._onDestroy?.call();
        _container.remove(requested);
        requested._notify();
      }
    }

    requested.addListener(listener);
    return instance!;
  }
}

typedef Factory<T> = T Function(Reference);





