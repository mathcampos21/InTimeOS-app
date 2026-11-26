import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/equipamento.dart';
import '../../data/models/ordem_servico.dart';
import '../../data/repositories/cadastros_repository.dart';
import '../clientes/cliente_detail_page.dart';
import '../os/os_detail_page.dart';
import '../os/os_form_page.dart';
import '../os/widgets/os_card.dart';

class EquipamentoDetailPage extends StatefulWidget {
  const EquipamentoDetailPage({super.key, required this.equipamentoId});

  final int equipamentoId;

  @override
  State<EquipamentoDetailPage> createState() => _EquipamentoDetailPageState();
}

class _EquipamentoDetailPageState extends State<EquipamentoDetailPage> {
  late Future<Equipamento> _future = _load();

  Future<Equipamento> _load() =>
      context.read<EquipamentosRepository>().get(widget.equipamentoId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Equipamento>(
      future: _future,
      builder: (context, snap) {
        final e = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(e?.tituloCompleto ?? 'Equipamento'),
            actions: [
              if (e != null)
                IconButton(
                  icon: const Icon(Icons.add_task_rounded),
                  tooltip: 'Nova OS para este equipamento',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OsFormPage(
                          clienteId: e.clienteId,
                          equipamentoId: e.id,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          body: snap.hasError
              ? ErrorView(error: snap.error!, onRetry: () => setState(() => _future = _load()))
              : e == null
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async => setState(() => _future = _load()),
                      child: ListView(
                        padding: const EdgeInsets.all(Gaps.lg),
                        children: [
                          _buildHeaderCard(context, e),
                          const SizedBox(height: Gaps.md),
                          _buildDadosTecnicos(context, e),
                          const SizedBox(height: Gaps.md),
                          if ((e.nomeCliente ?? '').isNotEmpty) ...[
                            _buildClienteCard(context, e),
                            const SizedBox(height: Gaps.md),
                          ],
                          _buildHistoricoOs(context, e),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context, Equipamento e) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.devices_other_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: Gaps.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.equipamento,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if ((e.marca ?? '').isNotEmpty || (e.modelo ?? '').isNotEmpty)
                      Text(
                        [e.marca, e.modelo].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                        style: TextStyle(color: context.colors.muted, fontSize: 14),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if ((e.numSerie ?? '').isNotEmpty) ...[
            const SizedBox(height: Gaps.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'S/N: ${e.numSerie}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDadosTecnicos(BuildContext context, Equipamento e) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Especificações Técnicas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: Gaps.md),
          if ((e.cor ?? '').isNotEmpty) _item(context, 'Cor', e.cor!),
          if ((e.voltagem ?? '').isNotEmpty) _item(context, 'Voltagem', e.voltagem!),
          if (e.dataCadastro != null) _item(context, 'Cadastrado em', Fmt.apiDate(e.dataCadastro!)),
          if ((e.descricao ?? '').isNotEmpty) ...[
            const SizedBox(height: Gaps.sm),
            const Text('Descrição / Configuração:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(e.descricao!, style: TextStyle(color: context.colors.text)),
          ],
        ],
      ),
    );
  }

  Widget _buildClienteCard(BuildContext context, Equipamento e) {
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ClienteDetailPage(clienteId: e.clienteId)),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Proprietário / Cliente', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                Text(
                  e.nomeCliente ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if ((e.telefoneCliente ?? '').isNotEmpty || (e.celularCliente ?? '').isNotEmpty)
                  Text(
                    [e.celularCliente, e.telefoneCliente].whereType<String>().where((s) => s.isNotEmpty).first,
                    style: TextStyle(color: context.colors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.colors.muted),
        ],
      ),
    );
  }

  Widget _buildHistoricoOs(BuildContext context, Equipamento e) {
    final osList = e.ordensServicos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ordens de Serviço vinculadas (${osList.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        if (osList.isEmpty)
          const EmptyView(
            icon: Icons.history_rounded,
            title: 'Nenhuma OS encontrada',
            message: 'Este equipamento ainda não possui ordens de serviço cadastradas.',
          )
        else
          for (final item in osList)
            if (item is Map)
              Builder(builder: (context) {
                final os = OrdemServico.fromJson(Map<String, dynamic>.from(item));
                return Padding(
                  padding: const EdgeInsets.only(bottom: Gaps.sm),
                  child: OsCard(
                    os: os,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OsDetailPage(osId: os.id)),
                      );
                    },
                  ),
                );
              }),
      ],
    );
  }

  Widget _item(BuildContext context, String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rotulo, style: TextStyle(color: context.colors.muted, fontSize: 13)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
