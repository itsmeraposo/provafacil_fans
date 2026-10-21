import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// TELA DE DETALHES · Cadastro/edição de questão.
///
/// "Nova questão" cria (`POST /api/questoes`); tocar numa questão da lista
/// edita (`PUT /api/questoes/:id`) ou exclui (`DELETE /api/questoes/:id`).
/// O botão de voltar do AppBar retorna sempre para a tela anterior.
class QuestaoFormScreen extends StatefulWidget {
  const QuestaoFormScreen({super.key, this.questao});

  /// Quando nulo, a tela funciona no modo de criação de uma questão nova.
  final Questao? questao;

  @override
  State<QuestaoFormScreen> createState() => _QuestaoFormScreenState();
}

class _QuestaoFormScreenState extends State<QuestaoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textoController;
  late final TextEditingController _assuntoController;
  late final TextEditingController _valorController;
  late String _curso;
  late int _periodo;
  late String _tipo;
  bool _salvando = false;

  bool get _editando => widget.questao != null;

  List<String> get _cursosDoUsuario {
    final usuario = AppState.instancia.usuarioAtual;
    final lista = <String>{
      ...?usuario?.cursos,
      if (widget.questao != null && widget.questao!.curso.isNotEmpty)
        widget.questao!.curso,
    }.toList();
    return lista.isEmpty ? AppState.instancia.cursosDisponiveis : lista;
  }

  @override
  void initState() {
    super.initState();
    final questao = widget.questao;
    _textoController = TextEditingController(text: questao?.texto ?? '');
    _assuntoController = TextEditingController(text: questao?.assunto ?? '');
    _valorController = TextEditingController(
      text: questao != null ? questao.valor.toString() : '1.0',
    );
    _curso = (questao != null && questao.curso.isNotEmpty)
        ? questao.curso
        : _cursosDoUsuario.first;
    _periodo = questao?.periodo ?? 1;
    _tipo = questao?.tipo ?? 'dissertativa';
  }

  @override
  void dispose() {
    _textoController.dispose();
    _assuntoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final valor =
        double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 1.0;

    setState(() => _salvando = true);
    try {
      final noServidor = await AppState.instancia.salvarQuestao(
        id: widget.questao?.id,
        texto: _textoController.text.trim(),
        tipo: _tipo,
        assunto: _assuntoController.text.trim(),
        curso: _curso,
        periodo: _periodo,
        valor: valor,
      );
      if (!mounted) return;
      mostrarMensagem(
          context,
          !noServidor
              ? 'Sem conexão: questão salva no aparelho. Será enviada quando '
                  'houver conexão.'
              : _editando
                  ? 'Questão atualizada.'
                  : 'Questão adicionada ao banco.');
      Navigator.of(context).pop();
    } catch (erro) {
      if (!mounted) return;
      setState(() => _salvando = false);
      mostrarMensagem(context, textoDoErro(erro));
    }
  }

  void _excluir() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir questão'),
        content: const Text(
            'Esta ação não pode ser desfeita. Deseja excluir esta questão do banco?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.claret),
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // fecha o diálogo
              try {
                await AppState.instancia.removerQuestao(widget.questao!.id);
                if (!mounted) return;
                Navigator.of(context).pop(); // volta ao banco de questões
                mostrarMensagem(context, 'Questão excluída.');
              } catch (erro) {
                if (mounted) mostrarMensagem(context, textoDoErro(erro));
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cursos = _cursosDoUsuario;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar questão' : 'Nova questão'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _salvando ? null : _excluir,
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_editando)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('Usada em ${widget.questao!.usadaEm} prova(s)',
                      style: const TextStyle(
                          color: AppColors.inkMuted, fontSize: 12.5)),
                ),
              TextFormField(
                controller: _textoController,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Texto da questão',
                  alignLabelWithHint: true,
                ),
                validator: (valor) =>
                    (valor == null || valor.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _assuntoController,
                decoration: const InputDecoration(labelText: 'Assunto'),
                validator: (valor) =>
                    (valor == null || valor.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _curso,
                decoration: const InputDecoration(labelText: 'Curso'),
                items: cursos
                    .map((curso) => DropdownMenuItem(
                        value: curso,
                        child: Text(curso, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (valor) => setState(() => _curso = valor ?? _curso),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _periodo,
                      decoration: const InputDecoration(labelText: 'Período'),
                      items: List.generate(
                        10,
                        (i) => DropdownMenuItem(
                            value: i + 1, child: Text('${i + 1}º')),
                      ),
                      onChanged: (valor) =>
                          setState(() => _periodo = valor ?? _periodo),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _valorController,
                      decoration: const InputDecoration(labelText: 'Valor (pts)'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (valor) =>
                          (valor == null || valor.trim().isEmpty)
                              ? 'Obrigatório'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _tipo,
                decoration: const InputDecoration(labelText: 'Tipo da questão'),
                items: const [
                  DropdownMenuItem(
                      value: 'dissertativa', child: Text('Dissertativa')),
                  DropdownMenuItem(
                      value: 'multipla_escolha',
                      child: Text('Múltipla escolha')),
                ],
                onChanged: (valor) => setState(() => _tipo = valor ?? _tipo),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_editando ? 'Salvar alterações' : 'Adicionar ao banco'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
