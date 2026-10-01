import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../screens/direcao/painel_direcao_screen.dart';
import '../screens/login_screen.dart';
import '../screens/perfil_screen.dart';
import '../screens/professor/banco_questoes_screen.dart';
import '../screens/professor/painel_professor_screen.dart';
import '../screens/repografia/painel_repografia_screen.dart';
import '../theme.dart';

/// Item de menu do drawer lateral.
class _ItemMenu {
  const _ItemMenu(this.rotulo, this.icone, this.destino);
  final String rotulo;
  final IconData icone;
  final Widget Function() destino;
}

/// Drawer (menu lateral / "hambúrguer") comum a todas as telas principais.
///
/// Os itens exibidos mudam de acordo com o [perfil] logado — é o menu lateral
/// pedido no enunciado, com opções específicas para cada perfil de usuário.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.telaAtual});

  /// Nome da tela atualmente aberta, usado para destacar o item ativo.
  final String telaAtual;

  List<_ItemMenu> _itensParaPerfil(Perfil perfil) {
    switch (perfil) {
      case Perfil.professor:
        return [
          _ItemMenu('Início', Icons.dashboard_outlined,
              () => const PainelProfessorScreen()),
          _ItemMenu('Banco de Questões', Icons.storage_outlined,
              () => const BancoQuestoesScreen()),
          _ItemMenu(
              'Perfil', Icons.person_outline, () => const PerfilScreen()),
        ];
      case Perfil.direcao:
        return [
          _ItemMenu('Início', Icons.dashboard_outlined,
              () => const PainelDirecaoScreen()),
          _ItemMenu(
              'Perfil', Icons.person_outline, () => const PerfilScreen()),
        ];
      case Perfil.repografia:
        return [
          _ItemMenu('Início', Icons.dashboard_outlined,
              () => const PainelRepografiaScreen()),
          _ItemMenu(
              'Perfil', Icons.person_outline, () => const PerfilScreen()),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = AppState.instancia;
    final usuario = estado.usuarioAtual!;
    final cor = corDoPerfil(usuario.perfil.chave);
    final itens = _itensParaPerfil(usuario.perfil);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'PF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ProvaFácil',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final item in itens)
                    _linhaMenu(
                      context,
                      item: item,
                      ativo: item.rotulo == telaAtual,
                      cor: cor,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: cor.withOpacity(0.14),
                    child: Text(
                      _iniciais(usuario.nome),
                      style: TextStyle(
                        color: cor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          usuario.nome,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          usuario.perfil.rotulo,
                          style: const TextStyle(
                              color: AppColors.inkMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout, size: 19),
                    onPressed: () => _sair(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaMenu(
    BuildContext context, {
    required _ItemMenu item,
    required bool ativo,
    required Color cor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: ativo ? cor.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(item.icone,
              size: 19, color: ativo ? cor : AppColors.inkMuted),
          title: Text(
            item.rotulo,
            style: TextStyle(
              fontSize: 13.5,
              color: ativo ? cor : AppColors.ink,
              fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          onTap: () {
            Navigator.of(context).pop(); // fecha o drawer
            if (ativo) return; // já está na tela
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => item.destino()),
            );
          },
        ),
      ),
    );
  }

  void _sair(BuildContext context) {
    Navigator.of(context).pop(); // fecha o drawer
    AppState.instancia.sair();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (rota) => false,
    );
  }

  static String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '··';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return (partes.first.substring(0, 1) + partes.last.substring(0, 1))
        .toUpperCase();
  }
}
