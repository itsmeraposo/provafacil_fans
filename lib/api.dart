import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:http/http.dart' as http;

import 'armazenamento_token.dart';
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

  /// Cliente usado só no upload de arquivos: o Dio informa o progresso do
  /// envio (`onSendProgress`), inclusive no navegador.
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

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
    ArmazenamentoToken.apagar();
  }

  /// Lê o token guardado em armazenamento seguro (login anterior). Devolve
  /// `false` se não havia nenhum. Quem chama confere o token no servidor.
  Future<bool> restaurarSessaoGuardada() async {
    final token = await ArmazenamentoToken.ler();
    if (token == null || token.isEmpty) return false;
    _sessao = token;
    return true;
  }

  /// Esquece o token só em memória (o guardado no aparelho continua lá).
  /// Usado quando não deu para conferir o token por falta de conexão.
  void esquecerSessaoEmMemoria() => _sessao = null;

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
        ArmazenamentoToken.salvar(_sessao!);
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
          'Sem conexão com o servidor. Tente de novo quando a internet voltar.',
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
        'Sem conexão com o servidor. Tente de novo quando a internet voltar.',
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
    return _erroDeDados(resposta.statusCode, dados);
  }

  ApiException _erroDeDados(int status, Map<String, dynamic>? dados) {
    final mensagem = (dados?['erro'] ??
            (status == 413
                ? 'O arquivo é grande demais para o servidor.'
                : 'Erro $status ao falar com o servidor.'))
        .toString();

    // O servidor responde "Sessão ..." quando o cookie sumiu ou expirou.
    // (Outros 401, como "Senha atual incorreta.", não derrubam a sessão.)
    if (status == 401 && mensagem.startsWith('Sessão')) {
      limparSessao();
      aoSessaoExpirada?.call();
    }
    return ApiException(mensagem, status: status, dados: dados);
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

  /// Envia um arquivo por POST `multipart/form-data` (Dio), com o token no
  /// cabeçalho `Authorization: Bearer`. [aoProgredir] recebe os bytes já
  /// enviados e o total. Lança [ApiException] em erro (401, 403, etc.).
  Future<Map<String, dynamic>> enviarArquivo(
    String caminho, {
    required String campo,
    required Uint8List bytes,
    required String nomeArquivo,
    required String mime,
    void Function(int enviados, int total)? aoProgredir,
  }) async {
    final partes = mime.split('/');
    final formulario = FormData.fromMap({
      campo: MultipartFile.fromBytes(
        bytes,
        filename: nomeArquivo,
        contentType: DioMediaType(partes.first, partes.last),
      ),
    });

    Response<dynamic> resposta;
    try {
      resposta = await _dio.post<dynamic>(
        _uri(caminho, null).toString(),
        data: formulario,
        onSendProgress: aoProgredir,
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (temSessao) 'Authorization': 'Bearer $_sessao',
          },
          // Os códigos 4xx/5xx chegam como resposta (não como exceção) para
          // o app tratar 401 e 403 do mesmo jeito que nas outras chamadas.
          validateStatus: (_) => true,
          sendTimeout: const Duration(seconds: 90),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
    } on DioException {
      semConexao.value = true;
      throw ApiException(
        'Sem conexão com o servidor. Tente de novo quando a internet voltar.',
      );
    }

    semConexao.value = false;
    final status = resposta.statusCode ?? 0;
    final corpo = resposta.data;
    final dados =
        corpo is Map ? Map<String, dynamic>.from(corpo) : null;
    if (status >= 400 || status == 0) throw _erroDeDados(status, dados);
    return dados ?? <String, dynamic>{};
  }
}
