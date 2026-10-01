import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'login_screen.dart';

/// TELA · Boas-vindas (tela inicial do app).
///
/// Apresenta o ProvaFácil e os três perfis de acesso. O botão "Começar"
/// leva ao login; o botão de voltar do login retorna a esta tela.
class BoasVindasScreen extends StatelessWidget {
  const BoasVindasScreen({super.key});

  IconData _icone(Perfil perfil) {
    switch (perfil) {
      case Perfil.professor:
        return Icons.edit_note_outlined;
      case Perfil.direcao:
        return Icons.fact_check_outlined;
      case Perfil.repografia:
        return Icons.print_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'PF',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ProvaFácil',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'FANS — Faculdade de Nova Serrana',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Banco de questões, aprovação e impressão de provas em um só lugar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  for (final perfil in Perfil.values) _linhaPerfil(perfil),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    child: const Text('Começar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _linhaPerfil(Perfil perfil) {
    final cor = corDoPerfil(perfil.chave);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.rule),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_icone(perfil), size: 19, color: cor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    perfil.rotulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    perfil.descricao,
                    style: const TextStyle(
                        color: AppColors.inkMuted, fontSize: 12),
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
