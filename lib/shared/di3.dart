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

  Instance(this.value, this.onDestroy);
}

typedef Factory<T> = T Function(Reference ref);

class MixinNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class DI {
  static final DI _instance = DI._internal();

  factory DI() => _instance;

  DI._internal();

  final Map<Token<dynamic>, Factory<dynamic>> _factories = {};
  final Map<Token<dynamic>, Instance<dynamic>> _instances = {};
  final Map<Token<dynamic>, MixinNotifier> _tokenNotifiers = {};
  final Map<Token<dynamic>, Set<Token<dynamic>>> _dependents = {};

  final List<Token<dynamic>> _resolutionStack = <Token<dynamic>>[];
  final Set<Token<dynamic>> _resolving = <Token<dynamic>>{};

  Token<T> register<T>(Factory<T> factory) {
    final token = Token<T>._();
    _factories[token] = factory;
    return token;
  }

  T _read<T>(Token<T> token) => _resolve(token, trackDependency: false);

  T _watchFromRef<T>(Token<T> token) => _resolve(token, trackDependency: true);

  (T, MixinNotifier) _watchFromMixin<T>(Token<T> token) {
    return (_read(token), _notifierFor(token));
  }

  MixinNotifier _notifierFor(Token<dynamic> token) {
    return _tokenNotifiers.putIfAbsent(token, () => MixinNotifier());
  }

  void _registerDependency(
    Token<dynamic> dependency,
    Token<dynamic> dependent,
  ) {
    if (dependency == dependent) {
      throw StateError('Token ${dependency.type} cannot depend on itself.');
    }
    _dependents
        .putIfAbsent(dependency, () => <Token<dynamic>>{})
        .add(dependent);
  }

  String _formatCycle(Token<dynamic> repeated) {
    final start = _resolutionStack.indexOf(repeated);
    final cycle = start == -1
        ? <Token<dynamic>>[..._resolutionStack, repeated]
        : <Token<dynamic>>[..._resolutionStack.sublist(start), repeated];

    return cycle.map((token) => token.type.toString()).join(' -> ');
  }

  T _resolve<T>(Token<T> token, {required bool trackDependency}) {
    final parent = _resolutionStack.isEmpty ? null : _resolutionStack.last;

    final existing = _instances[token];
    if (existing != null) {
      if (trackDependency && parent != null) {
        _registerDependency(token, parent);
      }
      return existing.value as T;
    }

    if (_resolving.contains(token)) {
      throw StateError(
        'Circular dependency during ${token.type} build via: ${_formatCycle(token)}',
      );
    }

    final factory = _factories[token];
    if (factory == null) {
      throw StateError('No factory registered for ${token.type}.');
    }

    _resolving.add(token);
    _resolutionStack.add(token);

    try {
      final reference = Reference();
      final value = (factory as Factory<T>)(reference);

      _instances[token] = Instance(value, reference.onDestroy);

      if (trackDependency && parent != null) {
        _registerDependency(token, parent);
      }

      return value;
    } finally {
      _resolutionStack.removeLast();
      _resolving.remove(token);
    }
  }

  void invalidate(Token<dynamic> token) {
    final visited = <Token<dynamic>>{};
    _invalidateRecursive(token, visited);
  }

  void _invalidateRecursive(Token<dynamic> token, Set<Token<dynamic>> visited) {
    if (!visited.add(token)) return;

    final dependents = List<Token<dynamic>>.from(
      _dependents[token] ?? const [],
    );
    for (final dependent in dependents) {
      _invalidateRecursive(dependent, visited);
    }

    final instance = _instances.remove(token);
    _removeDependencyLinks(token);

    try {
      instance?.onDestroy?.call();
    } finally {
      _tokenNotifiers[token]?.notify();
    }
  }

  void _removeDependencyLinks(Token<dynamic> token) {
    _dependents.remove(token);
    for (final dependents in _dependents.values) {
      dependents.remove(token);
    }
  }

  void _unwatchFromMixin(Token<dynamic> token, VoidCallback listener) {
    _tokenNotifiers.remove(token)?.removeListener(listener);
  }
}

mixin Watch<T extends StatefulWidget> on State<T> {
  final Set<Token<dynamic>> _subscribedTokens = <Token<dynamic>>{};
  final Set<Token<dynamic>> _usedInCurrentFrame = <Token<dynamic>>{};
  bool _isCleanupScheduled = false;

  S watch<S>(Token<S> token) {
    _usedInCurrentFrame.add(token);

    final (value, notifier) = DI()._watchFromMixin(token);
    if (_subscribedTokens.add(token)) {
      notifier.addListener(_handleTokenChange);
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

  void _deactivateListening(Set<Token<dynamic>> tokens) {
    for (final token in List<Token<dynamic>>.from(tokens)) {
      _subscribedTokens.remove(token);
      DI()._unwatchFromMixin(token, _handleTokenChange);
    }
  }
}
