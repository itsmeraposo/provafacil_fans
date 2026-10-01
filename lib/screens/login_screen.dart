import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'direcao/painel_direcao_screen.dart';
import 'professor/painel_professor_screen.dart';
import 'repografia/painel_repografia_screen.dart';

/// Tela inicial da aplicação: login.
///
/// Como esta etapa do projeto trata apenas de navegação (o enunciado dispensa
/// a lógica completa de backend), o campo "Entrar como" simula a
/// autenticação e define qual perfil de acesso — professor, direção ou
/// repografia — a app deverá exibir a partir do login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'ana.souza@fans.edu.br');
  final _senhaController = TextEditingController(text: 'senha123');
  Perfil _perfilSelecionado = Perfil.professor;
  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final nome = switch (_perfilSelecionado) {
      Perfil.professor => 'Ana Beatriz Souza',
      Perfil.direcao => 'Roberto Nascimento',
      Perfil.repografia => 'Juliana Prado',
    };

    AppState.instancia.entrar(
      Usuario(
        nome: nome,
        email: _emailController.text.trim(),
        perfil: _perfilSelecionado,
        cargo: _perfilSelecionado == Perfil.professor ? 'Professor(a)' : '',
        cursos: _perfilSelecionado == Perfil.professor
            ? ['Análise e Desenvolvimento de Sistemas']
            : const [],
      ),
    );

    if (!mounted) return;
    setState(() => _carregando = false);

    final destino = switch (_perfilSelecionado) {
      Perfil.professor => const PainelProfessorScreen(),
      Perfil.direcao => const PainelDirecaoScreen(),
      Perfil.repografia => const PainelRepografiaScreen(),
    };

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destino),
      (rota) => false,
    );
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'PF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'ProvaFácil',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'FANS — Faculdade Nossa Senhora',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Entrar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (valor) => (valor == null || !valor.contains('@'))
                          ? 'Informe um e-mail válido'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _senhaController,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      validator: (valor) => (valor == null || valor.length < 4)
                          ? 'Informe sua senha'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Entrar como',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...Perfil.values.map(_opcaoPerfil),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Esqueci minha senha'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _carregando ? null : _entrar,
                      child: _carregando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Ainda não tem conta? Cadastre-se'),
                      ),
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

  Widget _opcaoPerfil(Perfil perfil) {
    final selecionado = perfil == _perfilSelecionado;
    final cor = corDoPerfil(perfil.chave);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _perfilSelecionado = perfil),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selecionado ? cor.withOpacity(0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selecionado ? cor : AppColors.rule,
              width: selecionado ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selecionado
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: selecionado ? cor : AppColors.inkFaint,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      perfil.rotulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        color: selecionado ? cor : AppColors.ink,
                      ),
                    ),
                    Text(
                      perfil.descricao,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
