/// 网络层统一异常体系
///
/// UI 层 try/catch 时只要判断类型，就能给用户对应的 toast 提示：
/// ```
/// try {
///   await api.fetch();
/// } on NetworkException {
///   toast('网络连接失败，请检查网络');
/// } on UnauthorizedException {
///   toast('API Key 无效，请到设置页重新配置');
/// } on ApiException catch (e) {
///   toast('服务异常：${e.message}');
/// } on TimeoutException {
///   toast('请求超时，请重试');
/// }
/// ```
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// 网络层异常：无网络 / DNS 解析失败 / 连接被拒
class NetworkException extends AppException {
  const NetworkException([super.message = '网络连接失败，请检查网络']);
}

/// 鉴权失败：API Key 缺失 / 失效 / 额度用尽
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'API Key 无效或已过期']);
}

/// 请求超时：连接超时 / 接收超时 / 轮询超时
class TimeoutException extends AppException {
  const TimeoutException([super.message = '请求超时，请稍后重试']);
}

/// 业务异常：HTTP 状态非 2xx，服务端返回了错误码和错误信息
class ApiException extends AppException {
  final int? statusCode;
  final String? errorCode;

  const ApiException({
    required String message,
    this.statusCode,
    this.errorCode,
  }) : super(message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 未知异常：请求被取消 / 其他未归类错误
///
/// 单独抽出来是因为 [AppException] 是 sealed class 不能直接实例化，
/// cancel 等兜底场景需要一个具体子类。
class UnknownException extends AppException {
  const UnknownException([super.message = '未知错误']);
}
