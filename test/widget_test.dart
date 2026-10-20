import 'package:flutter_test/flutter_test.dart';

import 'package:provafacil_fans/validators.dart';

void main() {
  group('validarEmail', () {
    test('aceita e-mail válido', () {
      expect(validarEmail('prof@fans.edu.br'), isNull);
    });

    test('recusa e-mail inválido ou vazio', () {
      expect(validarEmail('prof@'), isNotNull);
      expect(validarEmail('sem-arroba.com'), isNotNull);
      expect(validarEmail(''), isNotNull);
    });
  });

  group('validarSenhaForte', () {
    test('aceita senha forte', () {
      expect(validarSenhaForte('Senha#Forte123'), isNull);
    });

    test('recusa senha curta ou sem requisitos', () {
      expect(validarSenhaForte('123'), isNotNull);
      expect(validarSenhaForte('somenteminusculas'), isNotNull);
    });
  });
}
