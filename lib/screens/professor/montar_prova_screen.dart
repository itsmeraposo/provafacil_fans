import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../preferencias.dart';
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

  /// Rascunho de prova guardado neste aparelho (ainda não enviado ao servidor).
  Prova? _rascunhoLocal;

  @override
  void initState() {
    super.initState();
    _carregarRascunhoLocal();
  }

  Future<void> _carregarRascunhoLocal() async {
    final usuario = AppState.instancia.usuarioAtual;
    if (usuario == null) return;
    final rascunho = await Preferencias.lerRascunhoLocal(usuario.id);
    if (!mounted) return;
    setState(() => _rascunhoLocal = rascunho);
  }

  void _continuarRascunhoLocal() {
    final rascunho = _rascunhoLocal;
    if (rascunho == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RevisaoProvaScreen(prova: rascunho, provaNova: true),
      ),
    );
  }

  Future<void> _descartarRascunhoLocal() async {
    final usuario = AppState.instancia.usuarioAtual;
    if (usuario != null) await Preferencias.apagarRascunhoLocal(usuario.id);
    if (!mounted) return;
    setState(() => _rascunhoLocal = null);
  }

  Widget _avisoRascunhoLocal(Prova rascunho) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: AppColors.accentSoft,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rascunho salvo neste aparelho',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              '${rascunho.titulo} · ${rascunho.questoes.length} questão(ões)',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _descartarRascunhoLocal,
                  child: const Text('Descartar'),
                ),
                TextButton(
                  onPressed: _continuarRascunhoLocal,
                  child: const Text('Continuar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double get _pontosSelecionados {
    final questoes = AppState.instancia.questoesEnviadas;
    return questoes
        .where((q) => _selecionadas.contains(q.id))
        .fold<double>(0, (soma, q) => soma + q.valor);
  }

  /// Se já houver um rascunho guardado no aparelho, a prova nova o
  /// substituiria: pergunta antes de seguir.
  Future<bool> _confirmarSubstituicao() async {
    final usuario = AppState.instancia.usuarioAtual;
    if (usuario == null) return true;
    final existente = await Preferencias.lerRascunhoLocal(usuario.id);
    if (existente == null || !mounted) return true;
    final substituir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Substituir rascunho?'),
        content: Text(
          'Já existe um rascunho guardado neste aparelho '
          '("${existente.titulo}", ${existente.questoes.length} questão(ões)). '
          'Se continuar, ele será substituído por esta prova.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Substituir'),
          ),
        ],
      ),
    );
    return substituir == true;
  }

  Future<void> _continuar() async {
    if (!await _confirmarSubstituicao() || !mounted) return;
    final estado = AppState.instancia;
    final usuario = estado.usuarioAtual!;
    final questoesSelecionadas =
        estado.questoes.where((q) => _selecionadas.contains(q.id)).toList();

    // Prova nova ainda não existe no servidor (id vazio): ela é criada ao
    // salvar o rascunho, enviar ao coordenador ou gerar o arquivo.
    final novaProva = Prova(
      id: '',
      titulo: 'Avaliação',
      curso: usuario.cursos.isNotEmpty
          ? usuario.cursos.first
          : estado.cursosDisponiveis.first,
      professor: usuario.nome,
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
    final questoes = AppState.instancia.questoesEnviadas;
    final pontos = _pontosSelecionados;
    final faltam = (10 - pontos).clamp(0, 10);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passo 1 de 2 · Questões'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_rascunhoLocal != null) _avisoRascunhoLocal(_rascunhoLocal!),
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
