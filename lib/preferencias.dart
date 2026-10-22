import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Edição de uma prova que já existe no servidor, feita sem conexão e
/// guardada no aparelho. [acao]: `rascunho`, `enviar`, `pdf` ou `docx`.
class EdicaoLocal {
  EdicaoLocal(this.prova, this.acao);

  final Prova prova;
  final String acao;
}

/// Preferências locais (SharedPreferences): ficam guardadas no aparelho (ou no
/// navegador) e permanecem depois de fechar e abrir o app, sem depender do
/// servidor. Os dados de verdade (questões, provas) continuam no Firestore.
class Preferencias {
  static const String _chaveTextoGrande = 'textoGrande';

  /// Último erro ao ler/gravar no aparelho (para mostrar na tela e achar o
  /// problema quando o app roda sem console, como num APK).
  static String? ultimoErro;

  /// Rascunho de prova NOVA guardado no aparelho (e o que fazer com ele
  /// quando a conexão voltar). As telas escutam para mostrá-lo na lista de
  /// rascunhos, com o aviso de "sem conexão".
  static final ValueNotifier<Prova?> rascunhoLocal = ValueNotifier<Prova?>(null);
  static final ValueNotifier<String?> acaoRascunhoLocal =
      ValueNotifier<String?>(null);

  /// Lê do aparelho o rascunho local do usuário e avisa as telas.
  static Future<void> atualizarRascunhoLocal(String usuarioId) async {
    rascunhoLocal.value = await lerRascunhoLocal(usuarioId);
    acaoRascunhoLocal.value = await lerAcaoPendente(usuarioId);
  }

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

  /* --------------------- rascunho de prova guardado no aparelho (local) */

  static String _chaveRascunhoLocal(String usuarioId) =>
      'provaRascunhoLocal:$usuarioId';

  /// Guarda a prova que o professor está montando (ainda não enviada ao
  /// servidor), para ele continuar depois de fechar o app.
  static Future<void> salvarRascunhoLocal(String usuarioId, Prova prova) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chaveRascunhoLocal(usuarioId),
        jsonEncode(prova.toLocalJson()),
      );
      rascunhoLocal.value = prova;
    } catch (erro) {
      debugPrint('Preferencias: não foi possível gravar rascunho: $erro');
    }
  }

  /// Devolve o rascunho local, ou `null` se não houver.
  static Future<Prova?> lerRascunhoLocal(String usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bruto = prefs.getString(_chaveRascunhoLocal(usuarioId));
      if (bruto == null) return null;
      final dados = jsonDecode(bruto);
      if (dados is! Map<String, dynamic>) return null;
      return Prova.fromJson(dados);
    } catch (erro) {
      debugPrint('Preferencias: não foi possível ler rascunho: $erro');
      return null;
    }
  }

  static String _chaveAcaoPendente(String usuarioId) =>
      'provaAcaoPendente:$usuarioId';

  /// O que fazer com o rascunho local quando a conexão voltar: `enviar`
  /// (enviar ao coordenador), `pdf` ou `docx` (gerar o arquivo). Sem ação
  /// guardada, o rascunho só é salvo no servidor.
  static Future<void> salvarAcaoPendente(String usuarioId, String acao) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chaveAcaoPendente(usuarioId), acao);
      acaoRascunhoLocal.value = acao;
    } catch (erro) {
      debugPrint('Preferencias: não foi possível gravar ação: $erro');
    }
  }

  static Future<String?> lerAcaoPendente(String usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_chaveAcaoPendente(usuarioId));
    } catch (erro) {
      debugPrint('Preferencias: não foi possível ler ação: $erro');
      return null;
    }
  }

  static Future<void> apagarAcaoPendente(String usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chaveAcaoPendente(usuarioId));
      acaoRascunhoLocal.value = null;
    } catch (erro) {
      debugPrint('Preferencias: não foi possível apagar ação: $erro');
    }
  }

  static Future<void> apagarRascunhoLocal(String usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chaveAcaoPendente(usuarioId));
      await prefs.remove(_chaveRascunhoLocal(usuarioId));
      acaoRascunhoLocal.value = null;
      rascunhoLocal.value = null;
    } catch (erro) {
      debugPrint('Preferencias: não foi possível apagar rascunho: $erro');
    }
  }

  /* ------------- edições offline de provas que já estão no servidor */

  static String _chaveEdicoes(String usuarioId) => 'provaEdicoes:$usuarioId';

  static Future<Map<String, dynamic>> _lerEdicoesBrutas(String usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bruto = prefs.getString(_chaveEdicoes(usuarioId));
      if (bruto == null) return {};
      final dados = jsonDecode(bruto);
      return dados is Map<String, dynamic> ? dados : {};
    } catch (erro) {
      debugPrint('Preferencias: não foi possível ler edições: $erro');
      return {};
    }
  }

  static Future<void> _gravarEdicoesBrutas(
    String usuarioId,
    Map<String, dynamic> dados,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (dados.isEmpty) {
        await prefs.remove(_chaveEdicoes(usuarioId));
      } else {
        await prefs.setString(_chaveEdicoes(usuarioId), jsonEncode(dados));
      }
    } catch (erro) {
      debugPrint('Preferencias: não foi possível gravar edições: $erro');
    }
  }

  /// Guarda (ou troca) a edição da prova [prova] (que tem `id` do servidor).
  static Future<void> salvarEdicaoLocal(
    String usuarioId,
    Prova prova,
    String acao,
  ) async {
    final dados = await _lerEdicoesBrutas(usuarioId);
    dados[prova.id] = {'acao': acao, 'prova': prova.toLocalJson()};
    await _gravarEdicoesBrutas(usuarioId, dados);
  }

  static Future<List<EdicaoLocal>> lerEdicoesLocais(String usuarioId) async {
    final dados = await _lerEdicoesBrutas(usuarioId);
    final lista = <EdicaoLocal>[];
    for (final item in dados.values) {
      if (item is! Map<String, dynamic>) continue;
      final prova = item['prova'];
      if (prova is! Map<String, dynamic>) continue;
      lista.add(EdicaoLocal(
        Prova.fromJson(prova),
        (item['acao'] ?? 'rascunho').toString(),
      ));
    }
    return lista;
  }

  static Future<void> apagarEdicaoLocal(String usuarioId, String provaId) async {
    final dados = await _lerEdicoesBrutas(usuarioId);
    if (dados.remove(provaId) != null) {
      await _gravarEdicoesBrutas(usuarioId, dados);
    }
  }

  /* ------------------------------ cópia local da lista de provas */

  static String _chaveProvas(String usuarioId) => 'provasCache:$usuarioId';

  /// Guarda a última lista de provas recebida do servidor (JSON como veio),
  /// para o app ainda mostrá-las e permitir editar sem conexão.
  static Future<void> salvarProvasCache(
    String usuarioId,
    List<Map<String, dynamic>> provas,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chaveProvas(usuarioId), jsonEncode(provas));
    } catch (erro) {
      debugPrint('Preferencias: não foi possível gravar provas: $erro');
    }
  }

  static Future<List<Prova>?> lerProvasCache(String usuarioId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bruto = prefs.getString(_chaveProvas(usuarioId));
      if (bruto == null) return null;
      final lista = jsonDecode(bruto);
      if (lista is! List) return null;
      return lista
          .whereType<Map<String, dynamic>>()
          .map(Prova.fromJson)
          .toList();
    } catch (erro) {
      debugPrint('Preferencias: não foi possível ler provas: $erro');
      return null;
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
