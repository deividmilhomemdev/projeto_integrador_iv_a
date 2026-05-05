import 'package:flutter/material.dart';
// Ajuste o caminho do import conforme sua estrutura de pastas
import 'package:aplicacao/services/database.dart';

class SessoesRegistradas extends StatefulWidget {
  const SessoesRegistradas({super.key});

  @override
  State<SessoesRegistradas> createState() => _SessoesRegistradasState();
}

class _SessoesRegistradasState extends State<SessoesRegistradas> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historicoCompleto = [];
  Map<String, dynamic>? usuarioLogado;

  // Variáveis para o Dashboard (Contadores)
  int _totalAssistidasAtivas = 0;
  int _qtdAgendadas = 0;
  int _qtdRealizadas = 0;
  int _qtdDesistencias = 0;

  // Estado do Filtro Ativo ('Todas', 'Pendente', 'Realizada', 'Desistência')
  String _filtroAtual = 'Todas';

  // Cores Suavizadas (Pastel) da Paleta Original
  final Color greenBg = const Color(0xFFE8F5E9);
  final Color greenText = const Color(0xFF2E7D32);
  final Color orangeBg = const Color(0xFFFFF3E0);
  final Color orangeText = const Color(0xFFEF6C00);
  final Color redBg = const Color(0xFFFFEBEE);
  final Color redText = const Color(0xFFC62828);
  final Color blueBg = const Color(0xFFE3F2FD);
  final Color blueText = const Color(0xFF1565C0);
  final Color roxoBg = const Color(0xFFF3E5F5);
  final Color roxoText = const Color(0xFF6A1B9A);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      usuarioLogado = args;
      _carregarDadosCompletos();
    }
  }

  Future<void> _carregarDadosCompletos() async {
    if (usuarioLogado == null) return;

    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final idUser = usuarioLogado!['id_usuario'];

      final totalAssistidas = await db.countAssistidasAtivas(idUser);
      List<Map<String, dynamic>> historicoBruto = await db.getHistoricoSessoes(idUser);

      int agendadas = 0;
      int realizadas = 0;
      int desistencias = 0;

      for (var sessao in historicoBruto) {
        if (sessao['indicador_sessao_realizada'] == '1') {
          realizadas++;
          sessao['status_calc'] = 'Realizada';
          sessao['ordem_status'] = 2;
        } else if (sessao['indicador_desistencia'] == '1') {
          desistencias++;
          sessao['status_calc'] = 'Desistência';
          sessao['ordem_status'] = 3;
        } else {
          agendadas++;
          sessao['status_calc'] = 'Pendente';
          sessao['ordem_status'] = 1;
        }
      }

      historicoBruto.sort((a, b) {
        int cmpStatus = a['ordem_status'].compareTo(b['ordem_status']);
        if (cmpStatus != 0) return cmpStatus;

        DateTime dataA = DateTime.parse(a['data_sessao']);
        DateTime dataB = DateTime.parse(b['data_sessao']);
        return dataB.compareTo(dataA);
      });

      if (mounted) {
        setState(() {
          _totalAssistidasAtivas = totalAssistidas;
          _historicoCompleto = historicoBruto;
          _qtdAgendadas = agendadas;
          _qtdRealizadas = realizadas;
          _qtdDesistencias = desistencias;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao carregar dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- REQ 1: NOVO FORMATO DE MINI-CARD PARA A MATRIZ 2x2 ---
  Widget _buildMiniCard(String titulo, String valor, Color borderColor, Color textIconColor, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white, // Fundo branco para contrastar com o card roxo
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2), // Borda colorida para manter a identidade
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: textIconColor, size: 20),
              const SizedBox(width: 6),
              Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textIconColor)),
            ],
          ),
          const SizedBox(height: 4),
          Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatarData(String dataIso) {
    try {
      final partes = dataIso.split('T')[0].split('-');
      return "${partes[2]}/${partes[1]}/${partes[0]}";
    } catch (e) {
      return dataIso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = _filtroAtual == 'Todas'
        ? _historicoCompleto
        : _historicoCompleto.where((s) => s['status_calc'] == _filtroAtual).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sessões Registradas"),
        backgroundColor: roxoText,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade50, // Fundo levemente cinza para destacar os cards
      // --- REQ 2: CUSTOM SCROLL VIEW PARA A TELA INTEIRA ROLAR ---
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: roxoText))
          : CustomScrollView(
        slivers: [
          // 1. O SUPER CARD DO DASHBOARD (Rola junto com a tela)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: roxoBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: roxoText.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(color: roxoText.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bloco de Texto
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined, color: roxoText, size: 24),
                        const SizedBox(width: 8),
                        Text("Visão Geral do seu Trabalho", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: roxoText)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Acompanhe o impacto dos seus atendimentos. Esta página exibe todo o seu histórico e permite remarcar sessões rapidamente.",
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    // Matriz 2x2 Compacta
                    Row(
                      children: [
                        Expanded(child: _buildMiniCard("Atendimentos", "$_totalAssistidasAtivas", blueBg, blueText, Icons.people)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMiniCard("Agendadas", "$_qtdAgendadas", orangeBg, orangeText, Icons.calendar_month)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMiniCard("Realizadas", "$_qtdRealizadas", greenBg, greenText, Icons.check_circle)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMiniCard("Desistências", "$_qtdDesistencias", redBg, redText, Icons.cancel)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. A BARRA DE FILTROS (Também rola junto)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text("Filtrar: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Todas', Colors.grey.shade600),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pendente', orangeText),
                  const SizedBox(width: 8),
                  _buildFilterChip('Realizada', greenText),
                  const SizedBox(width: 8),
                  _buildFilterChip('Desistência', redText),
                ],
              ),
            ),
          ),

          // 3. A LISTA DE REGISTROS (A mágica do SliverList)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: listaFiltrada.isEmpty
                ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text("Nenhum registro encontrado para: $_filtroAtual", style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final sessao = listaFiltrada[index];
                  final assistida = sessao['tb_assistida'];
                  final nome = assistida != null ? assistida['nome'] : 'Desconhecido';
                  final contato = assistida != null ? assistida['contato'] : '-';

                  final String statusCalc = sessao['status_calc'];
                  final int numeroSessao = sessao['numero_sessao'] ?? 0;

                  int proximaSessaoNum = statusCalc == 'Desistência' ? numeroSessao : numeroSessao + 1;

                  Color chipBg = orangeBg;
                  Color chipText = orangeText;

                  if (statusCalc == 'Realizada') {
                    chipBg = greenBg;
                    chipText = greenText;
                  } else if (statusCalc == 'Pendente') {
                    chipBg = redBg;
                    chipText = redText;
                  }

                  return Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  nome,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  statusCalc,
                                  style: TextStyle(color: chipText, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Icon(Icons.tag, size: 16, color: roxoText),
                              const SizedBox(width: 4),
                              Text("Sessão #$numeroSessao", style: TextStyle(fontWeight: FontWeight.bold, color: roxoText)),
                              const SizedBox(width: 16),
                              Icon(Icons.phone_android, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 4),
                              Text(contato, style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Icon(Icons.calendar_month, size: 16, color: Colors.grey[700]),
                              const SizedBox(width: 4),
                              Text("${_formatarData(sessao['data_sessao'])} - ${sessao['horario_sessao']}", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
                            ],
                          ),

                          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context,
                                    '/agendar',
                                    arguments: {
                                      'preencher_automatico': true,
                                      'usuario': usuarioLogado,
                                      'nome_assistida': nome,
                                      'contato_assistida': contato,
                                      'proxima_sessao': proximaSessaoNum
                                    }
                                );
                              },
                              icon: Icon(
                                  statusCalc == 'Pendente' ? Icons.edit_calendar : Icons.add_circle_outline,
                                  color: roxoText
                              ),
                              label: Text(
                                  statusCalc == 'Pendente' ? "Remarcar esta sessão" : "Agendar próxima sessão",
                                  style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                              style: TextButton.styleFrom(foregroundColor: roxoText),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
                childCount: listaFiltrada.length,
              ),
            ),
          ),

          // Espaçamento final para o usuário conseguir rolar bem até o final
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // Componente visual para a barra de filtros
  Widget _buildFilterChip(String label, Color color) {
    final bool isSelected = _filtroAtual == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _filtroAtual = selected ? label : 'Todas';
        });
      },
      selectedColor: color.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 1.5 : 1.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
