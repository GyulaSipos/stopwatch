import 'package:flutter/widgets.dart';

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
  final Token _reader;
  VoidCallback? onDestroy;

  Reference(this._reader);

  T read<T>(Token<T> entry) => DI()._read(entry);
  T watch<T>(Token<T> entry) => DI()._watch(_reader, entry);
}

typedef Factory<T> = T Function(Reference ref);

class DI {
  //Singleton for now so every DI() points back here.
  //Leaves the door open to implement different scopes via InheritedWidget in the future
  //as opposed if we wuld just static everything inside
  static final DI _instance = DI._internal();

  factory DI() => _instance;

  DI._internal();

  //collection of blueprints on how to create the instances
  final Map<Token, Factory> _factories = {};
  //For the actual instances
  final Map<Token, dynamic> _container = {};

  //the only publicly accesible method of the DI
  Token<T> register<T>(Factory<T> callBack) {
    final token = Token<T>._();
    _factories[token] = callBack;
    return token;
  }

  T _instanciateEntry<T>(Token<T> token) {
    final ref = Reference(token);
    final instance = _factories[token]!.call(ref);
    token._onDestroy = ref.onDestroy;
    _container[token] = instance;
    return instance;
  }

  T _read<T>(Token<T> requested) =>
      _container[requested] ?? _instanciateEntry(requested); //TODO: needs null providers to be valid


//TODO: right now this is connection to connection - waay too much of htem could exist
//needs to be rewritten as Provider to Provider
  T _watch<T>(Token reader, Token<T> requested) {
    T? instance = _read(requested);
    void listener() {
      reader._onDestroy?.call();
      _container.remove(reader);
      requested.removeListener(listener);
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

mixin Watch<T extends StatefulWidget> on State<T> {
  //here to track watch changes between rebuilds and remove unised ones
  final Set<Token> _subscribedTokens = {};
  final Set<Token> _usedInCurrentFrame = {};
  bool _isCleanupScheduled = false;

  S watch<S>(Token<S> token) {
    _usedInCurrentFrame.add(token);

    if (!_subscribedTokens.contains(token)) {
      token.addListener(_handleTokenChange);
      _subscribedTokens.add(token);
    }

    if (!_isCleanupScheduled) {
      _isCleanupScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pruneSubscriptions(),
      );
    }

    return DI()._read(token);
  }

  @override
  void dispose() {
    _deactivateListening(_subscribedTokens);
    _subscribedTokens.clear();
    _usedInCurrentFrame.clear();
    super.dispose();
  }

  void _handleTokenChange() {
    if (mounted) setState(() {});
  }

  void _pruneSubscriptions() {
    if (!mounted) return;
    final unusedTokens = _subscribedTokens.difference(_usedInCurrentFrame);
    _deactivateListening(unusedTokens);
    _usedInCurrentFrame.clear();
    _isCleanupScheduled = false;
  }

  void _deactivateListening(Set<Token> tokens) {
    for (final token in List.from(tokens)) {
      token.removeListener(_handleTokenChange);
      _subscribedTokens.remove(token);
      if (!token._isWatched) {
        token._onDestroy?.call();
        token._notify();
        DI()._container.remove(token);
      }
    }
  }
}
