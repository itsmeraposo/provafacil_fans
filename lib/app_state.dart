import 'package:flutter/foundation.dart';

import 'mock_data.dart';
import 'models.dart';

/// Guarda a sessão atual (usuário logado) e os dados compartilhados entre
/// as telas (banco de questões e provas), simulando o que viria do backend.
///
/// Não há persistência real nem chamadas de rede: é o suficiente para que a
/// navegação, os menus e os fluxos de cada perfil funcionem de ponta a ponta
/// nesta etapa do projeto.
class AppState extends ChangeNotifier {
  AppState._interno()
      : questoes = questoesIniciais(),
        provas = provasIniciais();

  static final AppState instancia = AppState._interno();

  Usuario? usuarioAtual;
  final List<Questao> questoes;
  final List<Prova> provas;

  bool get logado => usuarioAtual != null;

  void entrar(Usuario usuario) {
    usuarioAtual = usuario;
    notifyListeners();
  }

  void sair() {
    usuarioAtual = null;
    notifyListeners();
  }

  void adicionarQuestao(Questao questao) {
    questoes.insert(0, questao);
    notifyListeners();
  }

  void removerQuestao(String id) {
    questoes.removeWhere((q) => q.id == id);
    notifyListeners();
  }

  void atualizarQuestao(Questao questao) {
    final indice = questoes.indexWhere((q) => q.id == questao.id);
    if (indice != -1) {
      questoes[indice] = questao;
      notifyListeners();
    }
  }

  void adicionarProva(Prova prova) {
    provas.insert(0, prova);
    notifyListeners();
  }

  void atualizarStatusProva(
    String id,
    StatusProva status, {
    String? comentario,
  }) {
    final prova = provas.firstWhere((p) => p.id == id);
    prova.status = status;
    if (comentario != null) prova.comentarioDirecao = comentario;
    notifyListeners();
  }

  List<Prova> provasDoProfessor(String nomeProfessor) =>
      provas.where((p) => p.professor == nomeProfessor).toList();

  List<Prova> provasParaRevisao() =>
      provas.where((p) => p.status == StatusProva.emRevisao).toList();

  List<Prova> provasParaImpressao() =>
      provas.where((p) => p.status == StatusProva.aprovada).toList();
}
