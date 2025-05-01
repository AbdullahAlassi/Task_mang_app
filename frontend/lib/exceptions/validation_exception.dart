class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  ValidationException(this.message, {this.errors});

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.entries
          .map((e) => '${e.key}: ${e.value.join(', ')}')
          .join('\n');
      return '$message\n$errorMessages';
    }
    return message;
  }
}
