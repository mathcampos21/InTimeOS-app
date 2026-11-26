import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/widgets/ui.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) Toast.error(context, 'Não foi possível abrir o link.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        padding: Gaps.pageOf(context),
        children: [
          ContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(Gaps.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDeep]),
                    borderRadius: BorderRadius.circular(Gaps.radiusLg),
                  ),
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo-two.png', height: 56),
                      const SizedBox(height: Gaps.md),
                      Text(
                        '${AppConfig.appName} Mobile',
                        style: context.text.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: Gaps.xs),
                      Text(
                        AppConfig.appDescription,
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: Gaps.md),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'v${AppConfig.appVersion}',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader('In Time Technology'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const IconBadge(Icons.public_rounded, color: AppColors.accent, size: 36),
                        title: const Text('Painel Web InTimeOS'),
                        subtitle: const Text('itos.intimelab.com.br'),
                        trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                        onTap: () => _open(context, AppConfig.appSiteUrl),
                      ),
                      const Divider(indent: Gaps.lg, endIndent: Gaps.lg),
                      const ListTile(
                        leading: IconBadge(Icons.verified_user_outlined, color: AppColors.servicos, size: 36),
                        title: Text('Uso exclusivo de colaboradores'),
                        subtitle: Text('Sincronizado em tempo real com a operação técnica da In Time Technology'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Gaps.xl),
                Text(
                  '© ${DateTime.now().year} In Time Technology · InTimeOS v${AppConfig.appVersion}',
                  style: context.text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
