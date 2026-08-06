/// Exceptions thrown by the data layer (datasources). Repositories catch
/// these and translate them into [Failure]s before they reach the domain
/// layer — domain and presentation code should never catch these directly.
class ServerException implements Exception {
  const ServerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);

  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Local cache error']);

  final String message;
}

class UnauthorizedException implements Exception {
  const UnauthorizedException([this.message = 'Unauthorized']);

  final String message;
}
