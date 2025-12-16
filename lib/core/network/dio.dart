import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/core/network/auth_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final Dio dio = Dio(
  BaseOptions(
    baseUrl: kDebugMode
        ? 'http://10.0.2.2:8000/api/v1'
        : 'https://musakki.com/api/v1',
    headers: {
      'Accept': 'application/json',
    },
  ),
)
  ..interceptors.addAll([
    AuthInterceptor(),
    PrettyDioLogger(
      requestHeader: true,
      requestBody: false,
      responseHeader: true,
      responseBody: false, // avoid logging huge bodies that may cause issues
      compact: true,
      maxWidth: 120,
    ),
  ]);
