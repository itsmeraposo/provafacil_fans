/// Perfis de acesso da aplicação (equivalentes a "Cliente"/"Usuário" do
/// enunciado genérico, adaptados aos perfis reais do ProvaFácil FANS).
enum Perfil { professor, direcao, repografia }

extension PerfilRotulo on Perfil {
  String get chave {
    switch (this) {
      case Perfil.professor:
        return 'professor';
      case Perfil.direcao:
        return 'direcao';
      case Perfil.repografia:
        return 'repografia';
    }
  }

  String get rotulo {
    switch (this) {
      case Perfil.professor:
        return 'Professor(a)';
      case Perfil.direcao:
        return 'Direção';
      case Perfil.repografia:
        return 'Repografia';
    }
  }

  String get descricao {
    switch (this) {
      case Perfil.professor:
        return 'Cria e monta provas a partir do banco de questões.';
      case Perfil.direcao:
        return 'Revisa e aprova as provas enviadas pelos professores.';
      case Perfil.repografia:
        return 'Imprime as provas já aprovadas pela direção.';
    }
  }
}

const String instituicaoPadrao = 'FANS — Faculdade de Nova Serrana';

class Usuario {
  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    this.instituicao = instituicaoPadrao,
    this.cargo = '',
    this.cursos = const [],
    this.notificacoesEmail = true,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final instituicao = (json['instituicao'] ?? '').toString();
    return Usuario(
      id: (json['id'] ?? '').toString(),
      nome: (json['nome'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      perfil: Perfil.values.firstWhere(
        (p) => p.chave == json['perfil'],
        orElse: () => Perfil.professor,
      ),
      instituicao: instituicao.isEmpty ? instituicaoPadrao : instituicao,
      cargo: (json['cargo'] ?? '').toString(),
      cursos: (json['cursos'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      notificacoesEmail: json['notificacoesEmail'] != false,
    );
  }

  final String id;
  final String nome;
  final String email;
  final Perfil perfil;
  final String instituicao;
  final String cargo;
  final List<String> cursos;
  final bool notificacoesEmail;
}

class Questao {
  Questao({
    required this.id,
    required this.texto,
    required this.assunto,
    this.curso = '',
    this.periodo,
    this.tipo = 'dissertativa', // 'dissertativa' | 'multipla_escolha'
    required this.valor,
    this.usadaEm = 0,
    this.pendente = false,
  });

  factory Questao.fromJson(Map<String, dynamic> json) {
    return Questao(
      id: (json['id'] ?? '').toString(),
      texto: (json['texto'] ?? '').toString(),
      assunto: (json['assunto'] ?? 'Outros').toString(),
      curso: (json['curso'] ?? '').toString(),
      periodo: int.tryParse('${json['periodo']}'),
      tipo: json['tipo'] == 'multipla_escolha'
          ? 'multipla_escolha'
          : 'dissertativa',
      valor: double.tryParse('${json['valor']}') ?? 1.0,
      usadaEm: int.tryParse('${json['usadaEm']}') ?? 0,
      pendente: json['pendente'] == true,
    );
  }

  /// Usado para guardar a cópia local da lista (ver lib/preferencias.dart).
  Map<String, dynamic> toJson() => {
        'id': id,
        'texto': texto,
        'assunto': assunto,
        'curso': curso,
        'periodo': periodo,
        'tipo': tipo,
        'valor': valor,
        'usadaEm': usadaEm,
        'pendente': pendente,
      };

  final String id;
  String texto;
  String assunto;
  String curso;
  int? periodo; // período do curso, de 1 a 10
  String tipo;
  double valor;
  int usadaEm;

  /// Cadastrada sem conexão: está só no aparelho, esperando para ser enviada
  /// ao servidor.
  final bool pendente;

  String get periodoRotulo =>
      periodo == null ? 'Sem período' : '${periodo}º período';

  String get tipoRotulo =>
      tipo == 'multipla_escolha' ? 'Múltipla escolha' : 'Dissertativa';
}

enum StatusProva { rascunho, emRevisao, aprovada, reprovada, impressa }

extension StatusProvaRotulo on StatusProva {
  String get rotulo {
    switch (this) {
      case StatusProva.rascunho:
        return 'Rascunho';
      case StatusProva.emRevisao:
        return 'Em revisão';
      case StatusProva.aprovada:
        return 'Aprovada';
      case StatusProva.reprovada:
        return 'Reprovada';
      case StatusProva.impressa:
        return 'Impressa';
    }
  }
}

StatusProva _statusDe(String? bruto, bool impressa) {
  switch (bruto) {
    case 'em_revisao':
      return StatusProva.emRevisao;
    case 'aprovada':
      // No servidor a impressão é um campo à parte (`impressa`) e não muda
      // o status da prova; no app mostramos como "Impressa".
      return impressa ? StatusProva.impressa : StatusProva.aprovada;
    case 'reprovada':
      return StatusProva.reprovada;
    default:
      return StatusProva.rascunho;
  }
}

class Prova {
  Prova({
    required this.id,
    required this.titulo,
    required this.curso,
    required this.professor,
    required this.data,
    this.periodo = '',
    this.etapa = '1ª',
    this.valorProva = '10,0',
    this.instrucoes = '',
    this.linhasResposta = 5,
    this.status = StatusProva.rascunho,
    List<Questao>? questoes,
    this.comentarioDirecao,
    List<String>? questoesReprovadas,
    this.criadoPorId = '',
  })  : questoes = questoes ?? [],
        questoesReprovadas = questoesReprovadas ?? [];

  factory Prova.fromJson(Map<String, dynamic> json) {
    final porId = <String, Questao>{};
    for (final item in (json['questoesSnapshot'] as List?) ?? const []) {
      if (item is Map<String, dynamic>) {
        final questao = Questao.fromJson(item);
        porId[questao.id] = questao;
      }
    }
    final ids = ((json['questaoIds'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    final ordenadas =
        ids.where(porId.containsKey).map((id) => porId[id]!).toList();
    final comentario = (json['comentarioCoordenador'] ?? '').toString();

    return Prova(
      id: (json['id'] ?? '').toString(),
      titulo: (json['titulo'] ?? 'Avaliação').toString(),
      curso: (json['curso'] ?? '').toString(),
      professor: (json['professor'] ?? '').toString(),
      data: (json['data'] ?? '').toString(),
      periodo: (json['periodo'] ?? '').toString(),
      etapa: (json['etapa'] ?? '').toString(),
      valorProva: (json['valorProva'] ?? '').toString(),
      instrucoes: (json['instrucoes'] ?? '').toString(),
      linhasResposta: int.tryParse('${json['linhasResposta']}') ?? 5,
      status: _statusDe(json['status'] as String?, json['impressa'] == true),
      questoes: ordenadas.isNotEmpty ? ordenadas : porId.values.toList(),
      comentarioDirecao: comentario.isEmpty ? null : comentario,
      questoesReprovadas: ((json['questoesReprovadas'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      criadoPorId: (json['criadoPorId'] ?? '').toString(),
    );
  }

  final String id;
  String titulo;
  String curso;
  String professor;
  String data;
  String periodo;
  String etapa;
  String valorProva;
  String instrucoes;
  int linhasResposta;
  StatusProva status;
  List<Questao> questoes;
  String? comentarioDirecao;
  List<String> questoesReprovadas;
  final String criadoPorId;

  double get pontuacaoTotal => questoes.fold(0, (soma, q) => soma + q.valor);
}
