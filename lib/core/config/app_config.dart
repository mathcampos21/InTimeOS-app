import 'package:flutter/foundation.dart';

/// Constantes globais do aplicativo InTimeOS.
abstract final class AppConfig {
  static const String appName = 'InTimeOS';
  static const String appSubtitle = 'In Time Technology';
  static const String appDescription = 'Sistema de Gestão e Ordens de Serviço — In Time Technology';
  static const String appVersion = '5.4.0';
  static const String apiPrefix = '/api/v1';

  /// Servidor padrão da In Time Technology para facilitar o acesso dos funcionários.
  static const String defaultServerUrl = 'https://itos.intimelab.com.br';

  /// Credenciais de Service Token do Cloudflare Access para o domínio itos.intimelab.com.br.
  /// Podem ser sobrescritas via --dart-define no build ou alteradas diretamente na tela de configurações do app.
  static const String defaultCfAccessClientId = String.fromEnvironment(
    'CF_ACCESS_CLIENT_ID',
    defaultValue: '8c0be79a1ad706f22491007dfc0ec8bb.access',
  );
  static const String defaultCfAccessClientSecret = String.fromEnvironment(
    'CF_ACCESS_CLIENT_SECRET',
    defaultValue: 'cfast_RmneBVDK7tK29YnbqKVrVvLtgNkcysxVGY6vscXEd216f191',
  );

  static const Duration requestTimeout = Duration(seconds: 20);
  static const int pageSize = 20;

  static const String projectUrl = 'https://itos.intimelab.com.br';
  static const String appSiteUrl = 'https://itos.intimelab.com.br';
  static const String supportEmail = 'suporte@intimelab.com.br';

  /// Normaliza a URL digitada pelo usuário:
  /// adiciona https://, remove barras finais e o sufixo /api/v1.
  static String normalizeBaseUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (kIsWeb && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.endsWith(apiPrefix)) {
      url = url.substring(0, url.length - apiPrefix.length);
    }
    return url;
  }
}
