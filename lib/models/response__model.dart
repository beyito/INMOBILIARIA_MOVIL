class ResponseModel {
  final int? status;
  final int? error;
  final String? message;
  final dynamic values;

  ResponseModel({this.status, this.error, this.message, this.values});

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    return ResponseModel(
      status: json['status'],
      error: json['error'],
      message: json['message'],
      values: json['values'],
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'error': error,
    'message': message,
    'values': values,
  };
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({required this.success, this.message, this.data});

  factory ApiResponse.success(T data) {
    return ApiResponse(success: true, data: data);
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(success: false, message: message);
  }
}
