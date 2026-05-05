import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestConnectionPage extends StatefulWidget {
  const TestConnectionPage({super.key});

  @override
  State<TestConnectionPage> createState() => _TestConnectionPageState();
}

class _TestConnectionPageState extends State<TestConnectionPage> {
  String mensagem = "Clique para testar a conexão com Supabase.";
  Color corMensagem = Colors.black;
  bool isLoading = false;

  Future<void> testar() async {
    setState(() {
      isLoading = true;
      mensagem = "Enviando sinal para o espaço... 📡";
      corMensagem = Colors.blue;
    });

    try {
      // Tenta buscar apenas 1 registro qualquer para ver se o banco responde
      final supabase = Supabase.instance.client;

      // O comando .count() é super leve, perfeito para testes
      final response = await supabase
          .from('tb_usuario')
          .select()
          .limit(1);

      setState(() {
        mensagem = "Sucesso! Supabase respondeu: ${response.length} linhas encontradas. 🟢 pegou o código?!";
        corMensagem = Colors.green;
      });

      print("Dados recebidos: $response");

    } catch (e) {
      setState(() {
        mensagem = "Falha na missão: $e 🔴";
        corMensagem = Colors.red;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Teste Supabase")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mostra ícone do Supabase ou Loading
              isLoading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.cloud_done_outlined, size: 60, color: Colors.green),

              const SizedBox(height: 20),

              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: corMensagem, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: isLoading ? null : testar,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text("Testar Conexão Agora"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}