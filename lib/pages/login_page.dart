import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// IMPORTANTE: Ajuste o caminho abaixo conforme seu projeto
import 'package:aplicacao/services/database.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;

  // Cor principal do sistema
  final Color roxoPrincipal = const Color(0xFF6A1B9A);

  Future<void> _verificarEmailNoBanco() async {
    final emailDigitado = emailController.text.trim();

    // 1. Validações
    if (emailDigitado.isEmpty) {
      _mostrarSnack('Por favor, digite um e-mail.', Colors.orange);
      return;
    }

    if (!emailDigitado.contains('@') || !emailDigitado.contains('.')) {
      _mostrarSnack('E-mail inválido. Verifique se tem @ e .', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbService = DatabaseService();
      final usuario = await dbService.getUsuarioPorEmail(emailDigitado);

      if (mounted) {
        if (usuario != null) {
          // Sucesso: Vai para Home levando a mochila
          print("Usuário encontrado: ${usuario['nome_usuario']}");
          Navigator.pushReplacementNamed(
              context,
              '/home',
              arguments: usuario // <--- O passaporte
          );
        } else {
          // Falha: Vai para Cadastro levando o e-mail
          print("E-mail não encontrado. Redirecionando para cadastro...");
          Navigator.pushNamed(
            context,
            '/cadastro',
            arguments: emailDigitado,
          );
        }
      }
    } catch (e) {
      print('Erro na verificação: $e');
      _mostrarSnack('Erro de conexão: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarSnack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: cor),
    );
  }

  // --- Função para abrir o LinkedIn ---
  Future<void> _abrirLinkedinDeivid() async {
    final Uri url = Uri.parse('https://www.linkedin.com/in/deivid-milhomem-ba7777135/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _mostrarSnack('Não foi possível abrir o link do LinkedIn.', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Removemos a AppBar para um visual mais limpo e imersivo (Fullscreen Look)
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                // Garante que o conteúdo ocupe no mínimo a tela inteira para o rodapé ficar no fundo
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(), // Empurra o conteúdo para o meio

                      // === ÁREA DO LOGO ===
                      Hero(
                        tag: 'logo_app', // Efeito de transição suave se usar a logo em outras telas
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: Image.asset(
                            'assets/icon/logo_semfundo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.volunteer_activism, size: 100, color: roxoPrincipal);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // === TEXTOS DE BOAS-VINDAS ===
                      Text(
                        "Bem-vindo(a)",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: roxoPrincipal
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Informe seu e-mail para acessar o painel ou criar sua conta de voluntária.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                      const SizedBox(height: 40),

                      // === CAMPO DE E-MAIL ===
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "E-mail de Acesso",
                          hintText: "exemplo@email.com",
                          prefixIcon: Icon(Icons.email_outlined, color: roxoPrincipal),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: roxoPrincipal, width: 2),
                          ),
                        ),
                        // Facilita a vida do usuário permitindo submeter pelo botão "Enter/Ok" do teclado
                        onSubmitted: (_) => _verificarEmailNoBanco(),
                      ),
                      const SizedBox(height: 24),

                      // === BOTÃO DE AÇÃO ===
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: _isLoading
                            ? Center(child: CircularProgressIndicator(color: roxoPrincipal))
                            : ElevatedButton(
                          onPressed: _verificarEmailNoBanco,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: roxoPrincipal,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("ENTRAR / CADASTRAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const Spacer(), // Empurra o rodapé para o final da tela

                      // === RODAPÉ (CRÉDITOS ACADÊMICOS E VERSÃO) ===
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Mantém a coluna compacta
                          children: [
                            InkWell(
                              onTap: _abrirLinkedinDeivid,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Esta é uma aplicação voluntária.",
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
                            // --- ASSINATURA DA VERSÃO AQUI ---
                            const SizedBox(height: 4),
                            Text(
                              "Versão 2.0",
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5 // Visual moderno de marca d'água
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
