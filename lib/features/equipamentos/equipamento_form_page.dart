import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/ui.dart';
import '../../data/models/cliente.dart';
import '../../data/models/equipamento.dart';
import '../../data/repositories/cadastros_repository.dart';

class EquipamentoFormPage extends StatefulWidget {
  const EquipamentoFormPage({super.key, this.clienteId});

  final int? clienteId;

  @override
  State<EquipamentoFormPage> createState() => _EquipamentoFormPageState();
}

class _EquipamentoFormPageState extends State<EquipamentoFormPage> {
  final _form = GlobalKey<FormState>();

  int? _clienteId;
  String? _nomeCliente;
  final _equipamento = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _numSerie = TextEditingController();
  final _cor = TextEditingController();
  final _voltagem = TextEditingController();
  final _descricao = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _clienteId = widget.clienteId;
    if (_clienteId != null) {
      _loadClienteName();
    }
  }

  Future<void> _loadClienteName() async {
    try {
      final c = await context.read<ClientesRepository>().get(_clienteId!);
      if (mounted) setState(() => _nomeCliente = c.nome);
    } catch (_) {}
  }

  @override
  void dispose() {
    _equipamento.dispose();
    _marca.dispose();
    _modelo.dispose();
    _numSerie.dispose();
    _cor.dispose();
    _voltagem.dispose();
    _descricao.dispose();
    super.dispose();
  }

  Future<void> _selectCliente() async {
    final repo = context.read<ClientesRepository>();
    final selecionado = await showModalBottomSheet<Cliente>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ClienteSelectorSheet(repo: repo),
    );
    if (selecionado != null && mounted) {
      setState(() {
        _clienteId = selecionado.id;
        _nomeCliente = selecionado.nome;
      });
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_clienteId == null) {
      Toast.error(context, 'Selecione o cliente proprietário do equipamento.');
      return;
    }

    setState(() => _saving = true);
    try {
      final e = Equipamento(
        id: 0,
        clienteId: _clienteId!,
        equipamento: _equipamento.text.trim(),
        marca: _marca.text.trim().isEmpty ? null : _marca.text.trim(),
        modelo: _modelo.text.trim().isEmpty ? null : _modelo.text.trim(),
        numSerie: _numSerie.text.trim().isEmpty ? null : _numSerie.text.trim(),
        cor: _cor.text.trim().isEmpty ? null : _cor.text.trim(),
        voltagem: _voltagem.text.trim().isEmpty ? null : _voltagem.text.trim(),
        descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
      );

      await context.read<EquipamentosRepository>().create(e);
      if (mounted) {
        Toast.success(context, 'Equipamento salvo com sucesso!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) Toast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Equipamento')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(Gaps.lg),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cliente Proprietário *', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: Gaps.sm),
                  InkWell(
                    onTap: _selectCliente,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_search_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _nomeCliente ?? 'Toque para selecionar o cliente...',
                              style: TextStyle(
                                color: _nomeCliente != null ? context.colors.text : context.colors.muted,
                                fontWeight: _nomeCliente != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gaps.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Identificação do Equipamento', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: Gaps.md),
                  TextFormField(
                    controller: _equipamento,
                    decoration: const InputDecoration(
                      labelText: 'Equipamento / Tipo *',
                      hintText: 'Ex.: Notebook, Desktop, Impressora, Celular...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o tipo do equipamento.' : null,
                  ),
                  const SizedBox(height: Gaps.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _marca,
                          decoration: const InputDecoration(labelText: 'Marca', hintText: 'Ex.: Dell, HP, Apple'),
                        ),
                      ),
                      const SizedBox(width: Gaps.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _modelo,
                          decoration: const InputDecoration(labelText: 'Modelo', hintText: 'Ex.: Inspiron 15'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.md),
                  TextFormField(
                    controller: _numSerie,
                    decoration: const InputDecoration(
                      labelText: 'Número de Série (S/N)',
                      hintText: 'Ex.: BRJ982310',
                      prefixIcon: Icon(Icons.qr_code_rounded),
                    ),
                  ),
                  const SizedBox(height: Gaps.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cor,
                          decoration: const InputDecoration(labelText: 'Cor', hintText: 'Ex.: Prata, Preto'),
                        ),
                      ),
                      const SizedBox(width: Gaps.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _voltagem,
                          decoration: const InputDecoration(labelText: 'Voltagem', hintText: 'Ex.: Bivolt, 110V, 220V'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Gaps.md),
                  TextFormField(
                    controller: _descricao,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descrição / Configuração',
                      hintText: 'Processador, memória RAM, armazenamento, estado visual...',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gaps.xl),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Salvando...' : 'Salvar Equipamento'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClienteSelectorSheet extends StatefulWidget {
  const _ClienteSelectorSheet({required this.repo});
  final ClientesRepository repo;

  @override
  State<_ClienteSelectorSheet> createState() => _ClienteSelectorSheetState();
}

class _ClienteSelectorSheetState extends State<_ClienteSelectorSheet> {
  String _search = '';
  late Future<List<Cliente>> _future = widget.repo.list(search: '');

  void _onSearch(String text) {
    setState(() {
      _search = text;
      _future = widget.repo.list(search: text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(Gaps.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Selecionar Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: Gaps.sm),
          SearchField(hint: 'Buscar cliente...', onChanged: _onSearch),
          const SizedBox(height: Gaps.md),
          Expanded(
            child: FutureBuilder<List<Cliente>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data ?? [];
                if (list.isEmpty) {
                  return const EmptyView(
                    icon: Icons.person_off_rounded,
                    title: 'Nenhum cliente encontrado',
                    message: 'Tente outro termo de busca.',
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(c.documento ?? c.telefone ?? ''),
                      onTap: () => Navigator.pop(context, c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
