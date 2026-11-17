import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda o token de acesso (JWT) em armazenamento seguro: no Android usa o
/// Keystore, e no navegador a criptografia do próprio navegador (WebCrypto).
/// Diferente do SharedPreferences, o valor não fica em texto puro.
///
/// Qualquer falha (aparelho sem suporte, navegador sem HTTPS) é ignorada: o
/// app continua funcionando com o token só em memória.
class ArmazenamentoToken {
  ArmazenamentoToken._();

  static const String _chave = 'provafacil_token_sessao';
  static const FlutterSecureStorage _cofre = FlutterSecureStorage();

  static Future<void> salvar(String token) async {
    try {
      await _cofre.write(key: _chave, value: token);
    } catch (_) {}
  }

  static Future<String?> ler() async {
    try {
      return await _cofre.read(key: _chave);
    } catch (_) {
      return null;
    }
  }

  static Future<void> apagar() async {
    try {
      await _cofre.delete(key: _chave);
    } catch (_) {}
  }
}
