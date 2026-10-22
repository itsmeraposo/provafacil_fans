import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'config.dart';
import 'models.dart';
import 'preferencias.dart';

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

  /// Verdadeiro quando a lista de questões na tela veio da cópia guardada no
  /// aparelho (servidor ou internet indisponível), e não do servidor.
  bool usandoCache = false;

  /// Verdadeiro quando o app entrou sem conexão (usando os dados guardados no
  /// aparelho) e ainda não tem sessão com o servidor. A sessão é pedida de
  /// novo sozinha assim que a conexão voltar.
  bool semSessao = false;

  bool get logado => usuarioAtual != null;

  /* ------------- envio automático do que ficou no aparelho (offline) */

  /// Avisa o usuário (SnackBar) quando algo guardado no aparelho é enviado.
  /// Configurado em main.dart.
  void Function(String mensagem)? aoAvisar;

  /// Avisa que um arquivo (PDF/DOCX) pedido sem conexão ficou pronto. Quem
  /// escuta (main.dart) mostra um aviso com o botão "Abrir".
  void Function(Uint8List bytes, String titulo, String formato)?
      aoArquivoPronto;

  /// Edições feitas sem conexão em provas que já estão no servidor, esperando
  /// para serem enviadas (id da prova → prova editada).
  final Map<String, Prova> edicoesLocais = {};

  /// O que cada edição guardada vai fazer ao ser enviada (`rascunho`,
  /// `enviar`, `pdf` ou `docx`), pelo id da prova.
  final Map<String, String> acoesEdicoes = {};

  /// Último motivo pelo qual o envio automático não deu certo (para mostrar
  /// na lista de rascunhos). `null` quando não há problema.
  final ValueNotifier<String?> erroSincronizacao = ValueNotifier<String?>(null);
  final Set<String> _edicoesRecusadas = {};

  Future<void> _carregarEdicoesLocais() async {
    final usuario = usuarioAtual;
    if (usuario == null) return;
    final lista = await Preferencias.lerEdicoesLocais(usuario.id);
    edicoesLocais
      ..clear()
      ..addEntries(lista.map((e) => MapEntry(e.prova.id, e.prova)));
    acoesEdicoes
      ..clear()
      ..addEntries(lista.map((e) => MapEntry(e.prova.id, e.acao)));
  }

  /// Ao abrir uma prova do servidor: devolve a edição guardada no aparelho
  /// (se houver). O pedido guardado (enviar, PDF, DOCX) continua valendo até
  /// o professor cancelar na tela de revisão.
  Prova? abrirEdicaoLocal(String id) => edicoesLocais[id];

  /// Guarda a edição de uma prova do servidor feita sem conexão.
  Future<void> guardarEdicaoLocal(Prova prova, String acao) async {
    final usuario = usuarioAtual;
    if (usuario == null || prova.id.isEmpty) return;
    edicoesLocais[prova.id] = prova;
    acoesEdicoes[prova.id] = acao;
    _edicoesRecusadas.remove(prova.id);
    await Preferencias.salvarEdicaoLocal(usuario.id, prova, acao);
    notifyListeners();
  }

  /// A prova foi para o servidor: a edição guardada não é mais necessária.
  Future<void> descartarEdicaoLocal(String id) async {
    final usuario = usuarioAtual;
    edicoesLocais.remove(id);
    acoesEdicoes.remove(id);
    if (usuario != null) await Preferencias.apagarEdicaoLocal(usuario.id, id);
    notifyListeners();
  }

  Timer? _temporizadorSync;
  bool _sincronizando = false;
  bool _rascunhoRecusado = false;
  int _revisoesAbertas = 0;

  /// A tela de revisão de prova avisa quando abre e fecha. Enquanto ela está
  /// aberta, o rascunho local não é enviado sozinho (para não duplicar).
  void revisaoAberta() {
    _revisoesAbertas++;
    _rascunhoRecusado = false;
  }

  void revisaoFechada() {
    if (_revisoesAbertas > 0) _revisoesAbertas--;
  }

  /// A cada 15 s confere se há questões ou um rascunho de prova guardados só
  /// no aparelho. Só fala com o servidor se houver algo para enviar.
  void _iniciarSincronizacao() {
    _temporizadorSync ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => _sincronizarEmSegundoPlano(),
    );
  }

  Future<void> _sincronizarEmSegundoPlano() async {
    final usuario = usuarioAtual;
    if (usuario == null) {
      _temporizadorSync?.cancel();
      _temporizadorSync = null;
      return;
    }
    if (_sincronizando || _revisoesAbertas > 0) return;
    _sincronizando = true;
    try {
      final pendentes = await Preferencias.lerPendentes(usuario.id);
      final rascunho = _rascunhoRecusado
          ? null
          : await Preferencias.lerRascunhoLocal(usuario.id);
      final edicoes = (await Preferencias.lerEdicoesLocais(usuario.id))
          .where((e) => !_edicoesRecusadas.contains(e.prova.id))
          .toList();
      if (pendentes.isEmpty && rascunho == null && edicoes.isEmpty) return;

      var enviouAlgo = false;
      if (pendentes.isNotEmpty && await sincronizarPendentes() > 0) {
        aoAvisar?.call('Questões cadastradas sem conexão foram enviadas.');
        enviouAlgo = true;
      }
      if (rascunho != null) {
        final aviso = await sincronizarRascunhoProva(rascunho);
        if (aviso != null) {
          if (aviso.isNotEmpty) aoAvisar?.call(aviso);
          enviouAlgo = true;
        }
      }
      for (final edicao in edicoes) {
        final id = edicao.prova.id;
        try {
          final aviso = await _enviarProvaLocal(
            edicao.prova,
            edicao.acao,
            () => descartarEdicaoLocal(id),
          );
          if (aviso.isNotEmpty) aoAvisar?.call(aviso);
          erroSincronizacao.value = null;
          enviouAlgo = true;
        } on ApiException catch (erro) {
          final status = erro.status;
          erroSincronizacao.value = status == null ? null : erro.mensagem;
          final tentarDepois = status == null ||
              status >= 500 ||
              status == 401 ||
              status == 403;
          if (!tentarDepois) {
            _edicoesRecusadas.add(id);
            aoAvisar?.call('Não foi possível enviar as alterações guardadas '
                'da prova "${edicao.prova.titulo}": ${erro.mensagem}');
          }
        }
      }
      if (enviouAlgo) await carregarDados();
    } finally {
      _sincronizando = false;
    }
  }

  /// Envia ao servidor uma prova guardada no aparelho e faz o que o professor
  /// tinha pedido sem conexão ([acao]: só salvar, `enviar`, `pdf` ou `docx`).
  /// [limpar] é chamado assim que a prova chega ao servidor (antes de gerar o
  /// arquivo), para não criar a prova duas vezes se algo falhar depois.
  /// Devolve o texto do aviso (vazio = sem aviso). Erros ao salvar/enviar
  /// seguem como [ApiException], e quem chama decide se tenta de novo.
  Future<String> _enviarProvaLocal(
    Prova prova,
    String? acao,
    Future<void> Function() limpar,
  ) async {
    if (acao == 'enviar') {
      await enviarParaCoordenador(prova);
      await limpar();
      return 'Prova enviada ao coordenador.';
    }

    final salva = await salvarRascunho(prova);
    await limpar();
    if (acao != 'pdf' && acao != 'docx') {
      return prova.id.isEmpty
          ? 'Rascunho da prova enviado ao servidor.'
          : 'Alterações da prova "${prova.titulo}" enviadas ao servidor.';
    }

    final formato = acao!;
    try {
      // Usa as questões guardadas no aparelho, com o id que o servidor deu.
      final paraGerar = Prova(
        id: salva.id,
        titulo: prova.titulo,
        curso: prova.curso,
        professor: prova.professor,
        data: prova.data,
        periodo: prova.periodo,
        etapa: prova.etapa,
        valorProva: prova.valorProva,
        instrucoes: prova.instrucoes,
        linhasResposta: prova.linhasResposta,
        questoes: prova.questoes,
        status: StatusProva.rascunho,
      );
      final bytes = await gerarArquivo(paraGerar, formato);
      aoArquivoPronto?.call(bytes, prova.titulo, formato);
      return '';
    } on ApiException {
      return 'Prova salva no servidor, mas não foi possível gerar o '
          '${formato.toUpperCase()}. Abra a prova e gere de novo.';
    }
  }

  /// Envia o rascunho de prova NOVA guardado no aparelho. Devolve `null` se
  /// não deu certo (tenta de novo depois) ou o texto do aviso se deu.
  Future<String?> sincronizarRascunhoProva(Prova rascunho) async {
    final usuario = usuarioAtual;
    if (usuario == null || rascunho.questoes.isEmpty) return null;
    final acao = await Preferencias.lerAcaoPendente(usuario.id);
    try {
      final aviso = await _enviarProvaLocal(
        rascunho,
        acao,
        () => Preferencias.apagarRascunhoLocal(usuario.id),
      );
      erroSincronizacao.value = null;
      return aviso;
    } on ApiException catch (erro) {
      final status = erro.status;
      erroSincronizacao.value = status == null ? null : erro.mensagem;
      final tentarDepois =
          status == null || status >= 500 || status == 401 || status == 403;
      // Recusado pelo servidor (dados inválidos): não adianta insistir sozinho.
      if (!tentarDepois) {
        _rascunhoRecusado = true;
        aoAvisar?.call('Não foi possível enviar o rascunho guardado neste '
            'aparelho: ${erro.mensagem} Abra "Montar prova" e toque em '
            '"Continuar" para revisar.');
      }
      return null;
    }
  }

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
  ///
  /// Se não houver conexão (ou o servidor estiver fora do ar) e este perfil já
  /// tiver entrado antes neste aparelho, abre o painel mesmo assim, com os
  /// dados guardados localmente (modo offline).
  Future<void> entrarSemLogin(Perfil perfil) async {
    try {
      final resposta = await _api.post('/api/auth/entrada-direta', {
        'chave': semLoginChave,
        'perfil': perfil.chave,
      });
      final dadosUsuario = resposta['usuario'] as Map<String, dynamic>;
      usuarioAtual = Usuario.fromJson(dadosUsuario);
      semSessao = false;
      await Preferencias.salvarUsuarioOffline(perfil.chave, dadosUsuario);
    } on ApiException catch (erro) {
      // Erros de resposta do servidor (ex.: 403 chave errada, 404 modo
      // desligado) seguem como erro. Só entra offline sem conexão ou 5xx.
      final semServico = erro.status == null || erro.status! >= 500;
      if (!semServico) rethrow;
      final guardado = await Preferencias.lerUsuarioOffline(perfil.chave);
      if (guardado == null) {
        // Nunca entrou com internet neste aparelho: não há o que mostrar.
        throw ApiException(
          'Sem conexão com o servidor. Este perfil ainda não entrou com '
          'internet neste aparelho: conecte-se uma vez para depois poder '
          'usar sem conexão.',
        );
      }
      usuarioAtual = guardado;
      semSessao = true;
    }
    notifyListeners();
    await carregarDados();
  }

  /// Chamado pelo cliente HTTP antes de requisições que exigem sessão. No modo
  /// offline, tenta abrir a sessão; se não houver conexão, devolve `false`.
  Future<bool> garantirSessao() async {
    if (!semSessao) return true;
    final usuario = usuarioAtual;
    if (usuario == null) return false;
    try {
      final resposta = await _api.post('/api/auth/entrada-direta', {
        'chave': semLoginChave,
        'perfil': usuario.perfil.chave,
      });
      final dadosUsuario = resposta['usuario'] as Map<String, dynamic>;
      usuarioAtual = Usuario.fromJson(dadosUsuario);
      await Preferencias.salvarUsuarioOffline(usuario.perfil.chave, dadosUsuario);
      semSessao = false;
      return true;
    } on ApiException {
      return false;
    }
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
    _temporizadorSync?.cancel();
    _temporizadorSync = null;
    _rascunhoRecusado = false;
    erroSincronizacao.value = null;
    acoesEdicoes.clear();
    edicoesLocais.clear();
    Preferencias.rascunhoLocal.value = null;
    Preferencias.acaoRascunhoLocal.value = null;
    _api.limparSessao();
    usuarioAtual = null;
    semSessao = false;
    usandoCache = false;
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
    _iniciarSincronizacao();
    // Atualizar (puxar a lista, "Tentar de novo") também tenta enviar agora o
    // que ficou guardado no aparelho, sem esperar o próximo ciclo de 15 s.
    await _sincronizarEmSegundoPlano();
    await _carregarEdicoesLocais();
    await Preferencias.atualizarRascunhoLocal(usuario.id);

    carregando = true;
    erroCarregamento = null;
    usandoCache = false;
    notifyListeners();

    try {
      if (usuario.perfil != Perfil.repografia) {
        // Primeiro envia o que foi cadastrado sem conexão (se houver).
        await sincronizarPendentes();
        try {
          final respostaQuestoes =
              await _api.get('/api/questoes', consulta: {'limite': '100'});
          questoes = _lista(respostaQuestoes['questoes'])
              .map(Questao.fromJson)
              .toList();
          await Preferencias.salvarQuestoesCache(usuario.id, questoes);
        } on ApiException catch (erro) {
          // Sem conexão (status nulo) ou erro do servidor (5xx): tenta a
          // última lista guardada. Outros erros (ex.: sessão expirada) seguem
          // o caminho normal.
          final semServico = erro.status == null || erro.status! >= 500;
          final guardadas =
              semServico ? await Preferencias.lerQuestoesCache(usuario.id) : null;
          if (guardadas == null) rethrow;
          questoes = guardadas;
          usandoCache = true;
        }
        await _juntarPendentes(usuario.id);
      }
      try {
        final respostaProvas =
            await _api.get('/api/provas', consulta: {'limite': '50'});
        final brutas = _lista(respostaProvas['provas']);
        provas = brutas.map(Prova.fromJson).toList();
        await Preferencias.salvarProvasCache(usuario.id, brutas);
      } on ApiException catch (erro) {
        // Mesma regra das questões: sem conexão ou servidor fora, usa a
        // última lista de provas guardada no aparelho.
        final semServico = erro.status == null || erro.status! >= 500;
        final guardadas =
            semServico ? await Preferencias.lerProvasCache(usuario.id) : null;
        if (guardadas == null) rethrow;
        provas = guardadas;
        usandoCache = true;
      }
    } on ApiException catch (erro) {
      erroCarregamento = erro.mensagem;
    } catch (_) {
      erroCarregamento = 'Falha ao carregar os dados.';
    }

    if (usandoCache) {
      erroCarregamento = 'Sem conexão com o servidor. Mostrando a última '
          'cópia dos dados salva neste aparelho.';
    }

    carregando = false;
    notifyListeners();
  }

  Future<void> _recarregarQuestoes() async {
    final resposta =
        await _api.get('/api/questoes', consulta: {'limite': '100'});
    questoes = _lista(resposta['questoes']).map(Questao.fromJson).toList();
    usandoCache = false;
    final usuario = usuarioAtual;
    if (usuario != null) {
      await Preferencias.salvarQuestoesCache(usuario.id, questoes);
      await _juntarPendentes(usuario.id);
    }
    notifyListeners();
  }

  /* --------------------------- cadastro sem conexão (pendentes + envio) */

  /// Questões prontas no servidor (sem as pendentes), usadas para montar prova.
  List<Questao> get questoesEnviadas =>
      questoes.where((q) => !q.pendente).toList();

  /// Põe as questões pendentes (só no aparelho) no topo da lista.
  Future<void> _juntarPendentes(String usuarioId) async {
    final pendentes = await Preferencias.lerPendentes(usuarioId);
    if (pendentes.isEmpty) return;
    questoes = [...pendentes.reversed, ...questoes];
  }

  Future<void> _guardarPendente(Map<String, dynamic> corpo) async {
    final usuario = usuarioAtual;
    if (usuario == null) return;
    final pendente = Questao(
      id: 'pendente-${DateTime.now().microsecondsSinceEpoch}',
      texto: corpo['texto'] as String,
      tipo: corpo['tipo'] as String,
      assunto: corpo['assunto'] as String,
      curso: corpo['curso'] as String,
      periodo: corpo['periodo'] as int,
      valor: corpo['valor'] as double,
      pendente: true,
    );
    final lista = await Preferencias.lerPendentes(usuario.id);
    lista.add(pendente);
    await Preferencias.salvarPendentes(usuario.id, lista);
    questoes = [pendente, ...questoes];
    notifyListeners();
  }

  /// Envia ao servidor as questões cadastradas sem conexão. As que não
  /// conseguirem seguir (sem internet, servidor fora, sessão) continuam
  /// guardadas para a próxima tentativa. Devolve quantas foram enviadas.
  Future<int> sincronizarPendentes() async {
    final usuario = usuarioAtual;
    if (usuario == null) return 0;
    final pendentes = await Preferencias.lerPendentes(usuario.id);
    if (pendentes.isEmpty) return 0;

    final restantes = <Questao>[];
    var enviadas = 0;
    for (var i = 0; i < pendentes.length; i++) {
      final q = pendentes[i];
      try {
        await _api.post('/api/questoes', {
          'texto': q.texto,
          'tipo': q.tipo,
          'assunto': q.assunto,
          'curso': q.curso,
          'periodo': q.periodo,
          'valor': q.valor,
        });
        enviadas++;
      } on ApiException catch (erro) {
        final status = erro.status;
        final tentarDepois =
            status == null || status >= 500 || status == 401 || status == 403;
        if (tentarDepois) {
          // Guarda esta e as seguintes e para por aqui.
          restantes.addAll(pendentes.sublist(i));
          break;
        }
        // Rejeitada pelo servidor (ex.: dados inválidos): não adianta
        // tentar de novo, então descarta.
      }
    }
    await Preferencias.salvarPendentes(usuario.id, restantes);
    return enviadas;
  }

  Future<void> _recarregarProvas() async {
    final resposta = await _api.get('/api/provas', consulta: {'limite': '50'});
    provas = _lista(resposta['provas']).map(Prova.fromJson).toList();
    notifyListeners();
  }

  /* -------------------------------------------------------- questões */

  /// Devolve `true` se a questão já foi para o servidor e `false` se foi
  /// guardada só no aparelho (cadastro novo sem conexão), para ser enviada
  /// depois.
  Future<bool> salvarQuestao({
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
      try {
        await _api.post('/api/questoes', corpo);
      } on ApiException catch (erro) {
        // Erro do servidor (validação etc.) segue como erro. Sem conexão
        // (status nulo): guarda no aparelho para enviar quando voltar.
        if (erro.status != null) rethrow;
        await _guardarPendente(corpo);
        return false;
      }
    } else {
      await _api.put('/api/questoes/$id', corpo);
    }
    await _recarregarQuestoes();
    return true;
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
