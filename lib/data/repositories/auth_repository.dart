import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/storage/session_store.dart';

class AuthRepository {
  AuthRepository(this._api, this._session);

  final ApiClient _api;
  final SessionStore _session;

  Future<void> login({
    required String serverUrl,
    required String email,
    required String password,
    String? totp,
  }) async {
    final url = AppConfig.normalizeBaseUrl(serverUrl);
    if (url.isEmpty) throw const ApiException('Informe a URL do servidor InTimeOS.');
    await _session.setBaseUrl(url);

    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      if (totp != null && totp.trim().isNotEmpty) 'totp': totp.trim(),
    };

    final result = await _api.post(
      '/login',
      auth: false,
      body: body,
    );

    final map = result is Map ? Map<String, dynamic>.from(result) : const <String, dynamic>{};
    final access = map['access_token'] as String?;
    if (access == null) throw const ApiException('Resposta de login inválida.');

    await _session.saveTokens(access: access, refresh: map['refresh_token'] as String?);
    final perms = map['permissions'];
    if (perms is List && perms.isNotEmpty && perms.first is Map) {
      await _session.savePermissions(Map<String, dynamic>.from(perms.first as Map));
    }
    await _session.setLastEmail(email.trim());
  }

  /// Revoga o refresh token no servidor (POST /api/v1/logout) e limpa a sessão local.
  Future<void> logout() async {
    final refresh = _session.refreshToken;
    if (refresh != null && refresh.isNotEmpty && (_session.baseUrl ?? '').isNotEmpty) {
      try {
        await _api.post('/logout', auth: false, body: {'refresh_token': refresh});
      } catch (_) {
        // Ignora falhas de rede ao deslogar e limpa os tokens locais mesmo assim.
      }
    }
    await _session.clearSession();
  }
}
