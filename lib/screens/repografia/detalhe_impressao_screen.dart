import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../arquivos.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'painel_repografia_screen.dart';

/// TELA DE DETALHES · Impressão de prova (perfil Repografia).
///
/// Mostra os dados da prova aprovada, abre o PDF para imprimir
/// (`GET /api/provas/:id/previa-pdf`) e marca ou desmarca a impressão
/// (`PATCH /api/provas/:id/impressao`), retornando ao painel.
class DetalheImpressaoScreen extends StatefulWidget {
  const DetalheImpressaoScreen({super.key, required this.prova});

  final Prova prova;

  @override
  State<DetalheImpressaoScreen> createState() => _DetalheImpressaoScreenState();
}

class _DetalheImpressaoScreenState extends State<DetalheImpressaoScreen> {
  bool _ocupado = false;

  Future<void> _abrirPdf() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      final bytes =
          await AppState.instancia.baixarPreviaPdf(widget.prova.id);
      if (!mounted) return;
      await Arquivos.abrirPdfNoApp(
          context, bytes, Arquivos.nome(widget.prova.titulo, 'pdf'));
    } catch (erro) {
      if (mounted) mostrarMensagem(context, textoDoErro(erro));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _marcar({required bool impressa}) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await AppState.instancia
          .marcarImpressao(widget.prova.id, impressa: impressa);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PainelRepografiaScreen()),
        (rota) => false,
      );
      mostrarMensagem(
        context,
        impressa
            ? 'Prova marcada como impressa.'
            : 'Impressão desfeita. A prova voltou para a fila.',
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      mostrarMensagem(context, textoDoErro(erro));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prova = widget.prova;
    final jaImpressa = prova.status == StatusProva.impressa;

    return Scaffold(
      appBar: AppBar(title: Text(prova.titulo)),
      body: SafeArea(
        child: Column(
          children: [
            if (_ocupado) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(prova.titulo,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 10),
                              SeloStatus(prova.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _linhaDado('Curso', prova.curso),
                          _linhaDado('Professor(a)', prova.professor),
                          _linhaDado('Etapa', prova.etapa),
                          _linhaDado('Data', prova.data.isEmpty ? '—' : prova.data),
                          _linhaDado('Valor', prova.valorProva),
                          _linhaDado('Questões', '${prova.questoes.length}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _ocupado ? null : _abrirPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Abrir PDF para imprimir'),
                  ),
                  const SizedBox(height: 24),
                  if (jaImpressa) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.mossSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: AppColors.moss),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Esta prova já foi marcada como impressa.',
                                style: TextStyle(
                                    color: AppColors.moss, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _ocupado ? null : () => _marcar(impressa: false),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Desfazer impressão'),
                    ),
                  ] else
                    ElevatedButton.icon(
                      onPressed: _ocupado ? null : () => _marcar(impressa: true),
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: const Text('Marcar como impressa'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaDado(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(rotulo,
                style:
                    const TextStyle(color: AppColors.inkMuted, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
