import 'package:flutter_test/flutter_test.dart';
import 'package:aplicacao/utils/regras_negocio.dart';

void main() {
  group('Testes da Classe RegrasNegocio (Validações de Usuário)', () {

    // --- BLOCO 1: TESTANDO A LÓGICA DE ADMIN
    test('Deve retornar TRUE quando o acesso for o inteiro 1', () {
      int acesso = 1;

      bool resultado = RegrasNegocio.verificarAcessoAdmin(acesso);

      expect(resultado, isTrue);
    });

    test('Deve retornar TRUE quando o acesso for a string "1"', () {
      bool resultado = RegrasNegocio.verificarAcessoAdmin('1');
      expect(resultado, isTrue);
    });

    test('Deve retornar FALSE quando o acesso for diferente de 1 (ex: 0)', () {
      bool resultado = RegrasNegocio.verificarAcessoAdmin(0);
      expect(resultado, isFalse);
    });

    test('Deve retornar FALSE quando o acesso for nulo', () {
      bool resultado = RegrasNegocio.verificarAcessoAdmin(null);
      expect(resultado, isFalse);
    });

    // --- BLOCO 2: TESTANDO A VALIDAÇÃO DE NOME
    test('Deve retornar FALSE se o nome for apenas espaços em branco', () {
      bool resultado = RegrasNegocio.validarNomePreenchido('    ');
      expect(resultado, isFalse);
    });

    test('Deve retornar TRUE se o nome for válido', () {
      bool resultado = RegrasNegocio.validarNomePreenchido('Deivid Milhomem');
      expect(resultado, isTrue);
    });

  });
}

