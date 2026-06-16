// pegou o código?! Arquitetura híbrida limpa, validada e pronta pro deploy! 🚀
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database.dart'; // Verifique se o caminho está correto para o seu projeto

class MaisInfo extends StatefulWidget {
  final bool isAdmin;

  const MaisInfo({super.key, this.isAdmin = false});

  @override
  State<MaisInfo> createState() => _MaisInfoState();
}

class _MaisInfoState extends State<MaisInfo> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _infos = [];
  final DatabaseService _db = DatabaseService();

  final Color roxoPrincipal = const Color(0xFF6A1B9A);

  // 1. Variável local para guardar o poder
  bool _isAdminLocal = false;

  @override
  void initState() {
    super.initState();
    _carregarConteudo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Captura os argumentos da rota
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is bool) {
      _isAdminLocal = args;
    }
  }

  Future<void> _carregarConteudo() async {
    try {
      final dados = await _db.getInformacoes();
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

  Future<void> _deletarInformativo(int id) async {
    try {
      await _db.excluirInformacao(id);
      _mostrarMensagem("Informativo excluído com sucesso!", Colors.green);
      _carregarConteudo();
    } catch (e) {
      _mostrarErro(context, "Erro ao excluir informativo.");
    }
  }

  void _confirmarExclusao(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Exclusão"),
        content: const Text("Tem certeza que deseja apagar este informativo definitivamente?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletarInformativo(id);
            },
            child: const Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // === LÓGICA DE UPLOAD HÍBRIDO (WEB & MOBILE) ===
  Future<String?> _fazerUploadHibrido(dynamic arquivo, String tipo) async {
    try {
      final extensao = tipo == 'imagem' ? 'png' : 'pdf';
      final nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}.$extensao';
      final supabase = Supabase.instance.client;

      if (arquivo is XFile) {
        final bytes = await arquivo.readAsBytes();
        await supabase.storage.from('informativos').uploadBinary(nomeArquivo, bytes);
      }
      else if (arquivo is PlatformFile) {
        if (arquivo.bytes != null) {
          await supabase.storage.from('informativos').uploadBinary(nomeArquivo, arquivo.bytes!);
        }
        else if (arquivo.path != null) {
          final file = File(arquivo.path!);
          await supabase.storage.from('informativos').upload(nomeArquivo, file);
        } else {
          throw Exception("Arquivo inválido. Caminho e bytes estão nulos.");
        }
      }

      final urlPublica = supabase.storage.from('informativos').getPublicUrl(nomeArquivo);
      return urlPublica;
    } catch (e) {
      print('Erro no upload: $e');
      return null;
    }
  }

  void _exibirDialogoCadastro() {
    final txtTitulo = TextEditingController();
    final txtDescricao = TextEditingController();
    final txtConteudo = TextEditingController();
    String tipoSelecionado = 'texto';

    // Novas variáveis universais para substituir o antigo 'File'
    XFile? arquivoXFile;
    PlatformFile? arquivoPlatform;
    String? nomeArquivoTela;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nova Informação", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: txtTitulo, decoration: const InputDecoration(labelText: "Título *")),
                TextField(controller: txtDescricao, decoration: const InputDecoration(labelText: "Descrição (Breve resumo)")),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: tipoSelecionado,
                  decoration: const InputDecoration(labelText: "Tipo de Conteúdo"),
                  items: const [
                    DropdownMenuItem(value: 'texto', child: Text("Texto Longo Interno")),
                    DropdownMenuItem(value: 'pdf', child: Text("Arquivo PDF")),
                    DropdownMenuItem(value: 'imagem', child: Text("Imagem da Galeria")),
                  ],
                  onChanged: (val) {
                    setDialogState(() {
                      tipoSelecionado = val!;
                      arquivoXFile = null;
                      arquivoPlatform = null;
                      nomeArquivoTela = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                if (tipoSelecionado == 'texto')
                  TextField(
                      controller: txtConteudo,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: "Conteúdo do Texto *", alignLabelWithHint: true)
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: Text((arquivoXFile == null && arquivoPlatform == null) ? "Selecionar Arquivo" : "Trocar Arquivo"),
                        onPressed: () async {
                          if (tipoSelecionado == 'imagem') {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setDialogState(() {
                                arquivoXFile = pickedFile;
                                arquivoPlatform = null;
                                nomeArquivoTela = pickedFile.name;
                              });
                            }
                          } else if (tipoSelecionado == 'pdf') {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                              withData: true, // Garante que a Web consiga ler o PDF
                            );
                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                arquivoPlatform = result.files.first;
                                arquivoXFile = null;
                                nomeArquivoTela = result.files.first.name;
                              });
                            }
                          }
                        },
                      ),
                      if (nomeArquivoTela != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Selecionado: $nomeArquivoTela", style: const TextStyle(fontSize: 12, color: Colors.green)),
                        )
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            if (!isUploading)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: roxoPrincipal),
              onPressed: isUploading ? null : () async {
                // Validações básicas ajustadas
                if (txtTitulo.text.isEmpty) {
                  _mostrarMensagem("O título é obrigatório.", Colors.orange);
                  return;
                }
                if (tipoSelecionado == 'texto' && txtConteudo.text.isEmpty) {
                  _mostrarMensagem("Preencha o conteúdo do texto.", Colors.orange);
                  return;
                }
                if (tipoSelecionado != 'texto' && arquivoXFile == null && arquivoPlatform == null) {
                  _mostrarMensagem("Por favor, selecione um arquivo.", Colors.orange);
                  return;
                }

                setDialogState(() => isUploading = true);

                String? urlFinal;

                // Fluxo de Upload Universal
                if (tipoSelecionado != 'texto') {
                  final arquivoParaSubir = tipoSelecionado == 'imagem' ? arquivoXFile : arquivoPlatform;

                  urlFinal = await _fazerUploadHibrido(arquivoParaSubir, tipoSelecionado);

                  if (urlFinal == null) {
                    setDialogState(() => isUploading = false);
                    _mostrarMensagem("Falha ao enviar arquivo para o servidor.", Colors.red);
                    return;
                  }
                }

                // Grava no banco de dados
                await _db.adicionarInformacao(
                  titulo: txtTitulo.text,
                  descricao: txtDescricao.text.isEmpty ? null : txtDescricao.text,
                  tipo: tipoSelecionado,
                  url: urlFinal,
                  conteudo: tipoSelecionado == 'texto' ? txtConteudo.text : null,
                  ordem: _infos.length + 1,
                );

                if (context.mounted) Navigator.pop(context);
                _mostrarMensagem("Informativo adicionado com sucesso!", Colors.green);
                _carregarConteudo();
              },
              child: isUploading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Salvar", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirLinkedinDeivid() async {
    final Uri url = Uri.parse('https://www.linkedin.com/in/deivid-milhomem-ba7777135/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _mostrarErro(context, 'Não foi possível abrir o link do LinkedIn.');
    }
  }

  void _mostrarMensagem(String msg, Color cor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: cor));
    }
  }

  void _mostrarErro(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
      floatingActionButton: _isAdminLocal
          ? FloatingActionButton(
        backgroundColor: roxoPrincipal,
        onPressed: _exibirDialogoCadastro,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: roxoPrincipal,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
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
                  "Esta página é o seu portal de comunicação interna. Aqui você encontra guias, manuais, cartilhas e informações institucionais de apoio preparadas pela Ouvidoria.",
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
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
                          if (_isAdminLocal)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _confirmarExclusao(item['id']),
                            ),
                          Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade300))),
            child: InkWell(
              onTap: _abrirLinkedinDeivid,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text("Aplicativo voluntário originado de um projeto acadêmico.", style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Desenvolvido por ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text("Deivid Milhomem", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: roxoPrincipal, decoration: TextDecoration.underline)),
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
      Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheTextoPage(titulo: titulo, conteudo: conteudo, linkUrl: url)));
    } else if (tipo == 'imagem') {
      if (url.isNotEmpty) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetalheImagemPage(titulo: titulo, url: url)));
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
      _mostrarErro(context, "Não foi possível abrir o link.");
    }
  }
}

// ==========================================
// CLASSES AUXILIARES (Páginas de Detalhes)
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