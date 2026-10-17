import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  factory ApiException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Kết nối máy chủ quá hạn. Vui lòng kiểm tra lại mạng.');
      case DioExceptionType.badResponse:
        final response = dioError.response;
        final data = response?.data;
        String msg = 'Có lỗi xảy ra từ máy chủ.';
        if (data is Map && data.containsKey('message')) {
          msg = data['message'].toString();
        } else if (data is Map && data.containsKey('error')) {
          msg = data['error'].toString();
        }
        return ApiException(
          message: msg,
          statusCode: response?.statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Yêu cầu đã bị hủy.');
      case DioExceptionType.connectionError:
        return ApiException(message: 'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng.');
      default:
        return ApiException(message: 'Đã xảy ra lỗi không xác định.');
    }
  }

  @override
  String toString() => message;
}
