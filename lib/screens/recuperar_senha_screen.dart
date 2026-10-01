import 'package:flutter/material.dart';

import '../theme.dart';

/// TELA · Recuperar senha.
///
/// Acessada pelo link "Esqueci minha senha" do login. O envio do e-mail é
/// simulado nesta etapa: a tela só confirma o pedido e oferece voltar ao
/// login.
class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _enviado = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.emailInicial);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviado = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _enviado ? _confirmacao() : _formulario(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Informe o e-mail da sua conta e enviaremos as instruções para '
            'criar uma nova senha.',
            style: TextStyle(fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
            validator: (valor) => (valor == null || !valor.contains('@'))
                ? 'Informe um e-mail válido'
                : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _enviar,
            child: const Text('Enviar instruções'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar ao login'),
          ),
        ],
      ),
    );
  }

  Widget _confirmacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 40, color: AppColors.moss),
        const SizedBox(height: 14),
        const Text(
          'Instruções enviadas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Se existir uma conta para ${_emailController.text.trim()}, '
          'você receberá um e-mail com o passo a passo. '
          '(Envio simulado nesta etapa.)',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 13, height: 1.4, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Voltar ao login'),
        ),
      ],
    );
  }
}
