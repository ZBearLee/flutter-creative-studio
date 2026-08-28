import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'app_exception.dart';

/// 通用 Dio 客户端封装
///
/// - 单例：全局一份 Dio，复用底层连接池
/// - baseUrl：由调用方在构造时传入（DeepSeek / 硅基流动各一份）
/// - 拦截器：非 2xx 拒绝 + debug 日志
/// - 流式响应：用 [streamSse] 方法，禁用接收超时（receiveTimeout = 0）
///
/// 异常处理策略：
/// - 拦截器只做日志和非 2xx 拒绝，不转换异常类型（Dio 限制）
/// - 在 post/get/streamSse 方法层 try/catch 把 DioException → AppException
class DioClient {
  final Dio _dio;

  DioClient({
    required String baseUrl,
    String? apiKey, // 可空：未配置 Key 时仍可构造，调用时报错
    Map<String, String>? extraHeaders,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            // 默认接收超时 30s；流式调用时会单独设 0
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
              if (apiKey != null && apiKey.isNotEmpty)
                'Authorization': 'Bearer $apiKey',
              ...?extraHeaders,
            },
          ),
        ) {
    // 响应拦截：非 2xx 视为业务异常并拒绝（让 Dio 抛 DioException）
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onResponse: (response, handler) {
          if (response.statusCode != null &&
              (response.statusCode! < 200 || response.statusCode! >= 300)) {
            handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          handler.next(response);
        },
        // onError 不做异常类型转换（Dio 限制只能传 DioException）
        // 异常转换放在方法层 try/catch 里做
        onError: (e, handler) => handler.next(e),
      ),
    );

    // debug 模式打印请求/响应（release 包自动不生效）
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: false, // 流式响应体过长，不打
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 120,
        ),
      );
    }
  }

  /// 普通业务请求（JSON in / JSON out）
  Future<Response<T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: body,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// SSE 流式请求
  ///
  /// 调用方拿到 [Response] 后，把 `response.data`（`Stream<List<int>>`）
  /// 交给 [SseParser.parse] 解析为业务事件流。
  ///
  /// 关键点：[ResponseType.stream] + receiveTimeout = Duration.zero
  /// （流式可能持续几十秒，不能用固定超时）
  Future<Response> streamSse(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          // Duration.zero 是静态常量字段（非构造器），不能加 const
          receiveTimeout: Duration.zero, // 流式禁用接收超时
        ),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// 供 [PollingRunner] 等场景用的简单 GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// DioException → AppException 统一映射
  ///
  /// 把各种零散的 [DioExceptionType] 收敛到 4 个业务异常类，
  /// UI 层就不需要关心底层是连接超时还是证书错误。
  AppException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401 || code == 403) {
          return const UnauthorizedException();
        }
        // 尝试从响应体提取服务端错误信息
        final data = e.response?.data;
        String msg = '请求失败 ($code)';
        if (data is Map && data['message'] is String) {
          msg = data['message'] as String;
        } else if (data is String && data.isNotEmpty) {
          msg = data;
        }
        return ApiException(
          message: msg,
          statusCode: code,
          errorCode: data is Map ? data['code']?.toString() : null,
        );
      case DioExceptionType.cancel:
        return const UnknownException('请求已取消');
      default:
        return UnknownException(e.message ?? '未知错误');
    }
  }
}
