import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

/// TELA · Perfil (comum aos três perfis de acesso).
///
/// Permite editar dados pessoais, alterar a senha (modal), ativar/desativar
/// preferências e excluir a conta (modal de confirmação), como previsto no
/// enunciado para a tela de perfil do usuário.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final TextEditingController _nomeController;
  late final TextEditingController _instituicaoController;
  late final TextEditingController _cargoController;
  bool _notificacoes = true;

  @override
  void initState() {
    super.initState();
    final usuario = AppState.instancia.usuarioAtual!;
    _nomeController = TextEditingController(text: usuario.nome);
    _instituicaoController = TextEditingController(text: usuario.instituicao);
    _cargoController = TextEditingController(text: usuario.cargo);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _instituicaoController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  void _salvar() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
  }

  void _abrirAlterarSenha() {
    final senhaAtual = TextEditingController();
    final senhaNova = TextEditingController();
    final senhaConfirma = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: senhaAtual,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha atual'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: senhaNova,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: senhaConfirma,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Senha alterada com sucesso.')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _abrirExcluirConta() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Essa ação é permanente e não pode ser desfeita. Sua conta e sessão '
          'serão encerradas imediatamente. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.claret),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              AppState.instancia.sair();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (rota) => false,
              );
            },
            child: const Text('Excluir definitivamente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AppState.instancia.usuarioAtual!;
    final cor = corDoPerfil(usuario.perfil.chave);

    return TelaPrincipal(
      titulo: 'Perfil',
      drawer: const AppDrawer(telaAtual: 'Perfil'),
      corpo: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: cor.withOpacity(0.14),
                child: Text(
                  usuario.nome.isNotEmpty ? usuario.nome[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: cor, fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(usuario.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(usuario.perfil.rotulo,
                        style: const TextStyle(
                            color: AppColors.inkMuted, fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const TituloSecao('Informações pessoais'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    enabled: false,
                    controller: TextEditingController(text: usuario.email),
                    decoration: const InputDecoration(labelText: 'E-mail'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instituicaoController,
                    decoration: const InputDecoration(labelText: 'Instituição'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cargoController,
                    decoration: const InputDecoration(labelText: 'Cargo'),
                  ),
                  if (usuario.perfil == Perfil.professor) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Cursos que leciona',
                          style: TextStyle(
                              color: AppColors.inkMuted, fontSize: 12.5)),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: usuario.cursos
                          .map((curso) => Chip(label: Text(curso)))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: _salvar,
                    child: const Text('Salvar alterações'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const TituloSecao('Segurança'),
          Card(
            child: Column(
              children: [
                _linhaAcao(
                  titulo: 'Senha',
                  descricao: 'Altere periodicamente para manter a conta segura.',
                  botao: OutlinedButton(
                    onPressed: _abrirAlterarSenha,
                    child: const Text('Alterar'),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notificações por e-mail'),
                  subtitle:
                      const Text('Receber atualizações sobre provas e aprovações.'),
                  value: _notificacoes,
                  onChanged: (valor) => setState(() => _notificacoes = valor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const TituloSecao('Zona de risco'),
          Card(
            child: _linhaAcao(
              titulo: 'Excluir minha conta',
              descricao: 'Esta ação não pode ser desfeita.',
              botao: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.claret),
                onPressed: _abrirExcluirConta,
                child: const Text('Excluir'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Linha "texto + botão": o texto ocupa o espaço restante e quebra de
  /// linha, então nunca passa por baixo do botão.
  Widget _linhaAcao({
    required String titulo,
    required String descricao,
    required Widget botao,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(descricao,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          botao,
        ],
      ),
    );
  }
}
