import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // <--- O IMPORT MÁGICO DO IDIOMA AQUI

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/cadastro_page.dart';
import 'pages/agendamento.dart';
import 'pages/validacao_sessao.dart';
import 'pages/registro_sessao.dart';
import 'pages/informacoes.dart';
import 'pages/gestao_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // === PALETA DE CORES DA OUVIDORIA ===
  static const Color roxoPrincipal = Color(0xFF6A1B9A); // Roxo Profundo
  static const Color roxoClaro = Color(0xFF9C4DCC);     // Lilás
  static const Color brancoGelo = Color(0xFFF5F5F5);    // Fundo suave

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Aplicativo Ouvidoria da Mulher",

      // === CONFIGURAÇÃO DE IDIOMA E LOCALIZAÇÃO (PT-BR) ===
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Força o sistema a adotar o Brasil
      ],

      // === TEMA PERSONALIZADO (ROXO) ===
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: roxoPrincipal,
          primary: roxoPrincipal,
          secondary: roxoClaro,
          background: brancoGelo,
        ),

        // AppBar Roxa
        appBarTheme: const AppBarTheme(
          backgroundColor: roxoPrincipal,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 4,
        ),

        // Botões Roxos
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: roxoPrincipal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Inputs com foco Roxo
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: roxoPrincipal, width: 2),
          ),
          prefixIconColor: roxoPrincipal,
          labelStyle: const TextStyle(color: Colors.black87),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: roxoPrincipal,
          foregroundColor: Colors.white,
        ),
      ),

      // === ROTAS ===
      initialRoute: '/login', // Começa no Login
      routes: {
        // Rota raiz '/' ou '/login', você decide. Vou manter '/login' como padrão do código anterior
        '/login': (context) => const LoginPage(),
        '/': (context) => const LoginPage(), // Redireciona raiz pro login também

        '/home': (context) => const HomePage(),
        '/cadastro': (context) => const CadastroPage(),

        // Rotas internas
        '/agendar': (context) => const AgendarSessao(),
        '/validar': (context) => const ValidarSessao(),
        '/registradas': (context) => const SessoesRegistradas(),
        '/informacoes': (context) => const MaisInfo(),
        '/gestao': (context) => const GestaoPage(),
      },
    );
  }
}