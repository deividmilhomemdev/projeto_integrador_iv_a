import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../services/database.dart';

class AbaRelatorios extends StatefulWidget {
  const AbaRelatorios({super.key});

  @override
  State<AbaRelatorios> createState() => _AbaRelatoriosState();
}

class _AbaRelatoriosState extends State<AbaRelatorios> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _dadosBrutos = [];

  late DateTime _dataInicio;
  late DateTime _dataFim;
  int? _idVoluntariaSelecionada;

  // Variável para armazenar o número real de voluntárias na plataforma
  int _totalVoluntariasCadastradas = 0;

  @override
  void initState() {
    super.initState();
    _definirMesAtual();
    _carregarDados();
  }

  void _definirMesAtual() {
    final hoje = DateTime.now();
    _dataInicio = DateTime(hoje.year, hoje.month, 1);
    _dataFim = DateTime(hoje.year, hoje.month + 1, 0, 23, 59, 59);
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final db = DatabaseService();

    try {
      // Carrega em paralelo os relatórios e o número real de voluntárias
      final dados = await db.getDadosRelatorioCompleto();
      final totalVols = await db.getTotalVoluntarias();

      if (mounted) {
        setState(() {
          _dadosBrutos = dados;
          _totalVoluntariasCadastradas = totalVols; // Alimenta a nova variável
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao carregar dados do relatório: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('pt', 'BR'), // A MÁGICA DO IDIOMA BRASILEIRO AQUI! 🇧🇷
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _dataInicio, end: _dataFim),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6A1B9A),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dataInicio = picked.start;
        _dataFim = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  Map<String, int> _calcularIndicadores(List<Map<String, dynamic>> dadosFiltrados) {
    int atendimentosPeriodo = 0;
    int atendimentosAno = 0;
    final assistidasUnicas = <int>{};

    final anoAtual = DateTime.now().year;

    for (var assistida in dadosFiltrados) {
      assistidasUnicas.add(assistida['id_assistida']);

      final sessoes = List<Map<String, dynamic>>.from(assistida['tb_sessao'] ?? []);
      for (var sessao in sessoes) {
        if (sessao['indicador_desistencia'] == '1') continue;

        if (sessao['indicador_sessao_realizada'] == '1') {
          final dataSessao = DateTime.parse(sessao['data_sessao']);

          if (dataSessao.year == anoAtual) atendimentosAno++;

          if (dataSessao.isAfter(_dataInicio.subtract(const Duration(days: 1))) &&
              dataSessao.isBefore(_dataFim.add(const Duration(days: 1)))) {
            atendimentosPeriodo++;
          }
        }
      }
    }

    return {
      'atendimentos_periodo': atendimentosPeriodo,
      'atendimentos_ano': atendimentosAno,
      'assistidas_registradas': assistidasUnicas.length,
    };
  }

  Future<void> _exportarParaCSV(List<Map<String, dynamic>> linhasTabela) async {
    List<List<dynamic>> csvData = [];
    final dataExtracao = "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}";

    csvData.add(["Relatório Extraído em:", dataExtracao, "", "", "", "", "", "", "", ""]);
    csvData.add(["Período Selecionado:", "${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year} até ${_dataFim.day}/${_dataFim.month}/${_dataFim.year}", "", "", "", "", "", "", "", ""]);
    csvData.add([]);

    csvData.add([
      "Nome da Voluntária",
      "ID Voluntária",
      "ID Assistida",
      "Contato",
      "Data Agendamento",
      "Data Realização",
      "Nome da Assistida",
      "Atendimentos no Período",
      "Atendimentos no Ano",
      "Atendimentos Pendentes"
    ]);

    for (var row in linhasTabela) {
      csvData.add([
        row['nome_voluntaria'],
        row['id_voluntaria'],
        row['id_assistida'],
        row['contato'],
        row['data_agendamento'],
        row['data_realizacao'],
        row['nome_assistida'],
        row['atend_periodo'],
        row['atend_ano'],
        row['pendentes']
      ]);
    }

    String csvStr = const ListToCsvConverter().convert(csvData);

    final bytes = utf8.encode('\uFEFF$csvStr');
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "Relatorio_Ouvidoria_${DateTime.now().millisecondsSinceEpoch}.csv")
      ..click();

    html.Url.revokeObjectUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Download do arquivo iniciado! Verifique seus downloads. 📊"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A)));
    }

    var dadosFiltrados = _dadosBrutos;
    if (_idVoluntariaSelecionada != null) {
      dadosFiltrados = dadosFiltrados.where((a) =>
      a['tb_usuario'] != null && a['tb_usuario']['id_usuario'] == _idVoluntariaSelecionada
      ).toList();
    }

    final kpis = _calcularIndicadores(dadosFiltrados);

    final mapVoluntarias = <int, String>{};
    for (var a in _dadosBrutos) {
      if (a['tb_usuario'] != null) {
        mapVoluntarias[a['tb_usuario']['id_usuario']] = a['tb_usuario']['nome_usuario'];
      }
    }
    final listaVoluntarias = mapVoluntarias.entries.toList();
    listaVoluntarias.sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    final anoAtual = DateTime.now().year;
    List<Map<String, dynamic>> linhasTabela = [];

    for (var assistida in dadosFiltrados) {
      final sessoes = List<Map<String, dynamic>>.from(assistida['tb_sessao'] ?? []);

      int atendPeriodo = 0;
      int atendAno = 0;
      int pendentes = 0;

      List<Map<String, dynamic>> sessoesValidas = [];

      for (var sessao in sessoes) {
        if (sessao['indicador_desistencia'] == '1') continue;

        sessoesValidas.add(sessao);
        final dataSessao = DateTime.parse(sessao['data_sessao']);
        bool isRealizada = sessao['indicador_sessao_realizada'] == '1';

        if (isRealizada) {
          if (dataSessao.year == anoAtual) atendAno++;
          if (dataSessao.isAfter(_dataInicio.subtract(const Duration(days: 1))) &&
              dataSessao.isBefore(_dataFim.add(const Duration(days: 1)))) {
            atendPeriodo++;
          }
        } else {
          pendentes++;
        }
      }

      String nomeVol = assistida['tb_usuario']?['nome_usuario'] ?? 'Sem Vínculo';
      String idVol = assistida['tb_usuario']?['id_usuario']?.toString() ?? '-';
      String idAssistida = assistida['id_assistida'].toString();
      String nomeAssistida = assistida['nome'] ?? 'Desconhecida';
      String contato = assistida['contato'] ?? '-';

      if (sessoesValidas.isEmpty) {
        linhasTabela.add({
          'nome_voluntaria': nomeVol,
          'id_voluntaria': idVol,
          'id_assistida': idAssistida,
          'contato': contato,
          'data_agendamento': '-',
          'data_realizacao': '-',
          'nome_assistida': nomeAssistida,
          'atend_periodo': 0,
          'atend_ano': 0,
          'pendentes': 0,
          '_data_sort': DateTime(1900),
        });
      } else {
        for (var sessao in sessoesValidas) {
          final dataSessao = DateTime.parse(sessao['data_sessao']);
          final dataFormatada = "${dataSessao.day.toString().padLeft(2,'0')}/${dataSessao.month.toString().padLeft(2,'0')}/${dataSessao.year}";
          final isRealizada = sessao['indicador_sessao_realizada'] == '1';

          linhasTabela.add({
            'nome_voluntaria': nomeVol,
            'id_voluntaria': idVol,
            'id_assistida': idAssistida,
            'contato': contato,
            'data_agendamento': dataFormatada,
            'data_realizacao': isRealizada ? dataFormatada : '-',
            'nome_assistida': nomeAssistida,
            'atend_periodo': atendPeriodo,
            'atend_ano': atendAno,
            'pendentes': pendentes,
            '_data_sort': isRealizada ? dataSessao : DateTime(1900),
          });
        }
      }
    }

    linhasTabela.sort((a, b) {
      int cmpVoluntaria = a['nome_voluntaria'].toString().toLowerCase().compareTo(b['nome_voluntaria'].toString().toLowerCase());
      if (cmpVoluntaria != 0) return cmpVoluntaria;

      int cmpAssistida = a['nome_assistida'].toString().toLowerCase().compareTo(b['nome_assistida'].toString().toLowerCase());
      if (cmpAssistida != 0) return cmpAssistida;

      DateTime dataA = a['_data_sort'];
      DateTime dataB = b['_data_sort'];
      return dataB.compareTo(dataA);
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _selecionarPeriodo,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  "Período: ${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year} - ${_dataFim.day}/${_dataFim.month}/${_dataFim.year}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _exportarParaCSV(linhasTabela),
                icon: const Icon(Icons.file_download),
                label: const Text("Exportar CSV"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = (constraints.maxWidth / 2) - 8;
                if (constraints.maxWidth > 600) cardWidth = (constraints.maxWidth / 4) - 12;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildKpiCard("Atendimentos (Período)", kpis['atendimentos_periodo'].toString(), Colors.blue, cardWidth),
                    _buildKpiCard("Atendimentos (Ano)", kpis['atendimentos_ano'].toString(), Colors.teal, cardWidth),
                    // MUDANÇA AQUI: Renderiza o KPI baseado na contagem real do banco!
                    _buildKpiCard("Voluntárias Cadastradas", _totalVoluntariasCadastradas.toString(), const Color(0xFF6A1B9A), cardWidth),
                    _buildKpiCard("Assistidas (Únicas)", kpis['assistidas_registradas'].toString(), Colors.orange, cardWidth),
                  ],
                );
              }
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                const Text("Buscar Voluntária:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _idVoluntariaSelecionada,
                      hint: const Text("Selecione para filtrar..."),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text("Exibir Todas", style: TextStyle(fontStyle: FontStyle.italic)),
                        ),
                        ...listaVoluntarias.map((e) => DropdownMenuItem<int>(
                          value: e.key,
                          child: Text(e.value),
                        )),
                      ],
                      onChanged: (val) {
                        setState(() => _idVoluntariaSelecionada = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.swipe_outlined, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  "Mova lateralmente para ver mais dados",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                    columns: const [
                      DataColumn(label: Text("Voluntária", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("ID Assistida", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Contato", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Data Agend.", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Data Realiz.", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Assistida", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Atend. Período", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Atend. Ano", style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text("Pendentes", style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: linhasTabela.map((row) {
                      return DataRow(cells: [
                        DataCell(Text(row['nome_voluntaria'].toString())),
                        DataCell(Text(row['id_voluntaria'].toString())),
                        DataCell(Text(row['id_assistida'].toString())),
                        DataCell(Text(row['contato'].toString())),
                        DataCell(Center(child: Text(row['data_agendamento'].toString()))),
                        DataCell(Center(child: Text(row['data_realizacao'].toString()))),
                        DataCell(Text(row['nome_assistida'].toString())),
                        DataCell(Center(child: Text(row['atend_periodo'].toString()))),
                        DataCell(Center(child: Text(row['atend_ano'].toString()))),
                        DataCell(Center(
                          child: Text(
                            row['pendentes'].toString(),
                            style: TextStyle(
                              color: row['pendentes'] > 0 ? Colors.red : Colors.black,
                              fontWeight: row['pendentes'] > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String titulo, String valor, Color cor, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.05),
        border: Border.all(color: cor.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(valor, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: cor)),
        ],
      ),
    );
  }
}
