import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'config.dart';
import 'models.dart';

/// Lista usada só enquanto o servidor ainda não respondeu `/api/constantes`.
const List<String> _cursosPadrao = [
  'Administração',
  'Biomedicina',
  'Ciências Contábeis',
  'Direito',
  'Educação Física',
  'Engenharia de Software',
  'Fisioterapia',
  'Pedagogia',
  'Psicologia',
];

/// Sessão atual e dados compartilhados entre as telas.
///
/// Toda ação passa pela API do servidor (Firestore); as listas em memória
/// são só um espelho do que o servidor devolveu. Os métodos lançam
/// [ApiException] em caso de erro, e a tela decide como mostrar.
class AppState extends ChangeNotifier {
  AppState._();

  static final AppState instancia = AppState._();

  final ApiClient _api = ApiClient.instancia;

  Usuario? usuarioAtual;
  List<Questao> questoes = [];
  List<Prova> provas = [];
  List<String> cursosDisponiveis = List.of(_cursosPadrao);
  bool carregando = false;
  String? erroCarregamento;

  bool get logado => usuarioAtual != null;

  /* ------------------------------------------------------------ auth */

  Future<void> carregarConstantes() async {
    try {
      final resposta = await _api.get('/api/constantes');
      final cursos =
          (resposta['cursos'] as List?)?.map((e) => e.toString()).toList();
      if (cursos != null && cursos.isNotEmpty) {
        cursosDisponiveis = cursos;
        notifyListeners();
      }
    } catch (_) {
      // Sem conexão: segue com a lista padrão.
    }
  }

  Future<void> entrar({
    required String email,
    required String senha,
    required Perfil perfil,
  }) async {
    final resposta = await _api.post('/api/auth/login', {
      'email': email.trim(),
      'senha': senha,
      'perfil': perfil.chave,
    });
    usuarioAtual = Usuario.fromJson(resposta['usuario'] as Map<String, dynamic>);
    notifyListeners();
    await carregarDados();
  }

  /// MODO SEM LOGIN (`loginAtivo = false`): pede ao servidor a sessão do
  /// perfil escolhido, sem e-mail nem senha. O servidor precisa estar com
  /// `SEM_LOGIN=true` e a mesma chave de `semLoginChave` (lib/config.dart).
  Future<void> entrarSemLogin(Perfil perfil) async {
    final resposta = await _api.post('/api/auth/entrada-direta', {
      'chave': semLoginChave,
      'perfil': perfil.chave,
    });
    usuarioAtual = Usuario.fromJson(resposta['usuario'] as Map<String, dynamic>);
    notifyListeners();
    await carregarDados();
  }

  Future<String> registrar({
    required String nome,
    required String email,
    required String senha,
    required Perfil perfil,
    List<String> cursos = const [],
    String codigoConvite = '',
  }) async {
    final resposta = await _api.post('/api/auth/registrar', {
      'nome': nome.trim(),
      'email': email.trim(),
      'senha': senha,
      'perfil': perfil.chave,
      if (perfil == Perfil.professor) 'cursos': cursos,
      if (perfil != Perfil.professor) 'codigoConvite': codigoConvite.trim(),
    });
    return (resposta['mensagem'] ?? 'Conta criada.').toString();
  }

  Future<String> esqueciSenha(String email) async {
    final resposta =
        await _api.post('/api/auth/esqueci-senha', {'email': email.trim()});
    return (resposta['mensagem'] ??
            'Se esse e-mail tiver uma conta, enviamos um link de recuperação.')
        .toString();
  }

  Future<String> reenviarVerificacao(String email) async {
    final resposta = await _api
        .post('/api/auth/reenviar-verificacao', {'email': email.trim()});
    return (resposta['mensagem'] ?? 'Link reenviado.').toString();
  }

  Future<void> sair() async {
    try {
      await _api.post('/api/auth/logout');
    } catch (_) {
      // Mesmo sem conexão, encerra a sessão localmente.
    }
    _limpar();
  }

  /// Sessão derrubada pelo servidor (expirada): só limpa o estado local.
  void sessaoExpirada() => _limpar();

  void _limpar() {
    _api.limparSessao();
    usuarioAtual = null;
    questoes = [];
    provas = [];
    erroCarregamento = null;
    carregando = false;
    notifyListeners();
  }

  /* ----------------------------------------------------------- dados */

  List<Map<String, dynamic>> _lista(dynamic valor) =>
      ((valor as List?) ?? const []).whereType<Map<String, dynamic>>().toList();

  Future<void> carregarDados() async {
    final usuario = usuarioAtual;
    if (usuario == null) return;

    carregando = true;
    erroCarregamento = null;
    notifyListeners();

    try {
      if (usuario.perfil != Perfil.repografia) {
        final respostaQuestoes =
            await _api.get('/api/questoes', consulta: {'limite': '100'});
        questoes =
            _lista(respostaQuestoes['questoes']).map(Questao.fromJson).toList();
      }
      final respostaProvas =
          await _api.get('/api/provas', consulta: {'limite': '50'});
      provas = _lista(respostaProvas['provas']).map(Prova.fromJson).toList();
    } on ApiException catch (erro) {
      erroCarregamento = erro.mensagem;
    } catch (_) {
      erroCarregamento = 'Falha ao carregar os dados.';
    }

    carregando = false;
    notifyListeners();
  }

