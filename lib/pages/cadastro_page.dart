import 'package:flutter/material.dart';
// IMPORTANTE: Ajuste o caminho abaixo para onde seu arquivo database.dart está salvo
import 'package:aplicacao/services/database.dart'; // Ajuste conforme seu projeto

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  late TextEditingController emailController;
  final nomeController = TextEditingController();
  final codigoController = TextEditingController();

  // Novos Controllers
  final contatoController = TextEditingController();
  final linkedinController = TextEditingController();

  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    final emailRecebido = (args is String) ? args : "";
    emailController = TextEditingController(text: emailRecebido);
  }

  @override
  void dispose() {
    emailController.dispose();
    nomeController.dispose();
    codigoController.dispose();
    contatoController.dispose();
    linkedinController.dispose();
    super.dispose();
  }

  Future<void> _realizarCadastro() async {
    // Validação apenas dos campos obrigatórios
    if (nomeController.text.trim().isEmpty || codigoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos obrigatórios.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbService = DatabaseService();

      // Tratando os campos opcionais (se estiver vazio, manda null para o banco)
      final String? contatoFinal = contatoController.text.trim().isEmpty ? null : contatoController.text.trim();
      final String? linkedinFinal = linkedinController.text.trim().isEmpty ? null : linkedinController.text.trim();

      await dbService.criarUsuario(
        email: emailController.text.trim(),
        nome: nomeController.text.trim(),
        crp: codigoController.text.trim(),
        contato: contatoFinal,
        linkedin: linkedinFinal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cadastro realizado com sucesso! Faça login para continuar.'),
              backgroundColor: Colors.green
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      String mensagemErro = 'Erro ao cadastrar. Tente novamente.';

      if (e.toString().contains('23505') || e.toString().contains('duplicate')) {
        mensagemErro = 'Este e-mail já está cadastrado.';
      } else {
        mensagemErro = 'Erro técnico: $e';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErro),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definindo as cores baseadas no seu tema
    const Color roxoPrincipal = Color(0xFF6A1B9A);
    final Color roxoClaro = Colors.purple.shade50;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastro de Voluntária"),
        backgroundColor: roxoPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ACOLHEDOR ---
            Container(
              color: roxoPrincipal,
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
              child: const Column(
                children: [
                  Icon(Icons.volunteer_activism, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Junte-se à nossa rede de apoio!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "O seu trabalho transforma vidas. Preencha os dados abaixo para criar sua conta na Ouvidoria da Mulher.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // --- FORMULÁRIO ---
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aviso de Obrigatoriedade
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: roxoClaro, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.purple.shade100)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 20, color: roxoPrincipal),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Os campos com * são obrigatórios. Os demais ajudam a Ouvidoria a conhecer melhor você!",
                              style: TextStyle(fontSize: 13, color: roxoPrincipal),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campos Obrigatórios
                    const Text("Dados de Acesso e Identificação", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 16),

                    TextField(
                      controller: emailController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "E-mail *",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        prefixIcon: const Icon(Icons.email_outlined),
                        suffixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: "Nome Completo *",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: codigoController,
                      decoration: InputDecoration(
                        labelText: "Registro Profissional (Ex: CRP) *",
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campos Opcionais
                    const Text("Informações de Contato (Opcionais)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                    const SizedBox(height: 16),

                    TextField(
                      controller: contatoController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Telefone / WhatsApp",
                        prefixIcon: const Icon(Icons.phone_android),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: linkedinController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        labelText: "Link do Perfil no LinkedIn",
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botão com Loading
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _realizarCadastro,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: roxoPrincipal,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("FINALIZAR CADASTRO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text("Voltar à tela de login"),
                        style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
