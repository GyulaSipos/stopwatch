class AppException implements Exception {
  (Null, AppException) box() => (null, this);
}

//create app exceptions like this
class AppExceptionUnknown extends AppException {}

class AppExceptionNotFound extends AppException {}

class AppExceptionUnimplemented extends AppException {}

class AppExceptionAuth extends AppException {}

class AppExceptionLogoutFailed extends AppException {}

class AppExceptionNoUser extends AppException {}

class AppExceptionUpsertFailed extends AppException {}

class AppExceptionWrapped extends AppException {
  final Object? e;
  final StackTrace? s;

  AppExceptionWrapped(this.e, this.s);
}
