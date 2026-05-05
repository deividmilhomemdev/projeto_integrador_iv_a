import 'package:flutter/material.dart';
// Ajuste o caminho do import conforme sua estrutura
import '../services/database.dart';

class ValidarSessao extends StatefulWidget {
  const ValidarSessao({super.key});

  @override
  State<ValidarSessao> createState() => _ValidarSessaoState();
}

class _ValidarSessaoState extends State<ValidarSessao> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _listaSessoes = [];
  Map<String, dynamic>? usuarioLogado;

  final Color roxoPrincipal = const Color(0xFF6A1B9A);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recupera o usuário da "mochila"
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      usuarioLogado = args;
      _carregarSessoes();
    }
  }

  Future<void> _carregarSessoes() async {
    if (usuarioLogado == null) return;

    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      // Busca apenas sessões pendentes de assistidas ATIVAS (status=1)
      final sessoes = await db.getSessoesPendentes(usuarioLogado!['id_usuario']);

      if (mounted) {
        setState(() {
          _listaSessoes = sessoes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // GERENCIADOR DE PACIENTES (CORREÇÃO DE CADASTROS)
  // ===========================================================================
  Future<void> _abrirGerenciadorAssistidas() async {
    if (usuarioLogado == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 5,
                width: 50,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.people_alt_outlined, color: Color(0xFF6A1B9A), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Meus Pacientes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
                          Text("Selecione um cadastro para corrigir nome ou telefone", style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: DatabaseService().getAssistidas(usuarioLogado!['id_usuario']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text("Erro ao buscar pacientes.", style: TextStyle(color: Colors.red)));
                    }

                    final pacientes = snapshot.data ?? [];
                    if (pacientes.isEmpty) {
                      return const Center(child: Text("Você ainda não tem pacientes cadastrados.", style: TextStyle(color: Colors.grey)));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: pacientes.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final paciente = pacientes[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade50,
                            child: const Icon(Icons.person, color: Color(0xFF6A1B9A)),
                          ),
                          title: Text(paciente['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(paciente['contato'] ?? "Sem contato", style: TextStyle(color: Colors.grey.shade600)),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            tooltip: "Corrigir Cadastro",
                            onPressed: () {
                              Navigator.pop(ctx);
                              _dialogoEditarAssistida(paciente);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _dialogoEditarAssistida(Map<String, dynamic> paciente) async {
    final nomeController = TextEditingController(text: paciente['nome']);
    final contatoController = TextEditingController(text: paciente['contato'] ?? '');
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.edit_document, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text("Corrigir Dados"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Altere com atenção. Esta mudança refletirá em todo o histórico da paciente.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: "Nome da Paciente", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contatoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Contato / WhatsApp", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    child: const Text("Cancelar", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (nomeController.text.trim().isEmpty) {
                      _mostrarSnack("O nome não pode ficar vazio!", Colors.red);
                      return;
                    }

                    final confirmar = await showDialog<bool>(
                      context: ctx,
                      builder: (ctxConfirm) => AlertDialog(
                        title: const Text("Confirmar Alteração"),
                        content: const Text("Deseja realmente salvar as alterações deste cadastro?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctxConfirm, false), child: const Text("Não")),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctxConfirm, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text("Sim, Salvar", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      setStateDialog(() => isSaving = true);
                      try {
                        await DatabaseService().atualizarAssistida(
                          idAssistida: paciente['id_assistida'],
                          nome: nomeController.text.trim(),
                          contato: contatoController.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          _mostrarSnack("Cadastro corrigido com sucesso! 🚀", Colors.green);
                          _carregarSessoes();
                        }
                      } catch (e) {
                        if (e.toString().contains('23505') || e.toString().contains('duplicate')) {
                          _mostrarSnack("Erro: Já existe outra paciente com esse mesmo nome e contato.", Colors.red);
                        } else {
                          _mostrarSnack("Erro ao salvar: $e", Colors.red);
                        }
                      } finally {
                        setStateDialog(() => isSaving = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Salvar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // LÓGICA DE VALIDAÇÃO DE SESSÕES COM PREVENÇÃO DE ERROS
  // ===========================================================================
  Future<void> _processarSessao(int idSessao, bool foiRealizada) async {
    setState(() => _isLoading = true);
    final db = DatabaseService();

    try {
      if (foiRealizada) {
        await db.marcarSessaoRealizada(idSessao);
        _mostrarSnack("Sessão confirmada com sucesso! ✅", Colors.green);
      } else {
        await db.registrarDesistencia(idSessao);
        _mostrarSnack("Desistência registrada. ⚠️", Colors.orange);
      }

      setState(() {
        _listaSessoes.removeWhere((sessao) => sessao['id_sessao'] == idSessao);
        _isLoading = false;
      });

    } catch (e) {
      _mostrarSnack("Erro ao atualizar: $e", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  // --- REQ 1: ALERTA DE CONFIRMAÇÃO PARA DESISTÊNCIA ---
  Future<void> _confirmarDesistencia(Map<String, dynamic> sessao) async {
    final assistida = sessao['tb_assistida'];
    final nomePaciente = assistida != null ? assistida['nome'] : 'Desconhecido';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text("Registrar Falta"),
          ],
        ),
        content: Text("Tem certeza que deseja registrar a desistência/falta da paciente '$nomePaciente' para esta sessão?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text("Sim, Registrar Falta", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _processarSessao(sessao['id_sessao'], false);
    }
  }

  // --- REQ 2 e 3: VERIFICAÇÃO DE DATA + CONFIRMAÇÃO DE DADOS PARA SESSÃO REALIZADA ---
  Future<void> _verificarERealizarSessao(Map<String, dynamic> sessao) async {
    try {
      final dataSessao = DateTime.parse(sessao['data_sessao']);
      final hoje = DateTime.now();

      final dataApenas = DateTime(dataSessao.year, dataSessao.month, dataSessao.day);
      final hojeApenas = DateTime(hoje.year, hoje.month, hoje.day);

      // Passo 1: Condicional existente da Data Futura
      if (dataApenas.isAfter(hojeApenas)) {
        final confirmarFuturo = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Atenção: Data Futura 🚨", style: TextStyle(color: Colors.orange)),
            content: const Text(
                "Este agendamento está marcado para uma data futura.\n\n"
                    "Tem certeza de que deseja prosseguir com a confirmação desta sessão antecipadamente?"
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Sim, prosseguir", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        // Se abortou o alerta futuro, sai da função
        if (confirmarFuturo != true) return;
      }

      // Passo 2: Tela de Confirmação Final detalhada
      final assistida = sessao['tb_assistida'];
      final nomePaciente = assistida != null ? assistida['nome'] : 'Desconhecido';
      final dataFormatada = _formatarData(sessao['data_sessao']);
      final horario = sessao['horario_sessao'];
      final numSessao = sessao['numero_sessao'];

      final confirmarRealizacao = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Confirmar Sessão"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Deseja confirmar a realização do seguinte atendimento?", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Text("Paciente: $nomePaciente", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text("Sessão: #$numSessao"),
              Text("Data: $dataFormatada"),
              Text("Horário: $horario"),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Voltar", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Sim, Confirmar Realização", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      // Só executa o processamento se confirmou a tela final
      if (confirmarRealizacao == true) {
        await _processarSessao(sessao['id_sessao'], true);
      }

    } catch (e) {
      _mostrarSnack("Erro ao verificar dados da sessão: $e", Colors.red);
    }
  }

  Future<void> _confirmarExclusao(int idSessao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Excluir Agendamento"),
        content: const Text("Tem certeza que deseja apagar este registro do sistema?\nUse isso apenas se o agendamento foi criado por engano ou remarcado. Essa ação não pode ser desfeita."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sim, Excluir", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await DatabaseService().excluirSessao(idSessao);
        _mostrarSnack("Agendamento excluído do sistema! 🗑️", Colors.grey.shade700);

        setState(() {
          _listaSessoes.removeWhere((sessao) => sessao['id_sessao'] == idSessao);
          _isLoading = false;
        });
      } catch (e) {
        _mostrarSnack("Erro ao excluir: $e", Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarSnack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Validar Sessões"),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_accounts_outlined),
            tooltip: "Corrigir Cadastros de Pacientes",
            onPressed: _abrirGerenciadorAssistidas,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: roxoPrincipal))
          : Column(
        children: [
          // --- CARD DE INSTRUÇÕES ---
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Como validar seus agendamentos:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: roxoPrincipal)),
                const SizedBox(height: 8),
                const Text("✅ Realizada: Clique se a sessão ocorreu normalmente."),
                const SizedBox(height: 4),
                const Text("⚠️ Desistência: Clique caso a assistida tenha faltado ou desmarcado."),
                const SizedBox(height: 4),
                const Text("🗑️ Excluir: Clique apenas se o agendamento foi registrado por engano."),
                const Divider(color: Colors.white, height: 20),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Dica: Errou o nome da paciente? Use o botão no canto superior direito para corrigir o cadastro.",
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- LISTA DE SESSÕES ---
          Expanded(
            child: _listaSessoes.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 10),
                  Text("Tudo em dia! Nenhuma sessão pendente.", style: TextStyle(fontSize: 16)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
              itemCount: _listaSessoes.length,
              itemBuilder: (context, index) {
                final sessao = _listaSessoes[index];
                final assistida = sessao['tb_assistida'];
                final nomePaciente = assistida != null ? assistida['nome'] : 'Desconhecido';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Sessão #${sessao['numero_sessao']}",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: roxoPrincipal),
                            ),
                            Chip(
                              label: Text(_formatarData(sessao['data_sessao']), style: const TextStyle(fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.purple.shade50,
                              side: BorderSide.none,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text("Paciente: $nomePaciente", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        Text("Horário: ${sessao['horario_sessao']}", style: TextStyle(fontSize: 16, color: Colors.grey[700])),

                        const Divider(height: 30),

                        Row(
                          children: [
                            // ALTERAÇÃO: Botão Desistência agora chama o Alerta de Confirmação
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _confirmarDesistencia(sessao),
                                icon: const Icon(Icons.close, color: Colors.orange),
                                label: const Text("Desistência", style: TextStyle(color: Colors.orange)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange), padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Botão Realizada continua acionando a função com dupla verificação
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _verificarERealizarSessao(sessao),
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text("Realizada", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () => _confirmarExclusao(sessao['id_sessao']),
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            label: const Text("Excluir registro indevido", style: TextStyle(color: Colors.redAccent)),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
