import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/storage_service.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient apiClient;
  final StorageService storageService;

  AuthService({
    required this.apiClient,
    required this.storageService,
  });

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConstants.register,
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final authRes = AuthResponse.fromJson(response as Map<String, dynamic>);
    await storageService.saveToken(authRes.accessToken);
    await storageService.saveUser(authRes.user);
    return authRes;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConstants.login,
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final authRes = AuthResponse.fromJson(response as Map<String, dynamic>);
    await storageService.saveToken(authRes.accessToken);
    await storageService.saveUser(authRes.user);
    return authRes;
  }

  Future<UserModel> getMe() async {
    final response = await apiClient.get(ApiConstants.me);
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    await storageService.saveUser(user);
    return user;
  }

  Future<void> logout() async {
    await storageService.clearAll();
  }
}
