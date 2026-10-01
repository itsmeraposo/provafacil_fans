import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'painel_repografia_screen.dart';

/// TELA DE DETALHES · Impressão de prova (perfil Repografia).
///
/// Acessada a partir do Painel da Repografia. Mostra os dados da prova
/// aprovada e permite marcá-la como impressa, retornando ao painel.
class DetalheImpressaoScreen extends StatelessWidget {
  const DetalheImpressaoScreen({super.key, required this.prova});

  final Prova prova;

  @override
  Widget build(BuildContext context) {
    final jaImpressa = prova.status == StatusProva.impressa;

    return Scaffold(
      appBar: AppBar(title: Text(prova.titulo)),
      body: SafeArea(
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
                                  fontSize: 16, fontWeight: FontWeight.w600)),
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
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.rule),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf_outlined,
                      size: 34, color: AppColors.inkFaint),
                  SizedBox(height: 8),
                  Text('Prévia do PDF (simulada nesta etapa)',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12.5)),
                ],
              ),
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
                onPressed: () {
                  AppState.instancia
                      .atualizarStatusProva(prova.id, StatusProva.aprovada);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const PainelRepografiaScreen()),
                    (rota) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Impressão desfeita. A prova voltou para a fila.')),
                  );
                },
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Desfazer impressão'),
              ),
            ]
            else
              ElevatedButton.icon(
                onPressed: () {
                  AppState.instancia
                      .atualizarStatusProva(prova.id, StatusProva.impressa);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const PainelRepografiaScreen()),
                    (rota) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prova marcada como impressa.')),
                  );
                },
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Marcar como impressa'),
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
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(valor,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
