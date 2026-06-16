class RegrasNegocio {
  static bool verificarAcessoAdmin(dynamic acessoAdm) {
    if (acessoAdm == null) return false;
    // Retorna true se for o inteiro 1 ou a string '1'
    return acessoAdm == 1 || acessoAdm == '1';
  }

  static bool validarNomePreenchido(String? nome) {
    if (nome == null || nome.trim().isEmpty) return false;
    return true;
  }
}