import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplicacao/pages/informacoes.dart';

void main() {
  group('Testes Funcionais (Widgets) - Tela de Detalhes', () {

    testWidgets('Deve exibir o título e o conteúdo corretamente na tela', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetalheTextoPage(
            titulo: 'Aviso da Ouvidoria',
            conteudo: 'Este é um teste funcional simulando a leitura de um documento.',
          ),
        ),
      );

      // Verifica se os textos principais apareceram na tela
      expect(find.text('Aviso da Ouvidoria'), findsOneWidget);
      expect(find.text('Este é um teste funcional simulando a leitura de um documento.'), findsOneWidget);


      expect(find.text('Acessar Página Oficial'), findsNothing);
    });

    testWidgets('Deve renderizar o botão de link se a URL for fornecida', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DetalheTextoPage(
            titulo: 'Guia com Link',
            conteudo: 'Acesse o site abaixo.',
            linkUrl: 'https://ouvidoriadamulhergoianiavoluntariado.netlify.app/',
          ),
        ),
      );

      expect(find.text('Acessar Página Oficial'), findsOneWidget);
      expect(find.byIcon(Icons.public), findsOneWidget);
    });

  });
}