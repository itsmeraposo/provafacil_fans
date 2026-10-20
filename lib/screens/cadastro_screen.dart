import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../validators.dart';
import '../widgets/common.dart';

/// TELA · Cadastro de conta (`POST /api/auth/registrar`).
///
/// Professor escolhe os cursos que leciona; Direção e Repografia precisam do
/// código de convite fornecido pela instituição. Depois do cadastro o servidor
/// envia um link de confirmação por e-mail — só então o login é liberado.
class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmaController = TextEditingController();
  final _conviteController = TextEditingController();
  final Set<String> _cursos = {};
  Perfil _perfil = Perfil.professor;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    AppState.instancia.carregarConstantes().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaController.dispose();
    _conviteController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_perfil == Perfil.professor && _cursos.isEmpty) {
      setState(() => _erro = 'Selecione pelo menos um curso que você leciona.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      final mensagem = await AppState.instancia.registrar(
        nome: _nomeController.text,
        email: _emailController.text,
        senha: _senhaController.text,
        perfil: _perfil,
        cursos: _cursos.toList(),
        codigoConvite: _conviteController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Conta criada'),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(_emailController.text.trim());
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _erro = textoDoErro(erro);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cursos = AppState.instancia.cursosDisponiveis;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'Nome completo'),
                      validator: (valor) =>
                          (valor == null || valor.trim().isEmpty)
                              ? 'Informe seu nome'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: validarEmail,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Perfil>(
                      isExpanded: true,
                      value: _perfil,
                      decoration: const InputDecoration(labelText: 'Perfil'),
                      items: Perfil.values
                          .map((perfil) => DropdownMenuItem(
                                value: perfil,
                                child: Text(perfil.rotulo,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (valor) =>
                          setState(() => _perfil = valor ?? _perfil),
                    ),
                    const SizedBox(height: 12),
                    if (_perfil == Perfil.professor) ...[
                      const Text('Cursos que você leciona',
                          style: TextStyle(
                              color: AppColors.inkMuted, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final curso in cursos)
                            FilterChip(
                              label: Text(curso),
                              selected: _cursos.contains(curso),
                              onSelected: (marcado) => setState(() {
                                if (marcado) {
                                  _cursos.add(curso);
                                } else {
                                  _cursos.remove(curso);
                                }
                              }),
                            ),
                        ],
                      ),
                    ] else
                      TextFormField(
                        controller: _conviteController,
                        decoration: InputDecoration(
                          labelText: 'Código de convite da ${_perfil.rotulo}',
                          helperText:
                              'Fornecido pela instituição para este perfil.',
                          helperMaxLines: 2,
                        ),
                        validator: (valor) =>
                            (valor == null || valor.trim().isEmpty)
                                ? 'Informe o código de convite'
                                : null,
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        helperText: 'Mínimo de 10 caracteres, com maiúscula, '
                            'minúscula, número e caractere especial.',
                        helperMaxLines: 3,
                        errorMaxLines: 3,
                      ),
                      validator: validarSenhaForte,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmaController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Confirmar senha'),
                      validator: (valor) => valor != _senhaController.text
                          ? 'As senhas não conferem'
                          : null,
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(_erro!,
                          style: const TextStyle(
                              color: AppColors.claret, fontSize: 12.5)),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _enviando ? null : _criarConta,
                      child: _enviando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Criar conta'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Já tenho conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
