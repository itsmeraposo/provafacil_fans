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

class Usuario {
  Usuario({
    required this.nome,
    required this.email,
    required this.perfil,
    this.instituicao = 'FANS — Faculdade de Nova Serrana',
    this.cargo = '',
    this.cursos = const [],
  });

  final String nome;
  final String email;
  final Perfil perfil;
  final String instituicao;
  final String cargo;
  final List<String> cursos;
}

class Questao {
  Questao({
    required this.id,
    required this.texto,
    required this.assunto,
    required this.periodo, // 'atual' | 'historico'
    required this.valor,
    this.usadaEm = 0,
  });

  final String id;
  String texto;
  String assunto;
  String periodo;
  double valor;
  int usadaEm;
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

class Prova {
  Prova({
    required this.id,
    required this.titulo,
    required this.curso,
    required this.professor,
    required this.data,
    this.etapa = '1ª',
    this.valorProva = '10,0',
    this.status = StatusProva.rascunho,
    List<Questao>? questoes,
    this.comentarioDirecao,
  }) : questoes = questoes ?? [];

  final String id;
  String titulo;
  String curso;
  String professor;
  String data;
  String etapa;
  String valorProva;
  StatusProva status;
  List<Questao> questoes;
  String? comentarioDirecao;

  double get pontuacaoTotal => questoes.fold(0, (soma, q) => soma + q.valor);
}
