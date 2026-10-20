/// Mesma regra de senha forte do servidor (auth.js): 10+ caracteres, com
/// maiúscula, minúscula, número e caractere especial.
String? validarSenhaForte(String? senha) {
  final texto = senha ?? '';
  final faltando = <String>[];
  if (texto.length < 10) faltando.add('10 caracteres');
  if (!RegExp(r'[a-z]').hasMatch(texto)) faltando.add('letra minúscula');
  if (!RegExp(r'[A-Z]').hasMatch(texto)) faltando.add('letra maiúscula');
  if (!RegExp(r'[0-9]').hasMatch(texto)) faltando.add('número');
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(texto)) {
    faltando.add('caractere especial');
  }
  if (faltando.isEmpty) return null;
  return 'A senha precisa ter: ${faltando.join(', ')}.';
}

String? validarEmail(String? email) {
  final texto = (email ?? '').trim();
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(texto)
      ? null
      : 'Informe um e-mail válido';
}
