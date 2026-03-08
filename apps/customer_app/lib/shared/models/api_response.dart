class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final PaginationMeta? meta;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromJsonT,
  }) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: fromJsonT != null && json['data'] != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PaginationMeta {
  final int page;
  final int perPage;
  final int total;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  bool get hasNextPage => page < totalPages;
}
