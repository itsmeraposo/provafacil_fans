import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Preferências locais (SharedPreferences): ficam guardadas no aparelho (ou no
/// navegador) e permanecem depois de fechar e abrir o app, sem depender do
/// servidor. Os dados de verdade (questões, provas) continuam no Firestore.
class Preferencias {
  static const String _chaveTextoGrande = 'textoGrande';

  /// Último erro ao ler/gravar no aparelho (para mostrar na tela e achar o
  /// problema quando o app roda sem console, como num APK).
  static String? ultimoErro;

  /// Letras maiores em todo o app. Quem escuta (main.dart) reage na hora.
  static final ValueNotifier<bool> textoGrande = ValueNotifier<bool>(false);

  /// Lê o que foi salvo da última vez. Chamado uma vez ao abrir o app.
  static Future<void> carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      textoGrande.value = prefs.getBool(_chaveTextoGrande) ?? false;
      debugPrint('Preferencias.carregar: textoGrande=${textoGrande.value}');
    } catch (erro) {
      // Sem armazenamento local disponível: segue com o padrão.
      ultimoErro = '$erro';
      debugPrint('Preferencias.carregar falhou: $erro');
    }
  }

  /// Aplica na hora e grava para a próxima vez que o app abrir.
  /// Devolve `false` se não conseguiu gravar no aparelho.
  static Future<bool> definirTextoGrande(bool valor) async {
    textoGrande.value = valor;
    try {
      final prefs = await SharedPreferences.getInstance();
      final salvou = await prefs.setBool(_chaveTextoGrande, valor);
      if (!salvou) ultimoErro = 'setBool devolveu false (gravação recusada)';
      debugPrint('Preferencias.definirTextoGrande($valor): salvou=$salvou');
      return salvou;
    } catch (erro) {
      ultimoErro = '$erro';
      debugPrint('Preferencias: não foi possível gravar: $erro');
      return false;
    }
  }

  /* ------------------------------------- cópia local da lista de questões */

  static String _chaveQuestoes(String usuarioId) => 'questoesCache:$usuarioId';

  /// Guarda a última lista de questões recebida do servidor, para o app ainda
  /// mostrar algo quando o servidor ou a internet falharem.
  static Future<void> salvarQuestoesCache(
    String usuarioId,
    List<Questao> questoes,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chaveQuestoes(usuarioId),
        jsonEncode(questoes.map((q) => q.toJson()).toList()),
      );
    } catch (erro) {
      debugPrint('Preferencias: não foi possível gravar: $erro');
    }
  }

  /// Devolve a última lista guardada, ou `null` se nunca houve uma.
  static Future<List<Questao>?> lerQuestoesCache(String usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bruto = prefs.getString(_chaveQuestoes(usuarioId));
      if (bruto == null) return null;
      final lista = jsonDecode(bruto);
      if (lista is! List) return null;
      return lista
          .whereType<Map<String, dynamic>>()
          .map(Questao.fromJson)
          .toList();
    } catch (erro) {
      debugPrint('Preferencias: não foi possível ler: $erro');
      return null;
    }
  }

  /* ----------------------- questões cadastradas sem conexão (pendentes) */

  static String _chavePendentes(String usuarioId) =>
      'questoesPendentes:$usuarioId';

  /// Questões criadas sem conexão, ainda não enviadas ao servidor.
  static Future<List<Questao>> lerPendentes(String usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bruto = prefs.getString(_chavePendentes(usuarioId));
      if (bruto == null) return [];
      final lista = jsonDecode(bruto);
      if (lista is! List) return [];
      return lista
          .whereType<Map<String, dynamic>>()
          .map(Questao.fromJson)
          .toList();
    } catch (erro) {
      debugPrint('Preferencias: não foi possível ler: $erro');
      return [];
    }
  }

  static Future<void> salvarPendentes(
    String usuarioId,
    List<Questao> pendentes,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chavePendentes(usuarioId),
        jsonEncode(pendentes.map((q) => q.toJson()).toList()),
      );
    } catch (erro) {
      debugPrint('Preferencias: não foi possível gravar: $erro');
    }
  }

  /* ------------------------------- último usuário que entrou (modo offline) */

  static String _chaveUsuario(String perfil) => 'usuarioOffline:$perfil';

  /// Guarda os dados do usuário do acesso direto, devolvidos pelo servidor,
  /// para o app conseguir abrir o painel mesmo sem conexão.
  static Future<void> salvarUsuarioOffline(
    String perfil,
    Map<String, dynamic> usuario,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chaveUsuario(perfil), jsonEncode(usuario));
    } catch (erro) {
      debugPrint('Preferencias: não foi possível gravar usuário: $erro');
    }
  }

  static Future<Usuario?> lerUsuarioOffline(String perfil) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bruto = prefs.getString(_chaveUsuario(perfil));
      if (bruto == null) return null;
      final dados = jsonDecode(bruto);
      if (dados is! Map<String, dynamic>) return null;
      return Usuario.fromJson(dados);
    } catch (erro) {
      debugPrint('Preferencias: não foi possível ler usuário: $erro');
      return null;
    }
  }
}
