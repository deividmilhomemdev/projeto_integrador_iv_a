import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart'; // Necessário para usar TimeOfDay

class DatabaseService {
  final supabase = Supabase.instance.client;

  // ===========================================================================
  // 1. LOGIN
  // ===========================================================================
  Future<Map<String, dynamic>?> getUsuarioPorEmail(String email) async {
    try {
      final data = await supabase
          .from('tb_usuario')
          .select()
          .ilike('email', email)
          .maybeSingle();
      return data;
    } catch (e) {
      print('Erro ao buscar usuário: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 2. CADASTRO (Atualizado com campos opcionais)
  // ===========================================================================
  Future<Map<String, dynamic>> criarUsuario({
    required String email,
    required String nome,
    required String crp,
    String? contato, // Novo campo opcional
    String? linkedin, // Novo campo opcional
  }) async {
    try {
      final dadosUsuario = await supabase
          .from('tb_usuario')
          .insert({
        'email': email,
        'nome_usuario': nome,
        'crp': crp,
        'contato': contato,     // Se vier nulo, o banco aceita normalmente
        'linkedin': linkedin,   // Se vier nulo, o banco aceita normalmente
        'acesso_adm': 0,
      })
          .select()
          .single();
      return dadosUsuario;
    } catch (e) {
      print('Erro ao criar usuário: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // EDIÇÃO DE PERFIL DO USUÁRIO
  // ===========================================================================
  Future<void> atualizarPerfilUsuario({
    required int idUsuario,
    required String nome,
    required String crp,
    String? contato,
    String? linkedin,
  }) async {
    try {
      await supabase.from('tb_usuario').update({
        'nome_usuario': nome,
        'crp': crp,
        'contato': contato,
        'linkedin': linkedin,
      }).eq('id_usuario', idUsuario);
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // EDIÇÃO DE ASSISTIDA (CORREÇÃO DE CADASTRO) ✏️
  // ===========================================================================
  Future<void> atualizarAssistida({
    required int idAssistida,
    required String nome,
    required String contato,
  }) async {
    try {
      await supabase.from('tb_assistida').update({
        'nome': nome,
        'contato': contato,
      }).eq('id_assistida', idAssistida);
    } catch (e) {
      print('Erro ao atualizar assistida: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // EXCLUSÃO DEFINITIVA DE USUÁRIO (PERIGO) 🚨
  // ===========================================================================
  Future<void> excluirUsuarioCompleto(int idUsuario) async {
    try {
      // O PostgreSQL com a regra 'ON DELETE CASCADE' fará a limpeza das tabelas
      // tb_assistida e tb_sessao vinculadas a este ID de forma automática!
      await supabase.from('tb_usuario').delete().eq('id_usuario', idUsuario);
    } catch (e) {
      print('Erro ao excluir usuário completamente: $e');
      rethrow;
    }
  }


  // ===========================================================================
  // 3. HOME (Lista de Assistidas)
  // ===========================================================================
  Future<List<Map<String, dynamic>>> getAssistidas(int idUsuario) async {
    try {
      final data = await supabase
          .from('tb_assistida')
          .select()
          .eq('id_usuario', idUsuario)
          .order('nome', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar assistidas: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 4. AGENDAMENTO (Cascata com Prevenção de Duplicidade e Tratamento de Legado) 🛡️
  // ===========================================================================
  Future<void> realizarAgendamentoCompleto({
    required int idUsuario,
    required String nomeAssistida,
    required String contatoAssistida,
    required int numeroSessao,
    required DateTime dataSessao,
    required TimeOfDay horarioSessao,
  }) async {
    try {
      int idAssistidaFinal;

      // PASSO A: VERIFICAÇÃO DE EXISTÊNCIA (Agora blindado contra clones antigos)
      // Usamos .limit(1) em vez de .maybeSingle(). Se houver 9 duplicatas, ele pega a primeira e não quebra a tela!
      final listaAssistidaExistente = await supabase
          .from('tb_assistida')
          .select('id_assistida')
          .ilike('nome', nomeAssistida)
          .eq('contato', contatoAssistida)
          .eq('id_usuario', idUsuario)
          .limit(1);

      if (listaAssistidaExistente.isNotEmpty) {
        // REQ 1 (Verdadeiro): Assistida já existe! Captura o ID do primeiro registro encontrado.
        idAssistidaFinal = listaAssistidaExistente.first['id_assistida'];
        print("Assistida já cadastrada. Utilizando ID existente: $idAssistidaFinal");
      } else {
        // REQ 1 (Falso): Assistida não existe. Cria um novo registro limpo.
        final dadosAssistida = await supabase
            .from('tb_assistida')
            .insert({
          'id_usuario': idUsuario,
          'nome': nomeAssistida,
          'contato': contatoAssistida,
          'status_atendimento': '1',
        })
            .select()
            .single();

        idAssistidaFinal = dadosAssistida['id_assistida'];
        print("Nova assistida criada. Novo ID: $idAssistidaFinal");
      }

      // Formatando a hora com padLeft para evitar erros no banco
      final horarioFormatado = '${horarioSessao.hour.toString().padLeft(2, '0')}:${horarioSessao.minute.toString().padLeft(2, '0')}:00';

      // PASSO B: Criar Sessão vinculada ao ID correto
      await supabase.from('tb_sessao').insert({
        'id_assistida': idAssistidaFinal,
        'numero_sessao': numeroSessao,
        'data_sessao': dataSessao.toIso8601String(),
        'horario_sessao': horarioFormatado,
        'indicador_desistencia': '0',
        'indicador_sessao_realizada': '0',
      });
    } catch (e) {
      print('Erro crítico no agendamento: $e');
      rethrow;
    }
  }


  // Função para apagar definitivamente uma sessão lançada errada
  Future<void> excluirSessao(int idSessao) async {
    try {
      await supabase.from('tb_sessao').delete().eq('id_sessao', idSessao);
    } catch (e) {
      print('Erro ao excluir sessão: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // AGENDAMENTO PARA ASSISTIDA JÁ EXISTENTE (REQ 2 Garantido)
  // ===========================================================================
  Future<void> agendarSessaoExistente({
    required int idAssistida,
    required int numeroSessao,
    required DateTime dataSessao,
    required TimeOfDay horarioSessao,
  }) async {
    try {
      // Formatação segura de hora
      final horarioFormatado = '${horarioSessao.hour.toString().padLeft(2, '0')}:${horarioSessao.minute.toString().padLeft(2, '0')}:00';

      // REQ 2: Aqui NÃO tocamos na tb_assistida. Usamos o idAssistida passado.
      await supabase.from('tb_sessao').insert({
        'id_assistida': idAssistida,
        'numero_sessao': numeroSessao,
        'data_sessao': dataSessao.toIso8601String(),
        'horario_sessao': horarioFormatado,
        'indicador_desistencia': '0',
        'indicador_sessao_realizada': '0',
      });
    } catch (e) {
      print('Erro ao agendar sessão para assistida existente: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 5. VALIDAÇÃO (Pendentes) - COM FILTRO DE STATUS ATIVO
  // ===========================================================================
  Future<List<Map<String, dynamic>>> getSessoesPendentes(int idUsuario) async {
    try {
      final data = await supabase
          .from('tb_sessao')
          .select('*, tb_assistida!inner(id_usuario, nome, status_atendimento)')
          .eq('indicador_sessao_realizada', '0')
          .eq('indicador_desistencia', '0')
          .eq('tb_assistida.id_usuario', idUsuario)
          .eq('tb_assistida.status_atendimento', '1')
          .order('data_sessao', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar sessões pendentes: $e');
      rethrow;
    }
  }

  Future<void> marcarSessaoRealizada(int idSessao) async {
    await supabase.from('tb_sessao').update({'indicador_sessao_realizada': '1'}).eq('id_sessao', idSessao);
  }

  Future<void> registrarDesistencia(int idSessao) async {
    await supabase.from('tb_sessao').update({'indicador_desistencia': '1'}).eq('id_sessao', idSessao);
  }

  // ===========================================================================
  // 6. DASHBOARD E HISTÓRICO (Para a tela Sessões Registradas)
  // ===========================================================================
  Future<int> countAssistidasAtivas(int idUsuario) async {
    try {
      final response = await supabase
          .from('tb_assistida')
          .count()
          .eq('id_usuario', idUsuario)
          .eq('status_atendimento', '1');
      return response;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricoSessoes(int idUsuario) async {
    try {
      final data = await supabase
          .from('tb_sessao')
          .select('*, tb_assistida!inner(id_usuario, nome, contato)')
          .eq('tb_assistida.id_usuario', idUsuario)
          .order('data_sessao', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar histórico: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 7. INFORMAÇÕES (CMS)
  // ===========================================================================
  Future<List<Map<String, dynamic>>> getInformacoes() async {
    try {
      final data = await supabase
          .from('tb_informacoes')
          .select()
          .order('ordem', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // 8. GESTÃO ADMINISTRATIVA (NOVOS MÉTODOS) 👮‍♂️
  // ===========================================================================
  Future<List<Map<String, dynamic>>> getAllUsuarios() async {
    try {
      final data = await supabase
          .from('tb_usuario')
          .select()
          .order('nome_usuario', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar todos usuários: $e');
      rethrow;
    }
  }

  Future<void> promoverParaAdmin(int idUsuario) async {
    await supabase.from('tb_usuario').update({'acesso_adm': 1}).eq('id_usuario', idUsuario);
  }

  Future<List<Map<String, dynamic>>> getAllAssistidasAdmin() async {
    try {
      final data = await supabase
          .from('tb_assistida')
          .select('*, tb_usuario(id_usuario, nome_usuario)')
          .order('nome', ascending: true);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar assistidas admin: $e');
      rethrow;
    }
  }

  Future<void> transferirAssistida(int idAssistida, int novoIdUsuario) async {
    await supabase.from('tb_assistida').update({'id_usuario': novoIdUsuario}).eq('id_assistida', idAssistida);
  }

  Future<void> alterarStatusAssistida(int idAssistida, String novoStatus) async {
    await supabase.from('tb_assistida').update({'status_atendimento': novoStatus}).eq('id_assistida', idAssistida);
  }

  // ===========================================================================
  // 9. RELATÓRIOS E DASHBOARD 📊
  // ===========================================================================
  Future<List<Map<String, dynamic>>> getDadosRelatorioCompleto() async {
    try {
      final data = await supabase
          .from('tb_assistida')
          .select('''
            *,
            tb_usuario (id_usuario, nome_usuario),
            tb_sessao (*)
          ''')
          .order('nome', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar dados do relatório: $e');
      return [];
    }
  }

  // ===========================================================================
  // KPI: TOTAL DE VOLUNTÁRIAS CADASTRADAS (EXCETO ADMINS)
  // ===========================================================================
  Future<int> getTotalVoluntarias() async {
    try {
      // Busca todos os usuários excluindo aqueles que têm nível de acesso 1 (Admin)
      final List<dynamic> response = await supabase
          .from('tb_usuario')
          .select('id_usuario')
          .neq('acesso_adm', 1);

      return response.length;
    } catch (e) {
      print('Erro ao buscar total de voluntárias: $e');
      return 0; // Em caso de erro, retorna 0 para não quebrar a tela
    }
  }
}
