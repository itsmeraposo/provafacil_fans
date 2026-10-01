import 'package:flutter/material.dart';

import '../models.dart';

/// TELA · Cadastro de conta.
///
/// Acessada pelo link "Cadastre-se" do login. Como não há backend nesta
/// etapa, o cadastro é simulado: valida os campos, avisa que a conta foi
/// criada e volta ao login com o e-mail já preenchido.
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
  Perfil _perfil = Perfil.professor;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmaController.dispose();
    super.dispose();
  }

  void _criarConta() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conta criada. Faça login para continuar.')),
    );
    Navigator.of(context).pop(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
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
                      validator: (valor) =>
                          (valor == null || !valor.contains('@'))
                              ? 'Informe um e-mail válido'
                              : null,
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
                    TextFormField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      validator: (valor) => (valor == null || valor.length < 6)
                          ? 'Use ao menos 6 caracteres'
                          : null,
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _criarConta,
                      child: const Text('Criar conta'),
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
