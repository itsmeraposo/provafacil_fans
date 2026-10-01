import 'models.dart';

List<Questao> questoesIniciais() => [
      Questao(
        id: 'q1',
        texto:
            'Explique, com suas palavras, a diferença entre um StatelessWidget '
            'e um StatefulWidget no Flutter, citando um exemplo de uso para '
            'cada um.',
        assunto: 'Desenvolvimento Mobile',
        periodo: 'atual',
        valor: 2.5,
        usadaEm: 3,
      ),
      Questao(
        id: 'q2',
        texto: 'O que é normalização de banco de dados? Cite as três '
            'primeiras formas normais.',
        assunto: 'Banco de Dados',
        periodo: 'atual',
        valor: 2.0,
        usadaEm: 5,
      ),
      Questao(
        id: 'q3',
        texto:
            'Descreva o ciclo de vida de uma requisição HTTP em uma API REST, '
            'do cliente até a resposta do servidor.',
        assunto: 'Desenvolvimento Web',
        periodo: 'atual',
        valor: 2.0,
        usadaEm: 2,
      ),
      Questao(
        id: 'q4',
        texto: 'Explique o conceito de herança na Programação Orientada a '
            'Objetos e dê um exemplo em Dart ou Java.',
        assunto: 'Programação Orientada a Objetos',
        periodo: 'historico',
        valor: 1.5,
        usadaEm: 8,
      ),
      Questao(
        id: 'q5',
        texto: 'O que são metodologias ágeis? Cite as diferenças entre '
            'Scrum e Kanban.',
        assunto: 'Engenharia de Software',
        periodo: 'historico',
        valor: 2.0,
        usadaEm: 4,
      ),
      Questao(
        id: 'q6',
        texto: 'Explique o que é uma chave estrangeira (foreign key) e qual '
            'sua função na integridade referencial de um banco de dados.',
        assunto: 'Banco de Dados',
        periodo: 'atual',
        valor: 1.5,
        usadaEm: 1,
      ),
    ];

List<Prova> provasIniciais() => [
      Prova(
        id: 'p1',
        titulo: 'Avaliação de Banco de Dados',
        curso: 'Análise e Desenvolvimento de Sistemas',
        professor: 'Ana Beatriz Souza',
        data: '02/10/2026',
        status: StatusProva.emRevisao,
        questoes: [questoesIniciais()[1], questoesIniciais()[5]],
      ),
      Prova(
        id: 'p2',
        titulo: 'Avaliação de Engenharia de Software',
        curso: 'Sistemas de Informação',
        professor: 'Carlos Eduardo Lima',
        data: '28/09/2026',
        status: StatusProva.aprovada,
        questoes: [questoesIniciais()[4], questoesIniciais()[3]],
      ),
      Prova(
        id: 'p3',
        titulo: 'Avaliação de Desenvolvimento Mobile',
        curso: 'Análise e Desenvolvimento de Sistemas',
        professor: 'Ana Beatriz Souza',
        data: '10/09/2026',
        status: StatusProva.impressa,
        questoes: [questoesIniciais()[0], questoesIniciais()[2]],
      ),
      Prova(
        id: 'p4',
        titulo: 'Avaliação de Redes de Computadores',
        curso: 'Ciência da Computação',
        professor: 'Marina Torres',
        data: '05/09/2026',
        status: StatusProva.rascunho,
        questoes: [],
      ),
    ];

const cursosDisponiveis = [
  'Análise e Desenvolvimento de Sistemas',
  'Sistemas de Informação',
  'Ciência da Computação',
];
