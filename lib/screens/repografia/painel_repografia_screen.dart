import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common.dart';
import 'detalhe_impressao_screen.dart';

/// TELA · Painel da Repografia (tela inicial pós-login do perfil Repografia).
///
/// Lista as provas já aprovadas pela Direção e prontas para impressão, além
/// do histórico de provas já impressas.
class PainelRepografiaScreen extends StatelessWidget {
  const PainelRepografiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = AppState.instancia;
    final paraImprimir = estado.provasParaImpressao();
    final impressas =
        estado.provas.where((p) => p.status == StatusProva.impressa).toList();

    return TelaPrincipal(
      titulo: 'Painel da Repografia',
      drawer: const AppDrawer(telaAtual: 'Início'),
      corpo: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradeIndicadores(
            itens: [
              CartaoIndicador(
                rotulo: 'Prontas para impressão',
                valor: '${paraImprimir.length}',
                icone: Icons.print_outlined,
              ),
              CartaoIndicador(
                rotulo: 'Já impressas',
                valor: '${impressas.length}',
                icone: Icons.task_alt_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const TituloSecao('Aguardando impressão'),
          if (paraImprimir.isEmpty)
            const EstadoVazio(
              texto: 'Nenhuma prova aprovada aguardando impressão.',
              icone: Icons.print_disabled_outlined,
            )
          else
            ...paraImprimir.map((prova) => _linhaProva(context, prova)),
          const SizedBox(height: 22),
          const TituloSecao('Histórico de impressão'),
          if (impressas.isEmpty)
            const EstadoVazio(texto: 'Nenhuma prova impressa ainda.')
          else
            ...impressas.map((prova) => _linhaProva(context, prova)),
        ],
      ),
    );
  }

  Widget _linhaProva(BuildContext context, Prova prova) {
    return LinhaProva(
      titulo: prova.titulo,
      detalhe: '${prova.curso} · ${prova.data}',
      status: prova.status,
      aoTocar: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => DetalheImpressaoScreen(prova: prova)),
      ),
    );
  }
}
