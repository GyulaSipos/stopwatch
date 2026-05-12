import 'package:flutter/widgets.dart';

final class Token<T> {
  Token._();

  Type get type => T;
}

final class Reference {
  VoidCallback? onDestroy;
  T read<T>(Token<T> token) => DI()._read(token);
  T watch<T>(Token<T> token) => DI()._watchFromRef(token);
}

final class Instance<T> {
  final T value;
  final VoidCallback? onDestroy;
  // late final bool Function() keepAlive; //future improvement to override dispose logic

  Instance(this.value, this.onDestroy);
}

typedef Factory<T> = Instance<T> Function(Reference ref);

class MixinNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class DI {
  final Map<Token, Factory> _factories = {};

  final Map<Token, Instance> _instances = {};

  final Map<Instance, MixinNotifier> _mixinWatches = {};

  //final Map<Token, dynamic> _mocks = {};

  //We track what token the [_watchFromRef] was called on, so with other [_watchFromRef] calls during the initial get we can autimatically track dependencies
  Token? _tokenCurrentlyGetting;
  //Track build types to prevent circular dependencies
  final Set<Token> _circuitBreaker = {};

  //If some value invalidates, we want the dependents to do themselves same. This can read dependecies O1;
  final Map<Instance, Set<Instance>> _dependents = {};

  Token<T> register<T>(Factory<T> factory) {
    final token = Token<T>._();
    _factories[token] = factory;
    return token;
  }

  T _read<T>(Token<T> token) {
    if (_instances.containsKey(token)) {
      return (_instances[token] as Instance<T>).value;
    } else {
      final reference = Reference();
      final value = _factories[token]!.call(reference) as T;
      final instance = Instance(value, reference.onDestroy);
      _instances[token] = instance;
      return instance.value;
    }
  }

  T _watchFromRef<T>(Token<T> token) => _watch(token).value;

  (T, MixinNotifier) _watchFromMixin<T>(Token<T> token) {
    final instance = _watch(token);
    final notifier = _mixinWatches[instance] ??= MixinNotifier();
    _mixinWatches[instance] = notifier;
    return (instance.value, notifier);
  }

  Instance<T> _watch<T>(Token<T> token) {
    final previouslyBuiltToken = _tokenCurrentlyGetting;
    _tokenCurrentlyGetting = token;

    Instance? instance;
    try {
      //we check for key existence instead of value to allow null as value
      if (_instances.containsKey(token)) {
        instance = _instances[token] as Instance<T>;
      } else {
        // Since we rebuild this entry, we should remove it from the dependents tree, so discarded dependencies won't stick around
        invalidate(token);
        final reference = Reference();
        final value = _factories[token]!.call(reference); //TODO: error checks
        instance = Instance(value, reference.onDestroy);
        _instances[token] = instance;
      }

      //check for circular dependencies
      final wasAdded = _circuitBreaker.add(token);
      if (!wasAdded) {
        throw Exception(
          "Circular dependency during ${token.type} build via: ${_circuitBreaker.join(" -> ")}",
        );
      }

      //build the dependency graph
      if (previouslyBuiltToken != null) {
        final dependingInstance = _instances[previouslyBuiltToken]!;
        _dependents[instance] ??= {};
        _dependents[instance]!.add(dependingInstance);
      }
      return instance as Instance<T>;
    } finally {
      _tokenCurrentlyGetting = previouslyBuiltToken;
      //By removing only this value (and not clearing everything), we circumvent false positive circular errors in sibling dependencies
      _circuitBreaker.remove(instance);
    }
  }

  final _visitedInstances = <Instance>{};

  void invalidate(Token token) {
    try {
      final instance = _instances[token];
      if (instance != null) {
        _invalidateRecursive(instance);
      }
    } finally {
      _visitedInstances.clear();
    }
  }

  void _invalidateRecursive(Instance instance) {
    final dependents = _dependents[instance];
    if (dependents != null) {
      //deep copy the list to prevent concurrent modification
      for (final dependency in List<Instance>.from(dependents)) {
        if (!_visitedInstances.contains(dependency)) {
          _invalidateRecursive(dependency);
        }
      }
    }
    instance.onDestroy?.call();
    final notifier = _mixinWatches.remove(instance);
    notifier!.notify();
    notifier.dispose();
    _instances.removeWhere((_, value) => value == instance);
    _dependents.remove(instance);
    _visitedInstances.add(instance);
  }

  void _unwatchFromMixin(Token token, VoidCallback listener) {
    final instance = _instances[token];
    final notifier = _mixinWatches[instance];
    notifier?.removeListener(listener);
  }
}

mixin Watch<T extends StatefulWidget> on State<T> {
  //here to track watch changes between rebuilds and remove unised ones
  final Set<Token> _subscribedTokens = {};
  final Set<Token> _usedInCurrentFrame = {};
  bool _isCleanupScheduled = false;

  S watch<S>(Token<S> token) {
    _usedInCurrentFrame.add(token);
    late S value;
    if (!_subscribedTokens.contains(token)) {
      _subscribedTokens.add(token);
      final (returnValue, notifier) = DI()._watchFromMixin(token);
      notifier.addListener(_handleTokenChange);
      value = returnValue;
    } else {
      value = DI()._read(token);
    }

    if (!_isCleanupScheduled) {
      _isCleanupScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pruneSubscriptions(),
      );
    }
    return value;
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
      _subscribedTokens.remove(token);
      DI()._unwatchFromMixin(token, _handleTokenChange);
    }
  }
}
