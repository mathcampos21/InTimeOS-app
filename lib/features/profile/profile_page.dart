import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/utils/input_masks.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/conta.dart';
import '../../data/repositories/cadastros_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<(Usuario, Emitente?)> _future = _load();

  Future<(Usuario, Emitente?)> _load() async {
    final repo = context.read<ContaRepository>();
    final u = await repo.perfil();
    Emitente? e;
    try {
      e = await repo.emitente();
    } catch (_) {}
    return (u, e);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _editProfile(Usuario u) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EditProfileSheet(usuario: u),
    );
    if (saved == true && mounted) _reload();
  }

  Future<void> _changePassword(Usuario u) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ChangePasswordSheet(usuario: u),
    );
    if (changed == true && mounted) {
      Toast.success(context, 'Senha alterada com sucesso! Faça login novamente.');
      await context.read<AuthState>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: AsyncView<(Usuario, Emitente?)>(
        future: _future,
        onRetry: _reload,
        builder: (context, data) {
          final (u, e) = data;
          return ListView(
            padding: Gaps.pageOf(context),
            children: [
              ContentWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: Gaps.lg),
                    Center(child: InitialsAvatar(u.nome, size: 96, imageUrl: u.fotoUrl)),
                    const SizedBox(height: Gaps.lg),
                    Text(u.nome, style: context.text.headlineSmall, textAlign: TextAlign.center),
                    Text(u.email, style: context.text.bodyMedium?.copyWith(color: context.tokens.muted), textAlign: TextAlign.center),
                    const SizedBox(height: Gaps.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _editProfile(u),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Editar dados'),
                        ),
                        const SizedBox(width: Gaps.sm),
                        OutlinedButton.icon(
                          onPressed: () => _changePassword(u),
                          icon: const Icon(Icons.key_outlined, size: 18),
                          label: const Text('Trocar senha'),
                        ),
                      ],
                    ),
                    const SectionHeader('Dados pessoais'),
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.xs),
                      child: Column(
                        children: [
                          InfoRow(icon: Icons.badge_outlined, label: 'CPF', value: u.cpf),
                          InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: u.telefone),
                          InfoRow(icon: Icons.smartphone_outlined, label: 'Celular', value: u.celular),
                          InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Cidade',
                            value: [u.cidade, u.estado].where((s) => s.isNotEmpty).join(' / '),
                          ),
                          InfoRow(
                            icon: Icons.event_available_outlined,
                            label: 'Acesso válido até',
                            value: u.dataExpiracao == null || u.dataExpiracao!.year >= 2999 ? 'Sem expiração' : Fmt.date(u.dataExpiracao),
                          ),
                        ],
                      ),
                    ),
                    if (e != null && e.nome.isNotEmpty) ...[
                      const SectionHeader('Empresa'),
                      AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.xs),
                        child: Column(
                          children: [
                            InfoRow(icon: Icons.storefront_outlined, label: 'Razão social', value: e.nome),
                            InfoRow(icon: Icons.description_outlined, label: 'CNPJ', value: e.cnpj),
                            InfoRow(icon: Icons.phone_outlined, label: 'Telefone', value: e.telefone),
                            InfoRow(icon: Icons.mail_outline_rounded, label: 'E-mail', value: e.email),
                            InfoRow(
                              icon: Icons.location_city_outlined,
                              label: 'Cidade',
                              value: [e.cidade, e.uf].where((s) => s.isNotEmpty).join(' / '),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.usuario});

  final Usuario usuario;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario.nome);
  late final _email = TextEditingController(text: widget.usuario.email);
  late final _celular = TextEditingController(text: widget.usuario.celular);
  late final _telefone = TextEditingController(text: widget.usuario.telefone);
  late final _cpf = TextEditingController(text: widget.usuario.cpf);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nome, _email, _celular, _telefone, _cpf]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final u = widget.usuario;
    final updated = Usuario(
      id: u.id,
      nome: _nome.text.trim(),
      email: _email.text.trim(),
      celular: _celular.text.trim(),
      telefone: _telefone.text.trim(),
      cpf: _cpf.text.trim(),
      rg: u.rg,
      cep: u.cep,
      rua: u.rua,
      numero: u.numero,
      bairro: u.bairro,
      cidade: u.cidade,
      estado: u.estado,
      fotoUrl: u.fotoUrl,
      dataExpiracao: u.dataExpiracao,
    );
    try {
      await context.read<ContaRepository>().updatePerfil(updated);
      if (!mounted) return;
      Toast.success(context, 'Perfil atualizado com sucesso!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.sheetBottom(context) + Gaps.xl),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Editar dados do perfil', style: context.text.titleLarge),
            const SizedBox(height: Gaps.lg),
            AppTextField(
              controller: _nome,
              label: 'Nome completo',
              icon: Icons.person_outline_rounded,
              validator: (v) => Validators.required(v, 'Nome'),
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _email,
              label: 'E-mail',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.requiredEmail,
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _celular,
              label: 'Celular',
              icon: Icons.smartphone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [PatternMask.phone()],
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _telefone,
              label: 'Telefone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [PatternMask.phone()],
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _cpf,
              label: 'CPF',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [PatternMask.cpfCnpj()],
            ),
            const SizedBox(height: Gaps.xl),
            LoadingButton(label: 'Salvar alterações', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet({required this.usuario});

  final Usuario usuario;

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _form = GlobalKey<FormState>();
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirma = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<ContaRepository>().updatePerfil(
            widget.usuario,
            senhaAtual: _atual.text,
            novaSenha: _nova.text,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) Toast.error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(Gaps.xl, 0, Gaps.xl, Gaps.sheetBottom(context) + Gaps.xl),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Alterar senha', style: context.text.titleLarge),
            const SizedBox(height: Gaps.xs),
            Text(
              'Por segurança, alterar a senha encerrará a sessão atual para renovar o acesso.',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: Gaps.lg),
            AppTextField(
              controller: _atual,
              label: 'Senha atual',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              validator: (v) => Validators.required(v, 'Senha atual'),
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _nova,
              label: 'Nova senha (mín. 8 caracteres)',
              icon: Icons.key_outlined,
              obscure: true,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Nova senha é obrigatória';
                if (v.length < 8) return 'A nova senha deve ter no mínimo 8 caracteres';
                return null;
              },
            ),
            const SizedBox(height: Gaps.md),
            AppTextField(
              controller: _confirma,
              label: 'Confirmar nova senha',
              icon: Icons.key_outlined,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: (v) => v != _nova.text ? 'As senhas não conferem' : null,
            ),
            const SizedBox(height: Gaps.xl),
            LoadingButton(label: 'Alterar senha', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
