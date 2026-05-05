import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Certifique-se que o caminho do import está correto para o seu projeto
import 'package:aplicacao/services/database.dart';

class AgendarSessao extends StatefulWidget {
  const AgendarSessao({super.key});

  @override
  State<AgendarSessao> createState() => _AgendarSessaoState();
}

class _AgendarSessaoState extends State<AgendarSessao> {
  // A CHAVE DO FORMULÁRIO (Para validação visual)
  final _formKey = GlobalKey<FormState>();

  // Flag para saber se o usuário já tentou clicar em salvar
  bool _tentouSalvar = false;

  // Controllers
  final nomeController = TextEditingController();
  final contatoController = TextEditingController();
  final numSessaoController = TextEditingController();

  DateTime? dataSelecionada;
  TimeOfDay? horarioSelecionado;

  bool _isLoading = false;
  Map<String, dynamic>? usuarioLogado;

  // Variáveis para a lógica de Assistida Existente
  bool _isNovaAssistida = true;
  List<Map<String, dynamic>> _assistidasVinculadas = [];
  int? _idAssistidaSelecionada;

  final Color roxoPrincipal = const Color(0xFF6A1B9A);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      if (args.containsKey('preencher_automatico')) {
        usuarioLogado = args['usuario'];
        if (nomeController.text.isEmpty) {
          nomeController.text = args['nome_assistida'] ?? '';
          contatoController.text = args['contato_assistida'] ?? '';
          numSessaoController.text = args['proxima_sessao'].toString();
        }
      } else {
        usuarioLogado = args;
      }
      _carregarAssistidasDaVoluntaria();
    }
  }

  Future<void> _carregarAssistidasDaVoluntaria() async {
    if (usuarioLogado == null) return;
    try {
      final db = DatabaseService();
      final lista = await db.getAssistidas(usuarioLogado!['id_usuario']);
      if (mounted) {
        setState(() => _assistidasVinculadas = lista);
      }
    } catch (e) {
      print("Erro ao carregar assistidas: $e");
    }
  }

  // --- MÉTODOS DE FORMATAÇÃO BRASILEIRA ---
  String _formatarDataBR(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}";
  }

  String _formatarHoraBR(TimeOfDay hora) {
    // Garante o formato 24h independentemente da configuração de idioma do celular
    return "${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}";
  }

  // ===========================================================================
  // SELEÇÃO DE DATA E HORA (COM TRAVA EM 01/01/2026 E IDIOMA PT-BR)
  // ===========================================================================
  Future<void> selecionarData() async {
    // Trava absoluta solicitada: 01 de Janeiro de 2026
    final dataLimiteInicial = DateTime(2026, 1, 1);

    // Garante que o calendário abra no mês atual, a menos que hoje seja antes do limite
    final dataInicial = DateTime.now().isBefore(dataLimiteInicial) ? dataLimiteInicial : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: dataLimiteInicial, // Agora a voluntária pode voltar até Jan/2026!
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'), // Força o calendário a usar o Português do Brasil!
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: roxoPrincipal, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => dataSelecionada = picked);
  }

  Future<void> selecionarHorario() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: roxoPrincipal),
          ),
          child: MediaQuery(
            // Força o relógio a usar o formato de 24 horas no seletor
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) setState(() => horarioSelecionado = picked);
  }

  // --- LÓGICA DE VALIDAÇÃO E CONFIRMAÇÃO ---
  Future<void> _validarEConfirmar() async {
    setState(() => _tentouSalvar = true);

    bool formValido = _formKey.currentState?.validate() ?? false;

    if (!formValido) {
      _mostrarSnack("Verifique os campos em vermelho.", Colors.red);
      return;
    }

    if (!_isNovaAssistida && _idAssistidaSelecionada == null) {
      _mostrarSnack("Selecione uma paciente da lista!", Colors.red);
      return;
    }

    if (dataSelecionada == null || horarioSelecionado == null) {
      _mostrarSnack("A data e o horário são obrigatórios!", Colors.red);
      return;
    }

    String nomeConfirmacao = _isNovaAssistida
        ? nomeController.text.trim()
        : _assistidasVinculadas.firstWhere((a) => a['id_assistida'] == _idAssistidaSelecionada)['nome'];

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Color(0xFF6A1B9A)),
            SizedBox(width: 8),
            Text("Revisar Agendamento", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Confirme os dados antes de salvar no sistema:", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            Text("Paciente: $nomeConfirmacao", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text("Sessão N°: ${numSessaoController.text}"),
            Text("Data: ${_formatarDataBR(dataSelecionada!)}"),
            Text("Horário: ${_formatarHoraBR(horarioSelecionado!)}", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Editar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Tudo Certo, Agendar!", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      _executarSalvamentoNoBanco();
    }
  }

  Future<void> _executarSalvamentoNoBanco() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();

      if (_isNovaAssistida) {
        await dbService.realizarAgendamentoCompleto(
          idUsuario: usuarioLogado!['id_usuario'],
          nomeAssistida: nomeController.text.trim(),
          contatoAssistida: contatoController.text.trim(),
          numeroSessao: int.parse(numSessaoController.text),
          dataSessao: dataSelecionada!,
          horarioSessao: horarioSelecionado!,
        );
      } else {
        await dbService.agendarSessaoExistente(
          idAssistida: _idAssistidaSelecionada!,
          numeroSessao: int.parse(numSessaoController.text),
          dataSessao: dataSelecionada!,
          horarioSessao: horarioSelecionado!,
        );
      }

      if (mounted) {
        _mostrarSnack("Agendamento realizado com sucesso! 🚀", Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarSnack("Erro ao salvar: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agendar Sessão"),
        backgroundColor: roxoPrincipal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: roxoPrincipal))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF6A1B9A)),
                        SizedBox(width: 8),
                        Text("Sobre o Agendamento", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6A1B9A))),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Preencha todos os campos obrigatórios (*). Revise a data e a hora antes de salvar para evitar retrabalho.",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("👩 Dados da Paciente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: roxoPrincipal)),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: SwitchListTile(
                          title: const Text("Cadastrar nova paciente?", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text("Desmarque para buscar na sua lista.", style: TextStyle(fontSize: 12)),
                          value: _isNovaAssistida,
                          activeColor: roxoPrincipal,
                          onChanged: (val) {
                            setState(() {
                              _isNovaAssistida = val;
                              if (val) _idAssistidaSelecionada = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isNovaAssistida) ...[
                        TextFormField(
                          controller: nomeController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(labelText: "Nome Completo *", prefixIcon: Icon(Icons.person_outline)),
                          validator: (value) => value == null || value.trim().isEmpty ? "Informe o nome da paciente" : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: contatoController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: "Telefone / WhatsApp *", prefixIcon: Icon(Icons.phone_android)),
                          validator: (value) => value == null || value.trim().isEmpty ? "Informe um contato válido" : null,
                        ),
                      ] else ...[
                        _assistidasVinculadas.isEmpty
                            ? const Text("Você ainda não possui pacientes vinculadas para selecionar.", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic))
                            : DropdownButtonFormField<int>(
                          decoration: InputDecoration(
                              labelText: "Selecione a Paciente *",
                              prefixIcon: const Icon(Icons.search),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: _tentouSalvar && _idAssistidaSelecionada == null ? Colors.red : Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(12)
                              )
                          ),
                          value: _idAssistidaSelecionada,
                          items: _assistidasVinculadas.map((a) {
                            return DropdownMenuItem<int>(value: a['id_assistida'], child: Text(a['nome']));
                          }).toList(),
                          onChanged: (val) => setState(() => _idAssistidaSelecionada = val),
                        ),
                        if (_tentouSalvar && _idAssistidaSelecionada == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8, left: 12),
                            child: Text("Por favor, selecione uma paciente.", style: TextStyle(color: Colors.red, fontSize: 12)),
                          )
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("📅 Detalhes da Sessão", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: roxoPrincipal)),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: numSessaoController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(labelText: "Número da Sessão *", prefixIcon: Icon(Icons.tag)),
                        validator: (value) => value == null || value.trim().isEmpty ? "Informe o número" : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: selecionarData,
                              icon: Icon(Icons.calendar_today, size: 18, color: _tentouSalvar && dataSelecionada == null ? Colors.red : Colors.black87),
                              label: Text(
                                  dataSelecionada == null ? "Data *" : _formatarDataBR(dataSelecionada!),
                                  style: TextStyle(color: _tentouSalvar && dataSelecionada == null ? Colors.red : Colors.black87)
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                    color: _tentouSalvar && dataSelecionada == null ? Colors.red : Colors.grey.shade400,
                                    width: _tentouSalvar && dataSelecionada == null ? 2 : 1
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: selecionarHorario,
                              icon: Icon(Icons.access_time, size: 18, color: _tentouSalvar && horarioSelecionado == null ? Colors.red : Colors.black87),
                              label: Text(
                                  horarioSelecionado == null ? "Horário *" : _formatarHoraBR(horarioSelecionado!),
                                  style: TextStyle(color: _tentouSalvar && horarioSelecionado == null ? Colors.red : Colors.black87)
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                    color: _tentouSalvar && horarioSelecionado == null ? Colors.red : Colors.grey.shade400,
                                    width: _tentouSalvar && horarioSelecionado == null ? 2 : 1
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _validarEConfirmar,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text("Revisar e Agendar", style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roxoPrincipal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
