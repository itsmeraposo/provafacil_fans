import 'package:flutter/material.dart';

import '../../api.dart';
import '../../app_state.dart';
import '../../models.dart';
import '../../preferencias.dart';
import '../../theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common.dart';
import 'banco_questoes_screen.dart';
import 'montar_prova_screen.dart';
import 'revisao_prova_screen.dart';

/// TELA · Painel do professor.
///
/// Mostra indicadores e a lista de provas do professor logado (dados do
/// servidor), com atalho para reabrir uma prova e para começar a montar uma
/// nova (fluxo: Painel → Banco/Montar → Revisão). Puxe a lista para baixo
/// para atualizar.
class PainelProfessorScreen extends StatelessWidget {
  const PainelProfessorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TelaPrincipal(
      titulo: 'Painel do professor',
      drawer: const AppDrawer(telaAtual: 'Início'),
      corpo: PainelAtualizavel(construir: _conteudo),
    );
  }

  List<Widget> _conteudo(BuildContext context) {
    final estado = AppState.instancia;
    final usuario = estado.usuarioAtual;
    if (usuario == null) return const [];

    final minhasProvas = estado.provasDoProfessor();
    final aprovadas = minhasProvas
        .where((p) =>
            p.status == StatusProva.aprovada ||
            p.status == StatusProva.impressa)
        .length;

    return [
      Text('Olá, ${usuario.nome.split(' ').first}',
          style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
      const SizedBox(height: 14),
      GradeIndicadores(
        itens: [
          CartaoIndicador(
            rotulo: 'Provas no semestre',
            valor: '${minhasProvas.length + (Preferencias.rascunhoLocal.value != null ? 1 : 0)}',
            icone: Icons.assignment_outlined,
          ),
          CartaoIndicador(
            rotulo: 'Aprovadas pela direção',
            valor: '$aprovadas',
            icone: Icons.verified_outlined,
          ),
          CartaoIndicador(
            rotulo: 'Questões no banco',
            valor: '${estado.questoes.length}',
            icone: Icons.storage_outlined,
          ),
          CartaoIndicador(
            rotulo: 'Assunto predominante',
            valor: _assuntoMaisComum(estado.questoes),
            icone: Icons.topic_outlined,
          ),
        ],
      ),
      const SizedBox(height: 22),
      const TituloSecao('Provas recentes'),
      ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MontarProvaScreen()),
        ),
        icon: const Icon(Icons.add, size: 17),
        label: const Text('Criar nova prova'),
      ),
      const SizedBox(height: 8),
      // Rascunho de prova nova guardado só neste aparelho (sem conexão).
      ValueListenableBuilder<Prova?>(
        valueListenable: Preferencias.rascunhoLocal,
        builder: (context, rascunho, _) {
          if (rascunho == null) return const SizedBox.shrink();
          return ValueListenableBuilder<String?>(
            valueListenable: Preferencias.acaoRascunhoLocal,
            builder: (context, acao, _) =>
                ValueListenableBuilder<bool>(
              valueListenable: ApiClient.instancia.semConexao,
              builder: (context, semConexao, _) => LinhaProva(
                titulo: rascunho.titulo,
                detalhe: '${rascunho.curso} · ${_situacaoLocal(acao)}'
                    '${_motivoFalha()}',
                status: StatusProva.rascunho,
                aviso: _avisoLocal(semConexao),
                aoTocar: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RevisaoProvaScreen(prova: rascunho, provaNova: true),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      if (minhasProvas.isEmpty && Preferencias.rascunhoLocal.value == null)
        const EstadoVazio(
          texto: 'Você ainda não criou nenhuma prova. Toque em "Criar nova\n'
              'prova" para começar.',
          icone: Icons.assignment_outlined,
        )
      else
        ...minhasProvas.map((prova) => _linhaProva(context, prova)),
      const SizedBox(height: 22),
      OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BancoQuestoesScreen()),
        ),
        icon: const Icon(Icons.storage_outlined, size: 18),
        label: const Text('Ir para o Banco de Questões'),
      ),
    ];
  }

  Widget _linhaProva(BuildContext context, Prova prova) {
    // Se há alterações guardadas no aparelho (feitas sem conexão), mostra a
    // versão editada com o aviso.
    final editada = AppState.instancia.edicoesLocais[prova.id];
    final exibida = editada ?? prova;
    return LinhaProva(
      titulo: exibida.titulo,
      detalhe: '${exibida.curso} · ${exibida.data}',
      status: prova.status,
      aviso: editada != null
          ? _avisoLocal(ApiClient.instancia.semConexao.value)
          : null,
      aoTocar: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RevisaoProvaScreen(prova: prova)),
      ),
    );
  }

  /// Sem conexão: o que está no aparelho espera a internet. Com conexão, ainda
  /// não foi enviado (o envio automático roda a cada 15 s).
  static String _avisoLocal(bool semConexao) =>
      semConexao ? 'Sem conexão' : 'Não enviado';

  /// Motivo da última falha do envio automático (se o servidor respondeu com
  /// erro), para o professor saber por que a prova ainda não foi enviada.
  static String _motivoFalha() {
    final erro = AppState.instancia.erroSincronizacao.value;
    return erro == null ? '' : '\nNão enviada: $erro';
  }

  static String _situacaoLocal(String? acao) {
    switch (acao) {
      case 'enviar':
        return 'será enviada ao coordenador';
      case 'pdf':
        return 'o PDF será gerado';
      case 'docx':
        return 'o DOCX será gerado';
      default:
        return 'guardado neste aparelho';
    }
  }

  static String _assuntoMaisComum(List<Questao> questoes) {
    if (questoes.isEmpty) return '—';
    final contagem = <String, int>{};
    for (final questao in questoes) {
      contagem[questao.assunto] = (contagem[questao.assunto] ?? 0) + 1;
    }
    final entradas = contagem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entradas.first.key;
  }
}
