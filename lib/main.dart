import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importamos o seu arquivo de estrutura do app
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // MUDANÇA AQUI: Tira o ponto do nome do arquivo
    await dotenv.load(fileName: "env");
    print("Arquivo env carregado com sucesso! 🔐");
  } catch (e) {
    print("⚠️ ERRO CRÍTICO: Não foi possível carregar o env");
    print("Detalhe: $e");
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    print("Supabase inicializado! 🚀");
  } else {
    print("❌ ERRO: Chaves do Supabase não encontradas no env");
  }

  runApp(const MyApp());
}