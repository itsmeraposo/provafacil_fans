import 'package:flutter/material.dart';

import '../api.dart';
import '../app_state.dart';
import '../theme.dart';

/// Envolve o app inteiro. Quando o app está sem conexão com o servidor (e há
/// alguém dentro do painel), mostra no topo de TODAS as telas uma faixa bem
/// visível dizendo isso e explicando que os dados são reais (cópia guardada
/// no aparelho), não dados de exemplo.
class MoldeOffline extends StatelessWidget {
  const MoldeOffline({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ApiClient.instancia.semConexao,
        AppState.instancia,
      ]),
      builder: (context, _) {
        final visivel =
            ApiClient.instancia.semConexao.value && AppState.instancia.logado;
        final pendentes =
            AppState.instancia.questoes.where((q) => q.pendente).length;

        // A estrutura (Column > Expanded > child) é sempre a mesma, para o
        // navegador do app não ser recriado quando a faixa aparece/some.
        return Column(
          children: [
            if (visivel)
              Material(
              color: AppColors.claret,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SEM CONEXÃO COM O SERVIDOR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                letterSpacing: 0.3,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Você está vendo a última cópia salva neste '
                              'aparelho (dados reais, não de exemplo). O que '
                              'for cadastrado aqui será enviado quando a '
                              'conexão voltar.'
                              '${pendentes > 0 ? ' Pendentes de envio: $pendentes.' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                height: 1.25,
                                fontWeight: FontWeight.w400,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => AppState.instancia.carregarDados(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              // Com a faixa visível ela já ocupa a área da barra de status:
              // as telas não precisam reservar esse espaço de novo.
              child: MediaQuery.removePadding(
                context: context,
                removeTop: visivel,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
