sealed class Result<T> {
  const Result();
}

final class SuccessResult<T> extends Result<T> {
  final T data;

  const SuccessResult(this.data);
}

final class FailureResult<T> extends Result<T> {
  final String message;
  final Object? exception;
  final StackTrace? stackTrace;

  const FailureResult({required this.message, this.exception, this.stackTrace});
}
