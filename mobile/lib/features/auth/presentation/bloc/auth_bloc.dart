import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/offline_cache.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final DioClient _dioClient;

  AuthBloc({DioClient? dioClient})
      : _dioClient = dioClient ?? DioClient(),
        super(AuthInitial()) {
    on<AppStartedEvent>(_onAppStarted);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<QuickDemoLoginEvent>(_onQuickDemoLogin);
    on<LogoutSubmittedEvent>(_onLogoutSubmitted);
  }

  Future<void> _onAppStarted(AppStartedEvent event, Emitter<AuthState> emit) async {
    final token = await OfflineCache.getToken();
    final userJson = await OfflineCache.getUserSession();
    if (token != null && token.isNotEmpty && userJson != null) {
      final user = UserEntity.fromJson(userJson);
      emit(Authenticated(user: user, token: token));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmittedEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'username': event.username,
          'password': event.password,
        },
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'] as String;
        final user = UserEntity.fromJson(response.data['user'] as Map<String, dynamic>);
        await OfflineCache.saveUserSession(user.toJson(), token);
        emit(Authenticated(user: user, token: token));
      } else {
        emit(AuthFailure(response.data['message'] ?? 'Login failed. Invalid credentials.'));
      }
    } catch (e) {
      // Offline fallback credentials check for demo
      if (event.username == 'tech_vichai' && event.password == 'password123') {
        const user = UserEntity(
          id: 'mock_tech_vichai',
          username: 'tech_vichai',
          name: 'ช่างวิชัย (Vichai)',
          role: 'technician',
          phone: '081-999-8877',
        );
        const token = 'mock_jwt_token_tech_vichai';
        await OfflineCache.saveUserSession(user.toJson(), token);
        emit(const Authenticated(user: user, token: token));
      } else if (event.username == 'admin' && event.password == 'password123') {
        const user = UserEntity(
          id: 'mock_admin',
          username: 'admin',
          name: 'แอดมินสมศรี (Admin Somsri)',
          role: 'admin',
          phone: '080-111-2233',
        );
        const token = 'mock_jwt_token_admin';
        await OfflineCache.saveUserSession(user.toJson(), token);
        emit(const Authenticated(user: user, token: token));
      } else if (event.username == 'customer1' && event.password == 'password123') {
        const user = UserEntity(
          id: 'mock_customer1',
          username: 'customer1',
          name: 'คุณสมชาย (Somchai)',
          role: 'customer',
          phone: '089-123-4567',
        );
        const token = 'mock_jwt_token_customer';
        await OfflineCache.saveUserSession(user.toJson(), token);
        emit(const Authenticated(user: user, token: token));
      } else {
        String msg = 'Connection error: Unable to reach backend server.';
        if (e is DioException && e.response?.data != null) {
          msg = e.response?.data['message']?.toString() ?? msg;
        }
        emit(AuthFailure(msg));
      }
    }
  }

  Future<void> _onQuickDemoLogin(QuickDemoLoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    String u = 'customer1';
    if (event.role == 'technician') u = 'tech_vichai';
    if (event.role == 'admin') u = 'admin';

    add(LoginSubmittedEvent(username: u, password: 'password123'));
  }

  Future<void> _onLogoutSubmitted(LogoutSubmittedEvent event, Emitter<AuthState> emit) async {
    await OfflineCache.clearSession();
    emit(Unauthenticated());
  }
}
