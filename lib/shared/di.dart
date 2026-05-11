//Since you mentioned you rolled out your own thing for basically everything, i take this as an opportunity to do the same.
//So, this is a minimum viable DI container baby based on the service locator pattern that hypotetically could grow with us during the project lifetime
import 'package:flutter/material.dart';

class DI {
  //This can hold one factory per type. Good for now, could be expanded if we want to incorporate ProviderFamily-like functionality
  static final Map<Token, Factory> _factories = {};

  //For the actual instances
  static final Map<Token, dynamic> _container = {};

  static final Map<Token, dynamic> _mocks = {};

  //If some value updates, we want the dependents to update as well. This can track dependencies.
  static final Map<Token, Set<Token>> _dependents = {};

  static Token<T> register<T>(Factory<T> factory) {
    final token = Token<T>._();
    _factories[token] = factory;
    return token;
  }

  ///Use it only to mock out entries in tests
  @visibleForTesting
  static void mock<T>(Token<T> token, T value) {
    _mocks[token] = value;
    _invalidateRecursive(token);
  }

  ///Clears the entire container, mocks and everything.
  ///Useful betweent tests
  static void clear() {
    _mocks.clear();
    _container.clear();
    _factories.clear();
    _dependents.clear();
    _visitedTokens.clear(); //just in case
  }

  //We track what type the [get] was called on, so with other [get] calls during the initial get we can autimatically track dependencies
  static Token? _tokenCurrentlyGetting;
  //Track build types to prevent circular dependencies
  static final Set<Token> _circuitBreaker = {};

  //dependets tracking relies on this being a sync call. Update dependents tracking first if you want this to be async (but you shouldn't want)
  static T get<T>(Token<T> token) {
    //if this [get] is called during a [get] call, we know that the type of the original call is depending on this type
    if (_tokenCurrentlyGetting != null && _tokenCurrentlyGetting != token) {
      //if nothing is depending on T yet, we create the set
      _dependents[token] ??= {};
      _dependents[token]!.add(_tokenCurrentlyGetting!);
    }

    if (_mocks.containsKey(token)) {
      return _mocks[token];
    }

    if (_container.containsKey(token)) {
      return _container[token];
    }

    final wasNotAlreadyDependent = _circuitBreaker.add(token);
    if (!wasNotAlreadyDependent) {
      throw CircularDependencyException(
        'Exception: $T is trying to depend on itself via ${_circuitBreaker.map((token) => token.type).join(' -> ')} -> $T',
      );
    }

    final factory = _factories[token];
    if (factory == null) {
      throw MissingFactoryException("Forgot to register factory for $T");
    } else {
      final previousBuilding = _tokenCurrentlyGetting;
      _tokenCurrentlyGetting = token;
      try {
        // Since we rebuild this entry, we should remove it from the dependents tree, so removed dependencies won't stick around
        for (final set in _dependents.values) {
          set.remove(token);
        }
        final instance = factory();
        _container[token] = instance;
        return instance as T;
      } finally {
        _tokenCurrentlyGetting = previousBuilding;
        //By removing only this value (and not clearing everything), we circumvent false positive circular errors in sibling dependencies
        _circuitBreaker.remove(token);
      }
    }
  }

  static final _visitedTokens = <Token>{};

  static void invalidate(Token token) {
    try {
      _invalidateRecursive(token);
    } finally {
      _visitedTokens.clear();
    }
  }

  static void _invalidateRecursive(Token token) {
    final dependents = _dependents[token];
    if (dependents != null) {
      //deep copy the list to prevent concurrent modification
      for (final dependency in List<Token>.from(dependents)) {
        if (!_visitedTokens.contains(dependency)) {
          _invalidateRecursive(dependency);
        }
      }
    }
    _container.remove(token);
    _dependents.remove(token);
    _visitedTokens.add(token);
    token._notify();
  }
}

//lightweight class used as a locator for providers
final class Token<T> extends ChangeNotifier {
  //creates a new object every time, only allows tokens to be created in this file
  Token._();

  Type get type => T;

  //here to track changes reactively in widgets
  void _notify() => notifyListeners();
}

mixin Watch<T extends StatefulWidget> on State<T> {
  // Store the tokens this widget is currently listening to
  final Set<Token> _subscribedTokens = {};

  /// Use this inside your build method
  S watch<S>(Token<S> token) {
    final value = DI.get(token);
    if (!_subscribedTokens.contains(token)) {
      token.addListener(_handleTokenChange);
      _subscribedTokens.add(token);
    }
    return value;
  }

  @override
  void dispose() {
    // Clean up all subscriptions when widget leaves
    for (var token in _subscribedTokens) {
      token.removeListener(_handleTokenChange);
    }
    super.dispose();
  }

  void _handleTokenChange() {
    if (mounted) setState(() {});
  }
}

// since everything is static in the DI, no need to pass it in here like usual, factories just can DI.get() themselves
typedef Factory<T> = T Function();
//convinience typedefs for DX
typedef CircularDependencyException = Exception;
typedef MissingFactoryException = Exception;
