import 'package:flutter/material.dart';
// Ajuste o caminho do import se necessário
import '../services/database.dart';
// Importando a nossa aba de relatórios
import 'aba_relatorios.dart';

class GestaoPage extends StatefulWidget {
  const GestaoPage({super.key});

  @override
  State<GestaoPage> createState() => _GestaoPageState();
}

class _GestaoPageState extends State<GestaoPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _assistidas = [];

  // === PALETA DE CORES DARK (ADMIN THEME) ===
  final Color bgDark = const Color(0xFF121212); // Fundo principal
  final Color cardDark = const Color(0xFF1E1E1E); // Fundo dos cards
  final Color textPrimary = Colors.white;
  final Color textSecondary = Colors.grey.shade400;

  @override
  void initState() {
    super.initState();
    _carregarDadosAdmin();
  }

  Future<void> _carregarDadosAdmin() async {
    setState(() => _isLoading = true);
    try {
      final db = DatabaseService();
      final users = await db.getAllUsuarios();
      final assists = await db.getAllAssistidasAdmin();

      if (mounted) {
        setState(() {
          _usuarios = users;
          _assistidas = assists;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro admin: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===========================================================================
  // LÓGICA DE USUÁRIOS
  // ===========================================================================
  Future<void> _promoverUsuario(int idUsuario, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        title: Text("Confirmar Promoção", style: TextStyle(color: textPrimary)),
        content: Text("Deseja dar acesso de ADMIN para $nome?\nEssa ação concede poder total ao usuário.", style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text("Sim, Promover", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await DatabaseService().promoverParaAdmin(idUsuario);
        _mostrarSnack("Usuário promovido com sucesso! 👑", Colors.green);
        _carregarDadosAdmin();
      } catch (e) {
        _mostrarSnack("Erro: $e", Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  // --- FUNÇÃO DE EXCLUSÃO COM DUPLA CONFIRMAÇÃO (DOUBLE CHECK) 🔐 ---
  Future<void> _confirmarExclusaoUsuario(int idUsuario, String nome) async {
    // 1º MODAL: Aviso de Risco
    final confirmarPrimeiro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent, width: 2)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text("Exclusão de Risco", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          "Tem certeza que deseja apagar permanentemente o usuário '$nome'?\n\n"
              "🚨 ATENÇÃO: Essa ação acionará uma limpeza em cascata no banco de dados. TODOS os registros vinculados a esta voluntária (Assistidas e Sessões) também serão apagados irremediavelmente.",
          style: TextStyle(color: textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Sim, Desejo Excluir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    // Se o usuário clicou "Sim" no primeiro modal, jogamos a segunda trava!
    if (confirmarPrimeiro == true) {

      // 2º MODAL: Confirmação Definitiva (Irreversível)
      final confirmarSegundo = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.red, width: 4)), // Borda mais grossa e vermelha
          title: const Row(
            children: [
              Icon(Icons.dangerous, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text("ÚLTIMO AVISO!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            "Você tem CERTEZA ABSOLUTA?\n\nO processo é irreversível e irrecuperável. Não haverá como restaurar os dados de '$nome' após esta ação.",
            style: TextStyle(color: textPrimary, height: 1.4, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Ufa, Cancelar", style: TextStyle(color: Colors.grey))
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Sim, Destruir Tudo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      // Só executa a exclusão se ele confirmou TAMBÉM o segundo modal
      if (confirmarSegundo == true) {
        setState(() => _isLoading = true);
        try {
          await DatabaseService().excluirUsuarioCompleto(idUsuario);
          _mostrarSnack("Usuário e todos os seus registros foram varridos do sistema! 🗑️", Colors.green);
          _carregarDadosAdmin();
        } catch (e) {
          _mostrarSnack("Erro ao excluir: $e", Colors.red);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // ===========================================================================
  // LÓGICA DE ASSISTIDAS
  // ===========================================================================
  Future<void> _alterarStatusAtendimento(int idAssistida, bool ativo) async {
    setState(() => _isLoading = true);
    try {
      final novoStatus = ativo ? '1' : '0';
      await DatabaseService().alterarStatusAssistida(idAssistida, novoStatus);
      _mostrarSnack("Status atualizado!", Colors.blue);
      _carregarDadosAdmin();
    } catch (e) {
      _mostrarSnack("Erro: $e", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _dialogoTransferir(Map<String, dynamic> assistida) async {
    int? novoIdSelecionado;
    final psicologoAtualId = assistida['id_usuario'];

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: cardDark,
              title: Text("Transferir Atendimento", style: TextStyle(color: textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Paciente: ${assistida['nome']}", style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 20),
                  Text("Selecione o novo responsável:", style: TextStyle(color: textSecondary)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(8),
                      color: bgDark,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        dropdownColor: cardDark,
                        value: novoIdSelecionado,
                        hint: Text("Escolher Voluntária...", style: TextStyle(color: textSecondary)),
                        items: _usuarios.map((u) {
                          final isAtual = u['id_usuario'] == psicologoAtualId;
                          return DropdownMenuItem<int>(
                            value: u['id_usuario'],
                            enabled: !isAtual,
                            child: Text(
                              u['nome_usuario'] + (isAtual ? " (Atual)" : ""),
                              style: TextStyle(
                                color: isAtual ? Colors.grey.shade600 : textPrimary,
                                fontStyle: isAtual ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() => novoIdSelecionado = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: novoIdSelecionado == null
                      ? null
                      : () {
                    Navigator.pop(ctx);
                    _executarTransferencia(assistida['id_assistida'], novoIdSelecionado!);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A), foregroundColor: Colors.white),
                  child: const Text("Transferir"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executarTransferencia(int idAssistida, int novoIdUsuario) async {
    setState(() => _isLoading = true);
    try {
      await DatabaseService().transferirAssistida(idAssistida, novoIdUsuario);
      _mostrarSnack("Assistida transferida com sucesso! 🔄", Colors.green);
      _carregarDadosAdmin();
    } catch (e) {
      _mostrarSnack("Erro ao transferir: $e", Colors.red);
      setState(() => _isLoading = false);
    }
  }

  void _mostrarSnack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          title: const Text("Painel de Gestão (Admin)", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.badge), text: "Voluntários(as)"),
              Tab(icon: Icon(Icons.people), text: "Assistidas"),
              Tab(icon: Icon(Icons.bar_chart), text: "Relatórios"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : TabBarView(
          children: [
            // --- ABA 1: LISTA DE USUÁRIOS (DARK THEME) ---
            _usuarios.isEmpty
                ? Center(child: Text("Nenhum usuário encontrado.", style: TextStyle(color: textSecondary)))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _usuarios.length,
              itemBuilder: (ctx, index) {
                final u = _usuarios[index];
                final isAdm = u['acesso_adm'].toString() == '1';

                final emailVoluntaria = u['email'] ?? 'Sem e-mail cadastrado';
                final contatoVoluntaria = u['contato'] ?? 'Sem telefone cadastrado';

                return Card(
                  color: cardDark,
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade800)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isAdm ? Colors.amber.shade700 : Colors.blueGrey.shade800,
                      child: Icon(isAdm ? Icons.star : Icons.person, color: Colors.white),
                    ),
                    title: Text(
                        u['nome_usuario'],
                        style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 16)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(isAdm ? "Privilégio: Administrador" : "Registro: ${u['crp'] ?? '-'}", style: TextStyle(color: Colors.amber.shade200, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email_outlined, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(emailVoluntaria, style: TextStyle(color: textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_android, size: 14, color: textSecondary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(contatoVoluntaria, style: TextStyle(color: textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdm)
                          const Chip(label: Text("Admin", style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.amber, visualDensity: VisualDensity.compact)
                        else
                          IconButton(
                            icon: const Icon(Icons.arrow_circle_up, color: Colors.greenAccent),
                            tooltip: "Promover a Admin",
                            onPressed: () => _promoverUsuario(u['id_usuario'], u['nome_usuario']),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                          tooltip: "Excluir Usuário e Registros",
                          onPressed: () => _confirmarExclusaoUsuario(u['id_usuario'], u['nome_usuario']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // --- ABA 2: LISTA DE ASSISTIDAS (DARK THEME) ---
            _assistidas.isEmpty
                ? Center(child: Text("Nenhuma assistida cadastrada.", style: TextStyle(color: textSecondary)))
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _assistidas.length,
              itemBuilder: (ctx, index) {
                final a = _assistidas[index];
                final isAtivo = a['status_atendimento'].toString() == '1';
                final nomePsico = a['tb_usuario'] != null ? a['tb_usuario']['nome_usuario'] : 'Sem vínculo';
                final contatoAssistida = a['contato'] ?? 'Sem telefone cadastrado';

                return Card(
                  color: cardDark,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: isAtivo ? Colors.grey.shade800 : Colors.red.shade900.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                            Icons.face_3,
                            color: isAtivo ? Colors.amber : Colors.grey.shade600
                        ),
                        title: Text(
                          a['nome'],
                          style: TextStyle(
                              color: isAtivo ? textPrimary : Colors.grey.shade600,
                              decoration: isAtivo ? null : TextDecoration.lineThrough,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Responsável: $nomePsico", style: TextStyle(color: textSecondary)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone_android, size: 14, color: isAtivo ? Colors.blueAccent : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  contatoAssistida,
                                  style: TextStyle(color: isAtivo ? Colors.blueAccent : Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: isAtivo,
                          activeColor: Colors.greenAccent,
                          inactiveThumbColor: Colors.redAccent,
                          inactiveTrackColor: Colors.red.withOpacity(0.3),
                          onChanged: (val) => _alterarStatusAtendimento(a['id_assistida'], val),
                        ),
                      ),

                      if (isAtivo)
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: TextButton.icon(
                            onPressed: () => _dialogoTransferir(a),
                            icon: const Icon(Icons.swap_horiz, size: 18, color: Colors.blueAccent),
                            label: const Text("Transferir Atendimento", style: TextStyle(color: Colors.blueAccent)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // --- ABA 3: RELATÓRIOS E DASHBOARD ---
            Container(
                color: Colors.white,
                child: const AbaRelatorios()
            ),
          ],
        ),
      ),
    );
  }
}
