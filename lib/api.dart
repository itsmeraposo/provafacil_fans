import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:http/http.dart' as http;

import 'config.dart';

/// Erro devolvido pela API (ou falha de conexão), já com mensagem pronta
/// para mostrar ao usuário.
class ApiException implements Exception {
  ApiException(this.mensagem, {this.status, this.dados});

  final String mensagem;
  final int? status;

  /// Corpo JSON da resposta de erro (ex.: `emailNaoVerificado: true`).
  final Map<String, dynamic>? dados;

  @override
  String toString() => mensagem;
}

/// Cliente HTTP do servidor.
///
/// O backend devolve um token de sessão (JWT) no corpo do login, e o app o
/// reenvia em toda requisição no cabeçalho `Authorization: Bearer <token>`.
/// Isso funciona igual no Android e no navegador (o navegador não permite
/// ler `set-cookie` nem enviar o cabeçalho `Cookie` por código).
class ApiClient {
  ApiClient._();

  static final ApiClient instancia = ApiClient._();

  static const Duration _limiteTempo = Duration(seconds: 40);

  final http.Client _http = http.Client();
  String? _sessao;

  /// Chamado quando o servidor diz que a sessão acabou (401 com mensagem de
  /// sessão). O app usa isso para voltar ao login.
  void Function()? aoSessaoExpirada;

  /// Usado no modo offline (o app entrou sem conexão e está sem sessão): antes
  /// de uma chamada que exige sessão, tenta abrir a sessão de novo. Devolve
  /// `false` se continua sem conexão.
  Future<bool> Function()? aoFaltarSessao;

  bool get temSessao => _sessao != null && _sessao!.isNotEmpty;

  /// Verdadeiro quando a última tentativa de falar com o servidor falhou por
  /// falta de conexão. A tela usa isso para avisar, bem visível, que o app
  /// está sem conexão. Volta a `false` assim que o servidor responde.
  final ValueNotifier<bool> semConexao = ValueNotifier<bool>(false);

  void limparSessao() {
    _sessao = null;
    semConexao.value = false;
  }

  Uri _uri(String caminho, Map<String, String>? consulta) {
    final base = Uri.parse(apiBaseUrl);
    return base.replace(
      path: caminho,
      queryParameters: (consulta == null || consulta.isEmpty) ? null : consulta,
    );
  }

  /// Guarda o token devolvido pelo login / entrada direta.
  void _guardarToken(String caminho, http.Response resposta) {
    if (caminho != '/api/auth/login' &&
        caminho != '/api/auth/entrada-direta') {
      return;
    }
    try {
      final dados = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (dados is Map<String, dynamic> && dados['token'] is String) {
        _sessao = dados['token'] as String;
      }
    } catch (_) {}
  }

  Future<http.Response> _enviar(
    String metodo,
    String caminho, {
    Object? corpo,
    Map<String, String>? consulta,
  }) async {
    if (!temSessao &&
        !caminho.startsWith('/api/auth/') &&
        aoFaltarSessao != null) {
      final conseguiu = await aoFaltarSessao!();
      if (!conseguiu) {
        semConexao.value = true;
        throw ApiException(
          'Não foi possível conectar ao servidor. Verifique a internet e o '
          'endereço configurado em lib/config.dart.',
        );
      }
    }

    final requisicao = http.Request(metodo, _uri(caminho, consulta));
    requisicao.headers['Accept'] = 'application/json';
    if (temSessao) requisicao.headers['Authorization'] = 'Bearer $_sessao';
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json; charset=utf-8';
      requisicao.body = jsonEncode(corpo);
    }

    http.Response resposta;
    try {
      final fluxo = await _http.send(requisicao).timeout(_limiteTempo);
      resposta = await http.Response.fromStream(fluxo);
    } catch (_) {
      semConexao.value = true;
      throw ApiException(
        'Não foi possível conectar ao servidor. Verifique a internet e o '
        'endereço configurado em lib/config.dart.',
      );
    }

    // O servidor respondeu (mesmo que com erro): há conexão.
    semConexao.value = false;
    if (resposta.statusCode >= 400) throw _erroDe(resposta);
    _guardarToken(caminho, resposta);
    return resposta;
  }

  ApiException _erroDe(http.Response resposta) {
    Map<String, dynamic>? dados;
    try {
      final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (decodificado is Map<String, dynamic>) dados = decodificado;
    } catch (_) {}

    final mensagem = (dados?['erro'] ??
            'Erro ${resposta.statusCode} ao falar com o servidor.')
        .toString();

    // O servidor responde "Sessão ..." quando o cookie sumiu ou expirou.
    // (Outros 401, como "Senha atual incorreta.", não derrubam a sessão.)
    if (resposta.statusCode == 401 && mensagem.startsWith('Sessão')) {
      _sessao = null;
      aoSessaoExpirada?.call();
    }
    return ApiException(mensagem, status: resposta.statusCode, dados: dados);
  }

  Map<String, dynamic> _mapa(http.Response resposta) {
    if (resposta.bodyBytes.isEmpty) return <String, dynamic>{};
    final decodificado = jsonDecode(utf8.decode(resposta.bodyBytes));
    return decodificado is Map<String, dynamic>
        ? decodificado
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> get(String caminho,
          {Map<String, String>? consulta}) async =>
      _mapa(await _enviar('GET', caminho, consulta: consulta));

  Future<Map<String, dynamic>> post(String caminho, [Object? corpo]) async =>
      _mapa(await _enviar('POST', caminho, corpo: corpo));

  Future<Map<String, dynamic>> put(String caminho, [Object? corpo]) async =>
      _mapa(await _enviar('PUT', caminho, corpo: corpo));

  Future<Map<String, dynamic>> patch(String caminho, [Object? corpo]) async =>
      _mapa(await _enviar('PATCH', caminho, corpo: corpo));

  Future<Map<String, dynamic>> delete(String caminho) async =>
      _mapa(await _enviar('DELETE', caminho));

  /// Baixa um arquivo (PDF/DOCX) devolvido pelo servidor.
  Future<Uint8List> baixar(String metodo, String caminho,
      {Object? corpo}) async {
    final resposta = await _enviar(metodo, caminho, corpo: corpo);
    return resposta.bodyBytes;
  }
}
