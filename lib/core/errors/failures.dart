/// Base Failure class for domain and data exceptions
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class VoiceCommandFailure extends Failure {
  const VoiceCommandFailure(super.message, {super.code});
}

class InvoiceScannerFailure extends Failure {
  const InvoiceScannerFailure(super.message, {super.code});
}
