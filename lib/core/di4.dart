import 'package:flutter/widgets.dart';





///WARNING: I ran out if time for this unrelated task, so i used LLM-s for this last version, just to see it come to completion
///so AI had a big role in this version by fixing bugs and making the providers internal state representation more robust
///I probably would have came to a very similar conclusion if given enough time, but DI is entirely out of scope for the stopwatch
///so i had to pause the thinkering with this.





/// The immutable identity of a provider.
final class Token<T> {
  Token._();

  Type get type => T;
}

/// Passed to factories to discover and subscribe to other providers.
/// Each [Reference] remembers which token (the "owner") is performing the watch.
final class Reference {
  final Token<dynamic> _owner;
  VoidCallback? onDestroy;

  Reference(this._owner);

  /// Read the current value of [token] without tracking it as a dependency.
  T read<T>(Token<T> token) => DI()._read(token);

  /// Read the current value of [token] and link it to the owner.
  /// Whenever [token] is invalidated, the owner will be invalidated too.
  T watch<T>(Token<T> token) => DI()._watchFromRef(_owner, token);
}

enum _InstanceState { building, ready }

final class _Instance {
  final dynamic value;
  final VoidCallback? onDestroy;
  final _InstanceState state;

  const _Instance._(this.value, this.onDestroy, this.state);

  const _Instance.building() : this._(null, null, _InstanceState.building);

  const _Instance.ready(this.value, this.onDestroy)
    : state = _InstanceState.ready;
}

/// The blueprint for creating a value of type T.
typedef Factory<T> = T Function(Reference ref);

// ---------------------------------------------------------------------------
// Internal change notifier – bridges the DI to Flutter's widget tree
// ---------------------------------------------------------------------------
class _TokenNotifier extends ChangeNotifier {
  void notify() => notifyListeners();

  bool get hasWatchers => hasListeners;
}

// ===========================================================================
// The DI container – global singleton (scope-less by design)
// ===========================================================================
class DI {
  static final DI _instance = DI._internal();

  factory DI() => _instance;

  DI._internal();

  final Map<Token<dynamic>, Factory<dynamic>> _factories = {};
  final Map<Token<dynamic>, _Instance> _instances = {};
  final Map<Token<dynamic>, _TokenNotifier> _notifiers = {};

  /// Downstream: Who depends on me? (Provider -> Set of Consumers)
  final Map<Token<dynamic>, Set<Token<dynamic>>> _dependents = {};

  /// Upstream: Who do I depend on? (Consumer -> Set of Providers)
  final Map<Token<dynamic>, Set<Token<dynamic>>> _dependencies = {};

  /// Dependencies collected during the active build of each token.
  final Map<Token<dynamic>, Set<Token<dynamic>>> _buildDependencies = {};

  /// Circuit breaker: tokens currently being built (prevents circular deps)
  final Set<Token<dynamic>> _building = {};
  final List<Token<dynamic>> _buildStack = [];

  /// Register a factory and return its unique token.
  Token<T> register<T>(Factory<T> factory) {
    final token = Token<T>._();
    _factories[token] = factory;
    return token;
  }

  // ---------------------------------------------------------------
  // Reading (no subscription)
  // ---------------------------------------------------------------
  T _read<T>(Token<T> token) {
    final existing = _instances[token];
    if (existing != null) {
      if (existing.state == _InstanceState.ready) {
        return existing.value as T;
      }
    }

    final factory = _factories[token];
    if (factory == null) {
      throw StateError('No factory registered for ${token.type}.');
    }

    if (_building.contains(token)) {
      throw StateError(
        'Circular dependency detected while building ${token.type}: '
        '${_formatCycle(token)}',
      );
    }

    _building.add(token);
    _buildStack.add(token);
    _instances[token] = const _Instance.building();
    _buildDependencies[token] = <Token<dynamic>>{};

    try {
      final ref = Reference(token as Token<dynamic>);
      final value = (factory as Factory<T>)(ref);

      final instance = _Instance.ready(value, ref.onDestroy);
      _instances[token] = instance;
      _finalizeBuild(token);

      return value;
    } catch (_) {
      _instances.remove(token);
      _buildDependencies.remove(token);
      rethrow;
    } finally {
      _buildStack.removeLast();
      _building.remove(token);
    }
  }

  String _formatCycle(Token<dynamic> repeated) {
    final start = _buildStack.indexOf(repeated);
    final cycle = start == -1
        ? <Token<dynamic>>[..._buildStack, repeated]
        : <Token<dynamic>>[..._buildStack.sublist(start), repeated];

    return cycle.map((t) => t.type.toString()).join(' -> ');
  }

  void _finalizeBuild(Token<dynamic> token) {
    final newDeps = _buildDependencies.remove(token) ?? <Token<dynamic>>{};
    final oldDeps = _dependencies[token] ?? <Token<dynamic>>{};

    final removed = oldDeps.difference(newDeps);
    final added = newDeps.difference(oldDeps);

    for (final upstream in removed) {
      _dependents[upstream]?.remove(token);
      if (_dependents[upstream]?.isEmpty ?? false) {
        _dependents.remove(upstream);
      }
    }

    for (final upstream in added) {
      _dependents.putIfAbsent(upstream, () => <Token<dynamic>>{}).add(token);
    }

    if (newDeps.isEmpty) {
      _dependencies.remove(token);
    } else {
      _dependencies[token] = Set<Token<dynamic>>.from(newDeps);
    }
  }

