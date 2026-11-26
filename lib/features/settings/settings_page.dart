import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/config/app_config.dart';
import '../../core/storage/session_store.dart';
import '../../core/widgets/ui.dart';
import '../about/about_page.dart';
import '../onboarding/onboarding_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _changeServer(BuildContext context, String currentUrl) async {
    final url = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnboardingPage(serverOnly: true, initialUrl: currentUrl),
      ),
    );
    if (url == null || !context.mounted) return;
    await context.read<AuthState>().setServer(url);
    if (context.mounted) {
      Toast.success(context, 'Servidor atualizado para $url');
    }
  }

  Future<void> _configureCloudflareAccess(BuildContext context) async {
    final auth = context.read<AuthState>();
    final idCtrl = TextEditingController(text: auth.cfAccessClientId);
    final secretCtrl = TextEditingController(text: auth.cfAccessClientSecret);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.sheetBottom(sheet) + Gaps.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cloudflare Access (Service Token)', style: sheet.text.titleLarge),
            const SizedBox(height: Gaps.xs),
            Text(
              'Informe o Client ID e o Client Secret gerados no painel Cloudflare Zero Trust para que o app atravesse a tela de validação por e-mail.',
              style: sheet.text.bodySmall,
            ),
            const SizedBox(height: Gaps.lg),
            AppTextField(
              controller: idCtrl,
              label: 'CF-Access-Client-Id',
              hint: 'xxxx.access',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: secretCtrl,
              label: 'CF-Access-Client-Secret',
              icon: Icons.key_outlined,
              obscure: true,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: Gaps.xl),
            Row(
              children: [
                if (auth.hasCfAccessToken) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await auth.setCfAccessCredentials(clientId: '', clientSecret: '');
                        if (sheet.mounted) Navigator.pop(sheet);
                        if (context.mounted) Toast.info(context, 'Service Token removido.');
                      },
                      child: const Text('Remover'),
                    ),
                  ),
                  const SizedBox(width: Gaps.md),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await auth.setCfAccessCredentials(
                        clientId: idCtrl.text,
                        clientSecret: secretCtrl.text,
                      );
                      if (sheet.mounted) Navigator.pop(sheet);
                      if (context.mounted) Toast.success(context, 'Service Token salvo.');
                    },
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Aparência', padding: EdgeInsets.fromLTRB(4, Gaps.sm, 4, Gaps.sm)),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Tema', style: context.text.titleSmall),
                      const SizedBox(height: Gaps.md),
                      SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Sistema')),
                          ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
                          ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Escuro')),
                        ],
                        selected: {theme.mode},
                        onSelectionChanged: (s) => theme.setMode(s.first),
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Conexão'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dns_outlined),
                        title: const Text('Servidor InTimeOS'),
                        subtitle: Text(auth.serverUrl ?? AppConfig.defaultServerUrl),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () => _changeServer(context, auth.serverUrl ?? AppConfig.defaultServerUrl),
                      ),
                      const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                      ListTile(
                        leading: const Icon(Icons.security_rounded),
                        title: const Text('Cloudflare Access (Zero Trust)'),
                        subtitle: Text(
                          auth.hasCfAccessToken
                              ? 'Service Token ativo (${auth.cfAccessClientId})'
                              : 'Não configurado · toque para informar o Service Token',
                        ),
                        trailing: const Icon(Icons.edit_outlined, size: 18),
                        onTap: () => _configureCloudflareAccess(context),
                      ),
                      const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                      ListTile(
                        leading: const Icon(Icons.cleaning_services_outlined),
                        title: const Text('Limpar dados offline'),
                        subtitle: const Text('Remove as informações salvas para uso sem internet'),
                        onTap: () async {
                          await context.read<SessionStore>().clearCache();
                          if (context.mounted) Toast.success(context, 'Dados offline removidos.');
                        },
                      ),
                    ],
                  ),
                ),
                const SectionHeader('Conta'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('Sobre o app'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
                      ),
                      const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                        title: const Text('Sair', style: TextStyle(color: AppColors.danger)),
                        subtitle: const Text('Para trocar de servidor, saia e entre novamente'),
                        onTap: () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'Sair da conta?',
                            message: 'Você precisará entrar novamente para acessar o app.',
                            confirmLabel: 'Sair',
                            destructive: true,
                          );
                          if (ok && context.mounted) await context.read<AuthState>().logout();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gaps.xl),
                Text('Versão ${AppConfig.appVersion}', style: context.text.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
