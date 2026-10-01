import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'painel_direcao_screen.dart';

/// TELA DE DETALHES · Revisão da Direção.
///
/// Acessada a partir do Painel da Direção. Permite marcar questões
/// problemáticas, escrever um comentário para o professor e decidir entre
/// aprovar, reprovar ou deixar a prova em análise.
class RevisaoDirecaoScreen extends StatefulWidget {
  const RevisaoDirecaoScreen({super.key, required this.prova});

  final Prova prova;

  @override
  State<RevisaoDirecaoScreen> createState() => _RevisaoDirecaoScreenState();
}

class _RevisaoDirecaoScreenState extends State<RevisaoDirecaoScreen> {
  final Set<String> _questoesMarcadas = {};
  final _comentarioController = TextEditingController();

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  bool get _jaDecidida =>
      widget.prova.status == StatusProva.aprovada ||
      widget.prova.status == StatusProva.reprovada;

  void _decidir(StatusProva novoStatus) {
    AppState.instancia.atualizarStatusProva(
      widget.prova.id,
      novoStatus,
      comentario: _comentarioController.text.trim().isEmpty
          ? null
          : _comentarioController.text.trim(),
    );

    final mensagem = switch (novoStatus) {
      StatusProva.aprovada => 'Prova aprovada e liberada para a Repografia.',
      StatusProva.reprovada => 'Prova reprovada. O professor foi notificado.',
      _ => 'Prova mantida em análise.',
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PainelDirecaoScreen()),
      (rota) => false,
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final prova = widget.prova;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(prova.titulo),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Prova (prévia)'),
              Tab(text: 'Questões e decisão'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _abaPrevia(prova),
            _abaDecisao(prova),
          ],
        ),
      ),
    );
  }

  Widget _abaPrevia(Prova prova) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prova.titulo,
                      style:
                          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${prova.curso} · Etapa ${prova.etapa} · ${prova.data}',
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 12.5)),
                  const SizedBox(height: 2),
                  Text('Professor(a): ${prova.professor}',
                      style: const TextStyle(color: AppColors.inkMuted, fontSize: 12.5)),
                  const Divider(height: 28),
                  Text('Prévia simulada do PDF gerado (sem geração real de '
                      'arquivo nesta etapa). ${prova.questoes.length} questão(ões), '
                      '${prova.pontuacaoTotal.toStringAsFixed(1)} pts no total.',
                      style: const TextStyle(fontSize: 12.5, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _abaDecisao(Prova prova) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_jaDecidida)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta prova já foi ${prova.status.rotulo.toLowerCase()}.'
                      '${prova.comentarioDirecao != null ? '\nComentário: ${prova.comentarioDirecao}' : ''}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          TituloSecao('Questões da prova', contador: prova.questoes.length),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'Marque as questões que motivam a reprovação, se for o caso.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 12.5),
            ),
          ),
          if (prova.questoes.isEmpty)
            const EstadoVazio(texto: 'Esta prova ainda não tem questões.')
          else
            ...prova.questoes.map((questao) {
              final marcada = _questoesMarcadas.contains(questao.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: marcada ? AppColors.claretSoft : null,
                child: CheckboxListTile(
                  value: marcada,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: _jaDecidida
                      ? null
                      : (valor) => setState(() {
                            if (valor == true) {
                              _questoesMarcadas.add(questao.id);
                            } else {
                              _questoesMarcadas.remove(questao.id);
                            }
                          }),
                  title: Text(questao.texto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5)),
                  subtitle: Text(questao.assunto,
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
                ),
              );
            }),
          const SizedBox(height: 8),
          TextField(
            controller: _comentarioController,
            enabled: !_jaDecidida,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Comentário para o professor (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          if (!_jaDecidida) ...[
            ElevatedButton(
              onPressed: () => _decidir(StatusProva.aprovada),
              child: const Text('Aprovar prova'),
            ),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.claret),
              onPressed: () => _decidir(StatusProva.reprovada),
              child: const Text('Reprovar prova'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _decidir(StatusProva.emRevisao),
              child: const Text('Deixar em análise'),
            ),
          ],
        ],
      ),
    );
  }
}
