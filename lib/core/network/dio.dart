import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:homecare_mobile/core/network/auth_interceptor.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final Dio dio = Dio(
  BaseOptions(
    baseUrl: kDebugMode
        ? 'http://10.0.2.2:8000/api'
        : 'https://musakki.com/api',
  ),
)..interceptors.addAll([AuthInterceptor(), PrettyDioLogger()]);
