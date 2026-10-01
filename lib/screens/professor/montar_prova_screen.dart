import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'revisao_prova_screen.dart';

/// TELA · Montar prova — passo 1 de 2 (seleção de questões).
///
/// Fluxo: Painel/Banco de Questões → Montar prova → Revisão e geração.
/// Some ao total de 10,0 pontos automaticamente conforme o professor marca
/// as questões, e só libera o botão de continuar quando há questões
/// selecionadas.
class MontarProvaScreen extends StatefulWidget {
  const MontarProvaScreen({super.key});

  @override
  State<MontarProvaScreen> createState() => _MontarProvaScreenState();
}

class _MontarProvaScreenState extends State<MontarProvaScreen> {
  final Set<String> _selecionadas = {};

  double get _pontosSelecionados {
    final questoes = AppState.instancia.questoes;
    return questoes
        .where((q) => _selecionadas.contains(q.id))
        .fold<double>(0, (soma, q) => soma + q.valor);
  }

  void _continuar() {
    final estado = AppState.instancia;
    final questoesSelecionadas = estado.questoes
        .where((q) => _selecionadas.contains(q.id))
        .toList();

    final novaProva = Prova(
      id: 'p${DateTime.now().millisecondsSinceEpoch}',
      titulo: 'Avaliação',
      curso: estado.usuarioAtual?.cursos.isNotEmpty == true
          ? estado.usuarioAtual!.cursos.first
          : 'Análise e Desenvolvimento de Sistemas',
      professor: estado.usuarioAtual?.nome ?? '',
      data: '',
      status: StatusProva.rascunho,
      questoes: questoesSelecionadas,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RevisaoProvaScreen(prova: novaProva, provaNova: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questoes = AppState.instancia.questoes;
    final pontos = _pontosSelecionados;
    final faltam = (10 - pontos).clamp(0, 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passo 1 de 2 · Questões'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: questoes.isEmpty
                  ? const EstadoVazio(
                      texto:
                          'O banco de questões está vazio. Volte e adicione\n'
                          'questões antes de montar uma prova.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: questoes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, indice) {
                        final questao = questoes[indice];
                        final marcada = _selecionadas.contains(questao.id);
                        return Card(
                          color: marcada ? AppColors.accentSoft : null,
                          child: CheckboxListTile(
                            value: marcada,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (valor) => setState(() {
                              if (valor == true) {
                                _selecionadas.add(questao.id);
                              } else {
                                _selecionadas.remove(questao.id);
                              }
                            }),
                            title: Text(
                              questao.texto,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${questao.assunto} · ${questao.valor.toStringAsFixed(1)} pts',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.inkMuted),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                            '${_selecionadas.length} questão(ões) selecionada(s)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${pontos.toStringAsFixed(1)} / 10,0 pts',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pontos / 10).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: AppColors.rule,
                      color: faltam == 0 ? AppColors.moss : AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _selecionadas.isEmpty ? null : _continuar,
                    child: const Text('Continuar para revisão →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
