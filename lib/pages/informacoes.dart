import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
// Certifique-se que o caminho para o seu database está correto
import '../services/database.dart';

class MaisInfo extends StatefulWidget {
  const MaisInfo({super.key});

  @override
  State<MaisInfo> createState() => _MaisInfoState();
}

class _MaisInfoState extends State<MaisInfo> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _infos = [];

  final Color roxoPrincipal = const Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    _carregarConteudo();
  }

  Future<void> _carregarConteudo() async {
    try {
      final db = DatabaseService();
      final dados = await db.getInformacoes();

      if (mounted) {
        setState(() {
          _infos = dados;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao carregar informações: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Função para abrir o LinkedIn ---
  Future<void> _abrirLinkedinDeivid() async {
    final Uri url = Uri.parse('https://www.linkedin.com/in/deivid-milhomem-ba7777135/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _mostrarErro(context, 'Não foi possível abrir o link do LinkedIn.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Central de Apoio", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: roxoPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // === REQ 2: HEADER ACOLHEDOR ===
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: roxoPrincipal,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.library_books, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text("Materiais e Informações", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  "Esta página é o seu portal de comunicação interna. Aqui você encontra guias, manuais, cartilhas e informações institucionais de apoio preparadas pela Ouvidoria. Sinta-se à vontade para explorar e tirar suas dúvidas!",
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),

          // === LISTA DE CONTEÚDOS ===
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: roxoPrincipal))
                : _infos.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text("Nenhum material disponível no momento.", style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _infos.length,
              itemBuilder: (context, index) {
                final item = _infos[index];

                IconData icone;
                Color corIcone;

                switch (item['tipo']) {
                  case 'pdf':
                    icone = Icons.picture_as_pdf;
                    corIcone = Colors.redAccent;
                    break;
                  case 'imagem':
                    icone = Icons.image;
                    corIcone = Colors.blueAccent;
                    break;
                  case 'texto':
                  default:
                    icone = Icons.article;
                    corIcone = Colors.orangeAccent;
                }

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _abrirConteudo(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: corIcone.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(icone, color: corIcone, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['titulo'] ?? 'Sem Título',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['descricao'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // === REQ 4: RODAPÉ (CRÉDITOS ACADÊMICOS) ===
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: InkWell(
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
          ),
        ],
      ),
    );
  }

  void _abrirConteudo(BuildContext context, Map<String, dynamic> info) {
    final tipo = info['tipo'];
    final url = info['url'] ?? '';
    final titulo = info['titulo'] ?? 'Detalhe';
    final conteudo = info['conteudo'] ?? '';

    if (tipo == 'texto') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalheTextoPage(
            titulo: titulo,
            conteudo: conteudo,
            linkUrl: url,
          ),
        ),
      );
    } else if (tipo == 'imagem') {
      if (url.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetalheImagemPage(titulo: titulo, url: url),
          ),
        );
      } else {
        _mostrarErro(context, "URL da imagem não encontrada.");
      }
    } else if (tipo == 'pdf') {
      if (url.isNotEmpty) {
        _abrirLinkExterno(context, url);
      } else {
        _mostrarErro(context, "Link do PDF indisponível.");
      }
    }
  }

  Future<void> _abrirLinkExterno(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print("Erro URL: $e");
      _mostrarErro(context, "Não foi possível abrir o link.");
    }
  }

  void _mostrarErro(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }
}

// ==========================================
// TELA DE TEXTO COM LINK OPCIONAL (Atualizada!)
// ==========================================
class DetalheTextoPage extends StatelessWidget {
  final String titulo;
  final String conteudo;
  final String? linkUrl;

  const DetalheTextoPage({
    super.key,
    required this.titulo,
    required this.conteudo,
    this.linkUrl,
  });

  Future<void> _abrirLink() async {
    if (linkUrl == null || linkUrl!.isEmpty) return;
    final uri = Uri.parse(linkUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color roxoPrincipal = Color(0xFF6A1B9A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: roxoPrincipal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conteudo,
              style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 40),
            if (linkUrl != null && linkUrl!.isNotEmpty)
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _abrirLink,
                    icon: const Icon(Icons.public, color: Colors.white),
                    label: const Text("Acessar Página Oficial", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roxoPrincipal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DetalheImagemPage extends StatelessWidget {
  final String titulo;
  final String url;

  const DetalheImagemPage({
    super.key,
    required this.titulo,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    const Color roxoPrincipal = Color(0xFF6A1B9A);

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        backgroundColor: roxoPrincipal,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text("Erro ao carregar imagem", style: TextStyle(color: Colors.white)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
