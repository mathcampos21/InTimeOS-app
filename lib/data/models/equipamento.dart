import '../../core/utils/formatters.dart';

class Equipamento {
  const Equipamento({
    required this.id,
    required this.clienteId,
    required this.equipamento,
    this.nomeCliente,
    this.documentoCliente,
    this.telefoneCliente,
    this.celularCliente,
    this.marca,
    this.modelo,
    this.numSerie,
    this.cor,
    this.voltagem,
    this.descricao,
    this.dataCadastro,
    this.totalOs = 0,
    this.ordensServicos = const [],
  });

  final int id;
  final int clienteId;
  final String equipamento;
  final String? nomeCliente;
  final String? documentoCliente;
  final String? telefoneCliente;
  final String? celularCliente;
  final String? marca;
  final String? modelo;
  final String? numSerie;
  final String? cor;
  final String? voltagem;
  final String? descricao;
  final DateTime? dataCadastro;
  final int totalOs;
  final List<dynamic> ordensServicos;

  String get tituloCompleto {
    final partes = [equipamento];
    if ((marca ?? '').isNotEmpty) partes.add(marca!);
    if ((modelo ?? '').isNotEmpty) partes.add(modelo!);
    return partes.join(' · ');
  }

  String get detalhesResumo {
    final partes = <String>[];
    if ((numSerie ?? '').isNotEmpty) partes.add('S/N: $numSerie');
    if ((cor ?? '').isNotEmpty) partes.add(cor!);
    if ((voltagem ?? '').isNotEmpty) partes.add(voltagem!);
    return partes.join(' · ');
  }

  factory Equipamento.fromJson(Map<String, dynamic> j) {
    return Equipamento(
      id: asInt(j['idEquipamentos']),
      clienteId: asInt(j['clientes_id']),
      equipamento: (j['equipamento'] ?? '').toString().trim(),
      nomeCliente: j['nomeCliente']?.toString().trim(),
      documentoCliente: j['documentoCliente']?.toString().trim(),
      telefoneCliente: j['telefoneCliente']?.toString().trim(),
      celularCliente: j['celularCliente']?.toString().trim(),
      marca: j['marca']?.toString().trim(),
      modelo: j['modelo']?.toString().trim(),
      numSerie: j['num_serie']?.toString().trim(),
      cor: j['cor']?.toString().trim(),
      voltagem: j['voltagem']?.toString().trim(),
      descricao: j['descricao']?.toString().trim(),
      dataCadastro: asDate(j['data_cadastro']?.toString()),
      totalOs: asInt(j['total_os']),
      ordensServicos: j['ordensServicos'] is List ? (j['ordensServicos'] as List) : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'idEquipamentos': id,
        'clientes_id': clienteId,
        'equipamento': equipamento,
        'marca': marca,
        'modelo': modelo,
        'num_serie': numSerie,
        'cor': cor,
        'voltagem': voltagem,
        'descricao': descricao,
      };
}