  // ---------------------------------------------------------------
  // Watching (creates a dependency edge)
  // ---------------------------------------------------------------
  T _watchFromRef<T>(Token<dynamic> owner, Token<T> requested) {
    final result = _read(requested);

    if (owner != requested) {
      _buildDependencies
          .putIfAbsent(owner, () => <Token<dynamic>>{})
          .add(requested);
    }

    return result;
  }

  // ---------------------------------------------------------------
  // Invalidation – destroy downstream, then notify widgets
  // ---------------------------------------------------------------
  void invalidate(Token<dynamic> token) {
    if (_building.contains(token)) {
      throw StateError(
        'Cannot invalidate ${token.type} while it is being built.',
      );
    }

    final dirtyTokens = <Token<dynamic>>{};
    final order = <Token<dynamic>>[];

    _collectInvalidatedTokens(token, dirtyTokens, order);

    for (final t in order) {
      _destroyInstance(t);
    }

    for (final t in order) {
      final notifier = _notifiers[t];
      if (notifier == null) {
        continue;
      }

      try {
        notifier.notify();
      } catch (error, stackTrace) {
        _reportError(
          error,
          stackTrace,
          'while notifying watchers of ${t.type}.',
        );
      }

      _cleanupNotifierIfUnused(t);
    }
  }

  /// Recursively collect all tokens that depend on [token],
  /// clean their dependency edges, and add them to [order] in leaf-first order.
  void _collectInvalidatedTokens(
    Token<dynamic> token,
    Set<Token<dynamic>> visited,
    List<Token<dynamic>> order,
  ) {
    if (!visited.add(token)) return;

    final dependents = List<Token<dynamic>>.from(
      _dependents[token] ?? const [],
    );
    for (final dependent in dependents) {
      _collectInvalidatedTokens(dependent, visited, order);
    }

    final deps = _dependencies.remove(token);
    if (deps != null) {
      for (final upstream in deps) {
        _dependents[upstream]?.remove(token);
        if (_dependents[upstream]?.isEmpty ?? false) {
          _dependents.remove(upstream);
        }
      }
    }

    _dependents.remove(token);
    order.add(token);
  }

  void _destroyInstance(Token<dynamic> token) {
    final instance = _instances.remove(token);
    if (instance == null) return;

    try {
      instance.onDestroy?.call();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace, 'while disposing ${token.type}.');
    }
  }

  void _cleanupNotifierIfUnused(Token<dynamic> token) {
    final notifier = _notifiers[token];
    if (notifier == null) return;

    if (!notifier.hasWatchers) {
      notifier.dispose();
      _notifiers.remove(token);
    }
  }

  void _reportError(Object error, StackTrace stackTrace, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'di_container',
        context: ErrorDescription(context),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------
  /// Completely tear down the DI container (e.g. for testing or app shutdown).
  /// Calls every [onDestroy] callback and clears all state.
  void dispose() {
    final instances = List<MapEntry<Token<dynamic>, _Instance>>.from(
      _instances.entries,
    );

    for (final entry in instances) {
      try {
        entry.value.onDestroy?.call();
      } catch (error, stackTrace) {
        _reportError(error, stackTrace, 'while disposing ${entry.key.type}.');
      }
    }

    for (final notifier in _notifiers.values) {
      notifier.dispose();
    }

    _factories.clear();
    _instances.clear();
    _notifiers.clear();
    _dependents.clear();
    _dependencies.clear();
    _buildDependencies.clear();
    _building.clear();
    _buildStack.clear();
  }

  /// Permanently remove a token, its instance, all its downstream dependents,
  /// and clean the dependency graph.
  void remove(Token<dynamic> token) {
    invalidate(token);
    _factories.remove(token);
  }

  // ---------------------------------------------------------------
  // Notifier access (private to the DI, exposed to Watch mixin)
  // ---------------------------------------------------------------
  _TokenNotifier _getNotifier(Token<dynamic> token) {
    return _notifiers.putIfAbsent(token, () => _TokenNotifier());
  }

  void _unwatchFromMixin(Token<dynamic> token, VoidCallback listener) {
    final notifier = _notifiers[token];
    if (notifier == null) return;

    notifier.removeListener(listener);
    _cleanupNotifierIfUnused(token);
  }
}

// ===========================================================================
// Watch mixin – automatically subscribes/unsubscribes in build
// ===========================================================================
mixin Watch<T extends StatefulWidget> on State<T> {
  final Set<Token<dynamic>> _subscribedTokens = {};
  final Set<Token<dynamic>> _usedInCurrentFrame = {};
  bool _isCleanupScheduled = false;

  /// Read a provider's value and subscribe to changes.
  /// Must be called inside the [build] method.
  S watch<S>(Token<S> token) {
    _usedInCurrentFrame.add(token);

    if (_subscribedTokens.add(token)) {
      DI()._getNotifier(token).addListener(_handleTokenChange);
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
    for (final token in List<Token<dynamic>>.from(_subscribedTokens)) {
      DI()._unwatchFromMixin(token, _handleTokenChange);
    }
    _subscribedTokens.clear();
    _usedInCurrentFrame.clear();
    super.dispose();
  }

  void _handleTokenChange() {
    if (mounted) setState(() {});
  }

  void _pruneSubscriptions() {
    if (!mounted) return;

    final unused = _subscribedTokens.difference(_usedInCurrentFrame);
    for (final token in List<Token<dynamic>>.from(unused)) {
      DI()._unwatchFromMixin(token, _handleTokenChange);
      _subscribedTokens.remove(token);
    }

    _usedInCurrentFrame.clear();
    _isCleanupScheduled = false;
  }
}
