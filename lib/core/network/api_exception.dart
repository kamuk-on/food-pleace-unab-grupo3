class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.details = const <String, dynamic>{},
  });

  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic> details;

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer('ApiException(')
      ..write('message: $message');
    if (statusCode != null) {
      buffer.write(', statusCode: $statusCode');
    }
    if (code != null) {
      buffer.write(', code: $code');
    }
    buffer.write(')');
    return buffer.toString();
  }
}
