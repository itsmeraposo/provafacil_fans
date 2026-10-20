import 'package:flutter/material.dart';

import '../app_state.dart';
import '../theme.dart';
import '../validators.dart';
import '../widgets/common.dart';

/// TELA · Recuperar senha (`POST /api/auth/esqueci-senha`).
///
/// O servidor envia por e-mail um link (válido por 1 hora) para criar uma
/// nova senha. A resposta é sempre a mesma, exista ou não a conta.
class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key, this.emailInicial = ''});

  final String emailInicial;

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _enviando = false;
  String? _mensagem; // preenchida quando o pedido foi aceito pelo servidor
  String? _erro;

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

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final mensagem =
          await AppState.instancia.esqueciSenha(_emailController.text);
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _mensagem = mensagem;
      });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _mensagem != null ? _confirmacao() : _formulario(),
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
            validator: validarEmail,
          ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Text(_erro!,
                style:
                    const TextStyle(color: AppColors.claret, fontSize: 12.5)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enviar instruções'),
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
          'Pedido enviado',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          _mensagem!,
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
