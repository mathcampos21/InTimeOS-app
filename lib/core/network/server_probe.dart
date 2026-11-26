import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Onde o MAP-OS do usuário roda. Define o protocolo usado.
enum ServerMode {
  /// Na internet (hospedagem/VPS) — sempre HTTPS.
  hosted,

  /// Na rede da empresa (IP local, XAMPP, etc.) — HTTP.
  local,
}

/// Resultado do teste de conexão com o servidor.
class ProbeResult {
  const ProbeResult._({
    required this.ok,
    required this.url,
    required this.title,
    required this.message,
    this.elapsed,
    this.tips = const [],
    this.cloudflareAccessBlocked = false,
  });

  final bool ok;
  final String url;
  final String title;
  final String message;
  final Duration? elapsed;
  final List<String> tips;
  final bool cloudflareAccessBlocked;

  factory ProbeResult.success(String url, Duration elapsed, {bool viaCloudflareAccess = false}) =>
      ProbeResult._(
        ok: true,
        url: url,
        title: 'Conexão estabelecida!',
        message: viaCloudflareAccess
            ? 'API do InTimeOS autenticada via Cloudflare Access em ${elapsed.inMilliseconds} ms.'
            : 'Encontramos a API do InTimeOS em ${elapsed.inMilliseconds} ms.',
        elapsed: elapsed,
      );

  factory ProbeResult.fail(
    String url,
    String title,
    String message, [
    List<String> tips = const [],
    bool cloudflareAccessBlocked = false,
  ]) =>
      ProbeResult._(
        ok: false,
        url: url,
        title: title,
        message: message,
        tips: tips,
        cloudflareAccessBlocked: cloudflareAccessBlocked,
      );
}

/// Testa se uma URL aponta para uma API MAP-OS acessível.
///
/// Faz um POST em `/api/v1/login` com credenciais vazias: o MAP-OS sempre
/// responde com o envelope JSON `{status, message}` (recusando o login), o que
/// confirma que o servidor existe, responde e é de fato um MAP-OS.
abstract final class ServerProbe {
  static const Duration timeout = Duration(seconds: 12);

  /// Monta a URL base a partir do que o usuário digitou + o tipo de servidor.
  /// Qualquer protocolo digitado é descartado: quem manda é o [mode].
  static String buildUrl(String input, ServerMode mode) {
    var s = input.trim().replaceFirst(RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://'), '');
    s = _trimSlashes(s);
    if (s.endsWith(AppConfig.apiPrefix)) {
      s = _trimSlashes(s.substring(0, s.length - AppConfig.apiPrefix.length));
    }
    if (s.isEmpty) return '';
    return '${mode == ServerMode.local ? 'http' : 'https'}://$s';
  }

  /// Valida o formato antes de testar. Retorna a mensagem de erro ou null.
  static String? validate(String input, ServerMode mode) {
    final url = buildUrl(input, mode);
    if (url.isEmpty) return 'Informe o endereço do servidor.';
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty || url.contains(' ')) {
      return 'Endereço inválido. Ex.: ${mode == ServerMode.local ? '192.168.0.10:18080' : 'itos.intimelab.com.br'}';
    }
    return null;
  }

  /// Aviso para quem digita "localhost" no celular.
  static String? localhostWarning(String input, ServerMode mode) {
    final host = Uri.tryParse(buildUrl(input, mode))?.host ?? '';
    if (host == 'localhost' || host.startsWith('127.')) {
      return 'No celular, "localhost" é o próprio celular. Use o IP do computador que roda o InTimeOS (ex.: 192.168.0.10:18080).';
    }
    return null;
  }

