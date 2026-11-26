import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/equipamento.dart';
import '../../data/repositories/cadastros_repository.dart';
import 'equipamento_detail_page.dart';
import 'equipamento_form_page.dart';

class EquipamentosPage extends StatefulWidget {
  const EquipamentosPage({super.key, this.clienteId});

  final int? clienteId;

  @override
  State<EquipamentosPage> createState() => _EquipamentosPageState();
}

class _EquipamentosPageState extends State<EquipamentosPage> {
  late final PagedController<Equipamento> _ctrl = PagedController(
    fetch: (page, search) => context.read<EquipamentosRepository>().list(
          page: page,
          search: search,
          clienteId: widget.clienteId,
        ),
  )..refresh();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => page));
    if (changed == true) _ctrl.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final canAdd = auth.permissions.canAdd('Cliente') || auth.permissions.canAdd('Os');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clienteId != null ? 'Equipamentos do Cliente' : 'Equipamentos'),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _open(EquipamentoFormPage(clienteId: widget.clienteId)),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Novo Equipamento'),
            )
          : null,
      body: PagedListView<Equipamento>(
        controller: _ctrl,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(Gaps.lg, 0, Gaps.lg, Gaps.sm),
          child: ContentWidthScroll(
            child: SearchField(
              hint: 'Buscar por modelo, marca, S/N, cliente...',
              onChanged: _ctrl.setSearch,
            ),
          ),
        ),
        empty: (searching) => EmptyView(
          icon: Icons.devices_other_rounded,
          title: searching ? 'Nenhum equipamento encontrado' : 'Nenhum equipamento cadastrado',
          message: searching
              ? 'Tente outro modelo, marca ou número de série.'
              : 'Cadastre o primeiro equipamento para vincular às ordens de serviço.',
        ),
        itemBuilder: (context, e) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: Gaps.lg, vertical: Gaps.md),
          onTap: () => _open(EquipamentoDetailPage(equipamentoId: e.id)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.devices_other_rounded, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: Gaps.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.tituloCompleto,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if ((e.nomeCliente ?? '').isNotEmpty)
                      Text(
                        e.nomeCliente!,
                        style: TextStyle(color: context.tokens.muted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (e.detalhesResumo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        e.detalhesResumo,
                        style: const TextStyle(
                          color: AppColors.accentBright,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (e.totalOs > 0) ...[
                const SizedBox(width: Gaps.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.tokens.subtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.tokens.border),
                  ),
                  child: Text(
                    '${e.totalOs} OS',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              const SizedBox(width: Gaps.xs),
              Icon(Icons.chevron_right_rounded, color: context.tokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}