  Future<void> _recarregarQuestoes() async {
    final resposta =
        await _api.get('/api/questoes', consulta: {'limite': '100'});
    questoes = _lista(resposta['questoes']).map(Questao.fromJson).toList();
    notifyListeners();
  }

  Future<void> _recarregarProvas() async {
    final resposta = await _api.get('/api/provas', consulta: {'limite': '50'});
    provas = _lista(resposta['provas']).map(Prova.fromJson).toList();
    notifyListeners();
  }

  /* -------------------------------------------------------- questões */

  Future<void> salvarQuestao({
    String? id,
    required String texto,
    required String tipo,
    required String assunto,
    required String curso,
    required int periodo,
    required double valor,
  }) async {
    final corpo = {
      'texto': texto,
      'tipo': tipo,
      'assunto': assunto,
      'curso': curso,
      'periodo': periodo,
      'valor': valor,
    };
    if (id == null) {
      await _api.post('/api/questoes', corpo);
    } else {
      await _api.put('/api/questoes/$id', corpo);
    }
    await _recarregarQuestoes();
  }

  Future<void> removerQuestao(String id) async {
    await _api.delete('/api/questoes/$id');
    questoes.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  /* ---------------------------------------------------------- provas */

  Map<String, dynamic> _corpoProva(Prova prova) => {
        if (prova.id.isNotEmpty) 'id': prova.id,
        'titulo': prova.titulo,
        'curso': prova.curso,
        'periodo': prova.periodo,
        'etapa': prova.etapa,
        'data': prova.data,
        'valorProva': prova.valorProva,
        'professor': prova.professor,
        'instrucoes': prova.instrucoes,
        'linhasResposta': prova.linhasResposta,
        'questaoIds': prova.questoes.map((q) => q.id).toList(),
      };

  void _guardarProva(Prova prova) {
    final indice = provas.indexWhere((p) => p.id == prova.id);
    if (indice == -1) {
      provas.insert(0, prova);
    } else {
      provas[indice] = prova;
    }
    notifyListeners();
  }

  Future<Prova> salvarRascunho(Prova prova) async {
    final resposta = await _api.post('/api/provas/rascunho', _corpoProva(prova));
    final salva = Prova.fromJson(resposta);
    _guardarProva(salva);
    return salva;
  }

  Future<Prova> enviarParaCoordenador(Prova prova) async {
    final resposta = await _api.post('/api/provas/enviar', _corpoProva(prova));
    final enviada = Prova.fromJson(resposta);
    _guardarProva(enviada);
    return enviada;
  }

  Future<void> excluirProva(String id) async {
    await _api.delete('/api/provas/$id');
    provas.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// [formato]: `pdf` ou `docx`.
  Future<Uint8List> gerarArquivo(Prova prova, String formato) async {
    final bytes = await _api.baixar('POST', '/api/provas/gerar-$formato',
        corpo: _corpoProva(prova));
    try {
      await _recarregarProvas(); // o servidor registra a prova ao gerar
    } catch (_) {}
    return bytes;
  }

  /// PDF de uma prova já salva (usado pela Direção e pela Repografia).
  Future<Uint8List> baixarPreviaPdf(String id) =>
      _api.baixar('GET', '/api/provas/$id/previa-pdf');

  /// Direção: [status] é `aprovada`, `reprovada` ou `em_revisao`.
  Future<Prova> revisarProva(
    String id, {
    required String status,
    String comentario = '',
    List<String> questoesReprovadas = const [],
  }) async {
    final resposta = await _api.patch('/api/provas/$id/revisao', {
      'status': status,
      'comentario': comentario,
      'questoesReprovadas': questoesReprovadas,
    });
    final revisada = Prova.fromJson(resposta);
    _guardarProva(revisada);
    return revisada;
  }

  /// Repografia: marca ou desmarca a impressão de uma prova aprovada.
  Future<Prova> marcarImpressao(String id, {required bool impressa}) async {
    final resposta =
        await _api.patch('/api/provas/$id/impressao', {'impressa': impressa});
    final prova = Prova.fromJson(resposta['prova'] as Map<String, dynamic>);
    _guardarProva(prova);
    return prova;
  }

  List<Prova> provasDoProfessor() {
    final id = usuarioAtual?.id;
    return provas.where((p) => p.criadoPorId == id).toList();
  }

  List<Prova> provasParaRevisao() =>
      provas.where((p) => p.status == StatusProva.emRevisao).toList();

  List<Prova> provasParaImpressao() =>
      provas.where((p) => p.status == StatusProva.aprovada).toList();

  /* ---------------------------------------------------------- perfil */

  Future<void> atualizarPerfil({
    required String nome,
    required String instituicao,
    required String cargo,
    required bool notificacoesEmail,
  }) async {
    final resposta = await _api.put('/api/auth/perfil', {
      'nome': nome.trim(),
      'instituicao': instituicao.trim(),
      'cargo': cargo.trim(),
      'notificacoesEmail': notificacoesEmail,
    });
    usuarioAtual = Usuario.fromJson(resposta['usuario'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> alterarSenha(String senhaAtual, String novaSenha) async {
    await _api.post('/api/auth/alterar-senha', {
      'senhaAtual': senhaAtual,
      'novaSenha': novaSenha,
    });
  }

  Future<void> excluirConta() async {
    await _api.delete('/api/auth/conta');
    _limpar();
  }
}