  static Future<ProbeResult> test(
    String baseUrl, {
    String? cfClientId,
    String? cfClientSecret,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final local = baseUrl.startsWith('http://');
    final id = (cfClientId ?? '').trim();
    final secret = (cfClientSecret ?? '').trim();
    final hasCfToken = id.isNotEmpty && secret.isNotEmpty;
    final sw = Stopwatch()..start();
    try {
      final res = await c
          .post(
            Uri.parse('$baseUrl${AppConfig.apiPrefix}/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'App-Version': AppConfig.appVersion,
              if (hasCfToken) ...{
                'CF-Access-Client-Id': id,
                'CF-Access-Client-Secret': secret,
              },
            },
            body: jsonEncode({'email': '', 'password': ''}),
          )
          .timeout(timeout);
      sw.stop();
      return _classify(baseUrl, res, sw.elapsed, hasCfToken: hasCfToken);
    } on TimeoutException {
      return ProbeResult.fail(
        baseUrl,
        'O servidor não respondeu',
        'Esperamos ${timeout.inSeconds}s e não tivemos resposta.',
        local ? _localTips : _hostedTips,
      );
    } catch (e) {
      return _classifyError(baseUrl, e.toString(), local);
    } finally {
      if (client == null) c.close();
    }
  }

  static bool _isCloudflareAccessBlock(http.Response res) {
    final loc = (res.headers['location'] ?? '').toLowerCase();
    if (loc.contains('/cdn-cgi/access/login') || loc.contains('.cloudflareaccess.com')) {
      return true;
    }
    try {
      final raw = utf8.decode(res.bodyBytes, allowMalformed: true).toLowerCase();
      if (raw.contains('cloudflareaccess.com') ||
          raw.contains('/cdn-cgi/access/') ||
          raw.contains('cf-access-domain') ||
          raw.contains('cloudflare access')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static ProbeResult _classify(String url, http.Response res, Duration elapsed, {bool hasCfToken = false}) {
    final code = res.statusCode;

    if (_isCloudflareAccessBlock(res)) {
      return ProbeResult.fail(
        url,
        hasCfToken ? 'Service Token do Cloudflare recusado' : 'Protegido por Cloudflare Access',
        hasCfToken
            ? 'O Cloudflare Access bloqueou a requisição mesmo com o Service Token informado.'
            : 'Este servidor exige autenticação pelo Cloudflare Zero Trust antes de acessar a API.',
        hasCfToken
            ? const [
                'Confira se o Client ID e o Client Secret estão corretos.',
                'No painel Cloudflare Zero Trust (Access → Applications), adicione uma política com Action = "Service Auth" incluindo este Service Token.',
              ]
            : const [
                'Ative a opção "Proteção Cloudflare Access" abaixo e informe o Client ID e o Client Secret do Service Token.',
                'Ou crie uma política Service Auth / Bypass para "/api/v1/*" no painel Cloudflare Zero Trust.',
              ],
        true,
      );
    }

    // Redirecionamento (POST não segue automaticamente).
    if (code >= 300 && code < 400) {
      final location = res.headers['location'] ?? '';
      if (url.startsWith('http://') && location.startsWith('https://')) {
        return ProbeResult.fail(
          url,
          'Esse servidor usa HTTPS',
          'O servidor redirecionou para uma conexão segura.',
          const ['Volte e escolha a opção "Hospedado (HTTPS)".'],
        );
      }
      return ProbeResult.fail(
        url,
        'O servidor redirecionou a requisição',
        location.isEmpty ? 'Recebemos um redirecionamento (HTTP $code).' : 'Redirecionado para: $location',
        const ['Use o endereço final do InTimeOS, exatamente como aparece no navegador.'],
      );
    }

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {
      // Corpo não é JSON (HTML, vazio...) — tratado abaixo.
    }

    if (body != null && body.containsKey('status')) {
      final msg = (body['message'] ?? '').toString().toLowerCase();
      if (msg.contains('desabilitad') || msg.contains('disabled')) {
        return ProbeResult.fail(
          url,
          'API desativada',
          'Encontramos o InTimeOS, mas a API dele está desativada.',
          const ['Peça ao administrador para ativar a API nas configurações do InTimeOS.'],
        );
      }
      return ProbeResult.success(url, elapsed, viaCloudflareAccess: hasCfToken);
    }

    if (code == 404) {
      return ProbeResult.fail(
        url,
        'API do InTimeOS não encontrada',
        'O servidor respondeu, mas não encontramos a API habilitada nesse endereço.',
        const [
          'Confira se o caminho está completo (ex.: itos.intimelab.com.br).',
          'Abra o endereço no navegador: deve aparecer a tela de login do InTimeOS.',
          'Verifique se a API está ativada (API_ENABLED=true nas configurações do sistema).',
        ],
      );
    }

    if (code >= 500) {
      return ProbeResult.fail(
        url,
        'Erro no servidor (HTTP $code)',
        'O servidor foi encontrado, mas falhou ao processar a requisição.',
        const ['Verifique os logs do servidor ou a chave JWT (API_JWT_KEY) nas configurações do sistema.'],
      );
    }

    return ProbeResult.fail(
      url,
      'Servidor incompatível',
      'O servidor respondeu (HTTP $code), mas não com a API do InTimeOS.',
      const [
        'Confira se o endereço aponta para o servidor InTimeOS.',
        'Abra o endereço no navegador: deve aparecer a tela de login do InTimeOS.',
      ],
    );
  }

  static ProbeResult _classifyError(String url, String error, bool local) {
    final e = error.toLowerCase();

    if (e.contains('handshake') || e.contains('certificate') || e.contains('wrong_version_number')) {
      return ProbeResult.fail(
        url,
        'Problema com o certificado SSL',
        'Não foi possível criar uma conexão segura (HTTPS) com o servidor.',
        const [
          'Se o servidor não tem certificado SSL, escolha "Local (HTTP)".',
          'Se tem, verifique se o certificado está válido e não expirou.',
        ],
      );
    }

    if (e.contains('failed host lookup') || e.contains('no address associated')) {
      return ProbeResult.fail(
        url,
        'Endereço não encontrado',
        'Não conseguimos encontrar esse domínio.',
        const [
          'Confira se o endereço foi digitado corretamente.',
          'Verifique se o celular está conectado à internet.',
        ],
      );
    }

    if (e.contains('connection refused')) {
      return ProbeResult.fail(
        url,
        'Conexão recusada',
        'O endereço existe, mas nada respondeu nessa porta.',
        local
            ? const [
                'Verifique se o Apache/servidor web está rodando.',
                'Se usa porta diferente de 80, informe-a (ex.: 192.168.0.10:8080/mapos).',
                'Libere a porta no firewall do computador.',
              ]
            : const ['Verifique se o servidor está no ar e a porta está correta.'],
      );
    }

    if (e.contains('xmlhttprequest') || e.contains('failed to fetch')) {
      return ProbeResult.fail(
        url,
        'Acesso bloqueado pelo navegador',
        'O navegador bloqueou a conexão com o servidor.',
        const ['Verifique se o InTimeOS permite acesso externo (CORS) e usa HTTPS.'],
      );
    }

    return ProbeResult.fail(
      url,
      'Não foi possível conectar',
      'O servidor não pôde ser alcançado.',
      local ? _localTips : _hostedTips,
    );
  }

  static const _localTips = [
    'O celular precisa estar na mesma rede Wi-Fi do servidor.',
    'Use o IP do computador (ex.: 192.168.0.10), não "localhost".',
    'Verifique se o firewall libera a porta do servidor web.',
  ];

  static const _hostedTips = [
    'Verifique se o celular está conectado à internet.',
    'Confira se o endereço está correto e o site está no ar.',
  ];

  static String _trimSlashes(String s) {
    var r = s;
    while (r.endsWith('/')) {
      r = r.substring(0, r.length - 1);
    }
    return r;
  }
}
