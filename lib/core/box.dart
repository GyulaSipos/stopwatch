import 'app_exception.dart';

/// Why box u ask? Well, it's short, both a noun for the type Box and an verb to .box() stuff into the Box
/// Really it's because of Schrödinger's Box where you don't know if you get the thing out fine or you run into an Exception once you open it
typedef Box<T> = (T?, AppException?);
typedef OnResult<T> = dynamic Function(T);
typedef OnAppException = dynamic Function(AppException);
typedef ToBox<T> = T? Function();

extension Boxtensions<T> on Box<T> {
  dynamic when(OnResult onResult, OnAppException onException) {
    if (this.$1.runtimeType is T) return onResult(this.$1);
    if (this.$2.runtimeType is AppException) return onException(this.$2!);
  }

  bool get hasException => this.$2 != null;

  bool get noValue => this.$2 != null || this.$1 == null;

  bool get hasValue => this.$1 != null;

  bool get isEmpty => this.$1 == null && this.$2 == null;

  (K?, AppException?) cast<K>() => (this.$1 as K?, this.$2);

  T? get value => this.$1;

  AppException? get exception => this.$2;
}

extension ExtensionOnEverything<T /*! Exception */> on T {
  (T?, AppException?) box() => (this, null);

  bool get exists => this != null;
}

extension ExtensionOnDynamic on dynamic {
  (dynamic, AppException?) box() => (this, null);

  bool get exists => this != null;
}

extension FutureBox<T> on Future<T> {
  Future<(T?, AppException?)> box() async {
    return then((value) {
      if (value.runtimeType == Box<T>) {
        value as Box;
        if (value.value.runtimeType == T) {
          return value.cast<T?>();
        } else if (value.hasException) {
          return value.cast<T?>();
        } else if (value.hasValue) {
          return (value.value as T?, null);
        } else {
          return (null, null);
        }
      } else {
        return (value, null);
      }
    }, onError: (e, s) => AppExceptionWrapped(e, s).box());
  }
}
