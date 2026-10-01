import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common.dart';
import 'revisao_direcao_screen.dart';

/// TELA · Painel da Direção (tela inicial pós-login do perfil Direção).
///
/// Mostra a fila de provas aguardando revisão e o histórico de decisões já
/// tomadas. Ao tocar em uma prova pendente, abre a tela de revisão/decisão.
class PainelDirecaoScreen extends StatelessWidget {
  const PainelDirecaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AppState.instancia;
    final pendentes = estado.provasParaRevisao();
    final decididas = estado.provas
        .where((p) =>
            p.status == StatusProva.aprovada || p.status == StatusProva.reprovada)
        .toList();

    return TelaPrincipal(
      titulo: 'Painel da Direção',
      drawer: const AppDrawer(telaAtual: 'Início'),
      corpo: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradeIndicadores(
            itens: [
              CartaoIndicador(
                rotulo: 'Aguardando revisão',
                valor: '${pendentes.length}',
                icone: Icons.pending_actions_outlined,
              ),
              CartaoIndicador(
                rotulo: 'Decididas neste semestre',
                valor: '${decididas.length}',
                icone: Icons.fact_check_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const TituloSecao('Provas para revisar'),
          if (pendentes.isEmpty)
            const EstadoVazio(
              texto: 'Nenhuma prova aguardando revisão no momento.',
              icone: Icons.inbox_outlined,
            )
          else
            ...pendentes.map((prova) => _linhaProva(context, prova)),
          const SizedBox(height: 22),
          const TituloSecao('Decididas recentemente'),
          if (decididas.isEmpty)
            const EstadoVazio(texto: 'Nenhuma decisão registrada ainda.')
          else
            ...decididas.map((prova) => _linhaProva(context, prova)),
        ],
      ),
    );
  }

  Widget _linhaProva(BuildContext context, Prova prova) {
    return LinhaProva(
      titulo: prova.titulo,
      detalhe: '${prova.professor} · ${prova.curso}',
      status: prova.status,
      aoTocar: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RevisaoDirecaoScreen(prova: prova)),
      ),
    );
  }
}
