import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
// IMPORTANTE: Ajuste o caminho do import do seu banco de dados
import '../services/database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? usuarioLogado;
  bool _isAdmin = false;
  bool _isAtualizandoPerfil = false;

  final Color roxoPrincipal = const Color(0xFF6A1B9A);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      setState(() {
        usuarioLogado = args;
        // VERIFICAÇÃO DE PODER ⚡
        final acesso = args['acesso_adm'];
        _isAdmin = (acesso == 1 || acesso == '1');
      });
    }
  }

  void _confirmarSaida() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair do App"),
        content: const Text("Deseja realmente fechar o aplicativo?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text("Sair", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Função para abrir o LinkedIn ---
  Future<void> _abrirLinkedinDeivid() async {
    final Uri url = Uri.parse('https://www.linkedin.com/in/deivid-milhomem-ba7777135/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o link do LinkedIn.')),
      );
    }
  }

  // ===========================================================================
  // REQ 1 e 2: O FLUXOGRAMA DE AJUDA (TIMELINE VISUAL) 💡
  // ===========================================================================
  void _abrirGuiaRapido() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tracinho no topo do Modal
              Center(
                child: Container(
                  width: 40, height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.lightbulb_circle, color: Colors.amber.shade600, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text("Como funciona o app?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              const Text("Siga este fluxo simples para gerenciar seus atendimentos sem se perder:", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 24),

              // A Mágica da Timeline Visual
              _buildPassoTimeline("1", "Primeiro Contato", "Use a tela 'Agendar Nova Paciente' apenas para cadastrar mulheres que ainda não estão no sistema e marcar a primeira sessão delas.", Icons.person_add_alt_1, false),
              _buildPassoTimeline("2", "Validação (Pós-Sessão)", "Após a data do atendimento, vá em 'Validar Sessões'. Lá você confirma se a paciente compareceu (Realizada) ou se faltou (Desistência).", Icons.fact_check_outlined, false),
              _buildPassoTimeline("3", "Acompanhamento", "Na tela 'Sessões Registradas', você vê todo o seu histórico. De lá mesmo, com um clique, você já remarca a próxima sessão da paciente!", Icons.history_edu, true),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: roxoPrincipal),
                  child: const Text("Entendi!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // Componente construtor de cada passo da Timeline
  Widget _buildPassoTimeline(String numero, String titulo, String descricao, IconData icone, bool isUltimo) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A coluna com a bolinha e a linha conectora
          Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: roxoPrincipal, shape: BoxShape.circle),
                child: Center(child: Text(numero, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              // Desenha a linha apenas se não for o último passo
              if (!isUltimo) Expanded(child: Container(width: 2, color: roxoPrincipal.withOpacity(0.3))),
            ],
          ),
          const SizedBox(width: 16),
          // O conteúdo do passo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icone, color: roxoPrincipal, size: 20),
                      const SizedBox(width: 8),
                      Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(descricao, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODAL DE EDIÇÃO DE PERFIL ---
  void _abrirConfiguracoesPerfil() {
    if (usuarioLogado == null) return;

    final nomeCtrl = TextEditingController(text: usuarioLogado!['nome_usuario']);
    final crpCtrl = TextEditingController(text: usuarioLogado!['crp']);
    final contatoCtrl = TextEditingController(text: usuarioLogado!['contato'] ?? '');
    final linkedinCtrl = TextEditingController(text: usuarioLogado!['linkedin'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 20, right: 20, top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Editar Perfil", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: roxoPrincipal)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
                      const SizedBox(height: 12),
                      TextField(controller: crpCtrl, decoration: const InputDecoration(labelText: "Registro (Ex: CRP)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge))),
                      const SizedBox(height: 12),
                      TextField(controller: contatoCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Contato (WhatsApp)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
                      const SizedBox(height: 12),
                      TextField(controller: linkedinCtrl, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: "Link do LinkedIn", border: OutlineInputBorder(), prefixIcon: Icon(Icons.link))),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: roxoPrincipal, foregroundColor: Colors.white),
                          onPressed: _isAtualizandoPerfil ? null : () async {
                            if (nomeCtrl.text.isEmpty || crpCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nome e Registro são obrigatórios!"), backgroundColor: Colors.orange));
                              return;
                            }

                            setModalState(() => _isAtualizandoPerfil = true);

                            try {
                              await DatabaseService().atualizarPerfilUsuario(
                                idUsuario: usuarioLogado!['id_usuario'],
                                nome: nomeCtrl.text.trim(),
                                crp: crpCtrl.text.trim(),
                                contato: contatoCtrl.text.trim().isEmpty ? null : contatoCtrl.text.trim(),
                                linkedin: linkedinCtrl.text.trim().isEmpty ? null : linkedinCtrl.text.trim(),
                              );

                              setState(() {
                                usuarioLogado!['nome_usuario'] = nomeCtrl.text.trim();
                                usuarioLogado!['crp'] = crpCtrl.text.trim();
                                usuarioLogado!['contato'] = contatoCtrl.text.trim().isEmpty ? null : contatoCtrl.text.trim();
                                usuarioLogado!['linkedin'] = linkedinCtrl.text.trim().isEmpty ? null : linkedinCtrl.text.trim();
                              });

                              if (mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil atualizado com sucesso!"), backgroundColor: Colors.green));
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao atualizar: $e"), backgroundColor: Colors.red));
                            } finally {
                              setModalState(() => _isAtualizandoPerfil = false);
                            }
                          },
                          child: _isAtualizandoPerfil
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Salvar Alterações", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }
        );
      },
    );
  }

  // --- Widget para construir os botões do menu ---
  Widget _buildMenuButton(String titulo, String subtitulo, IconData icone, VoidCallback acao) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: acao,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(icone, color: roxoPrincipal, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text(subtitulo, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Programa Acolha uma Mulher", style: TextStyle(fontSize: 18)),
        backgroundColor: roxoPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // AQUI ESTÁ O NOVO BOTÃO DE AJUDA 💡
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: "Como usar o app?",
            onPressed: _abrirGuiaRapido,
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: "Editar Meu Perfil",
            onPressed: _abrirConfiguracoesPerfil,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: "Sair",
            onPressed: _confirmarSaida,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === HEADER INSPIRADOR ===
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: roxoPrincipal,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text("Olá, ", style: TextStyle(fontSize: 22, color: Colors.white70)),
                            Expanded(
                              child: Text(
                                usuarioLogado != null ? "${usuarioLogado!['nome_usuario']}" : "Visitante",
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_isAdmin)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                            child: const Text("ADMINISTRADOR", style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        const SizedBox(height: 20),
                        const Text(
                          "Sua dedicação é o que move este projeto. Cada sessão agendada e cada escuta atenta representam um passo enorme na transformação e dignidade de quem mais precisa. Obrigado por fazer a diferença!",
                          style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // === MENU DE NAVEGAÇÃO ===
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Como posso ajudar hoje?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 16),

                        if (_isAdmin) ...[
                          _buildMenuButton(
                            "Painel de Gestão",
                            "Administração de voluntárias e assistidas",
                            Icons.admin_panel_settings,
                                () => Navigator.pushNamed(context, "/gestao"),
                          ),
                          Row(children: const [
                            Expanded(child: Divider(thickness: 1)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("Ações da Voluntária", style: TextStyle(color: Colors.grey, fontSize: 12))),
                            Expanded(child: Divider(thickness: 1)),
                          ]),
                          const SizedBox(height: 16),
                        ],

                        _buildMenuButton(
                          "Agendar Nova Paciente",
                          "Realize o primeiro registro de uma assistida",
                          Icons.person_add_alt_1,
                              () => Navigator.pushNamed(context, "/agendar", arguments: usuarioLogado),
                        ),

                        _buildMenuButton(
                          "Validar Sessões",
                          "Confirme presenças ou registre desistências",
                          Icons.fact_check_outlined,
                              () => Navigator.pushNamed(context, "/validar", arguments: usuarioLogado),
                        ),

                        _buildMenuButton(
                          "Sessões Registradas",
                          "Veja seu histórico e faça reagendamentos",
                          Icons.history_edu,
                              () => Navigator.pushNamed(context, "/registradas", arguments: usuarioLogado),
                        ),

                        _buildMenuButton(
                          "Materiais e Informações",
                          "Consulte documentos e guias do programa",
                          Icons.library_books_outlined,
                              () => Navigator.pushNamed(context, "/informacoes"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // === RODAPÉ (CRÉDITOS ACADÊMICOS E VERSÃO) ===
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Garante que a coluna abrace os filhos
              children: [
                InkWell(
                  onTap: _abrirLinkedinDeivid,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Text(
                          "Aplicativo voluntário originado de um projeto acadêmico.",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Desenvolvido por ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              "Deivid Milhomem",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: roxoPrincipal, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // --- AQUI ESTÁ A ASSINATURA DA VERSÃO ---
                const SizedBox(height: 4),
                Text(
                  "Versão 2.0",
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5 // Dá um visual de "marca d'água" moderno
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}