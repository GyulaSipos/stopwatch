//Since you mentioned you rolled out your own thing for basically everything, i take this as an opportunity to do the same.
//So, this is a minimum viable DI container baby based on the service locator pattern that hypotetically could grow with us during the project lifetime

class DI {
  //This can hold one factory per type. Good for now, could be expanded if we want to incorporate ProviderFamily-like functionality
  static final Map<Type, Factory> _factories = {};

  //For the actual instances
  static final Map<Type, dynamic> _container = {};

  //If some class updates, we want the dependents to update as well. This can track dependencies.
  static final Map<Type, Set<Type>> _dependents = {};

  static void register<T>(Factory<T> factory) {
    if (_container.containsKey(T)) {
      //If an older version of the same type is already live, get rid of those first
      _invalidate(T);
    }
    _factories[T] = factory;
  }

  //We track what type the [get] was called on, so with other [get] calls during the initial get we can autimatically track dependencies
  static Type? _typeCurrentlyGetting;

  //dependets tracking relies on this being a sync call. Update dependents tracking first if you want this to be async (but you shouldn't want)
  static T get<T>() {
    if (_container.containsKey(T)) {
      return _container[T];
    }

    //if this [get] is called during a [get] call, we know that the type of the original call is depending on this type
    if (_typeCurrentlyGetting != null && _typeCurrentlyGetting != T) {
      //if nothing is depending on T yet, we create the set
      _dependents[T] ??= {};
      _dependents[T]!.add(_typeCurrentlyGetting!);
    }

    final factory = _factories[T];
    if (factory == null) {
      throw Exception("Forgot to register factory for $T");
    } else {
      final previousBuilding = _typeCurrentlyGetting;
      _typeCurrentlyGetting = T;
      try {
        final instance = factory();
        _container[T] = instance;
        return instance as T;
      } finally {
        _typeCurrentlyGetting = previousBuilding;
      }
    }
  }

  static void _invalidate<T>(T type) {
    final dependents = _dependents[type];
    if (dependents != null) {
      for (final dependency in dependents) {
        _invalidate(dependency);
      }
    }
    _container.remove(type);
  }
}

// since everything is static in the DI, no need to pass it in here like usual, factories just can DI.get() themselves
typedef Factory<T> = T Function();
