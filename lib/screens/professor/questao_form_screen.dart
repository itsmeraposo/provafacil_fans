import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';

/// TELA DE DETALHES · Cadastro/edição de questão.
///
/// Reaberta a partir do botão "+ Nova questão" (criação) ou ao tocar em uma
/// questão da lista no Banco de Questões (edição). O botão de voltar do
/// AppBar retorna sempre para a tela anterior.
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
  String _periodo = 'atual';

  bool get _editando => widget.questao != null;

  @override
  void initState() {
    super.initState();
    _textoController = TextEditingController(text: widget.questao?.texto ?? '');
    _assuntoController =
        TextEditingController(text: widget.questao?.assunto ?? '');
    _valorController = TextEditingController(
      text: widget.questao != null ? widget.questao!.valor.toString() : '1.0',
    );
    _periodo = widget.questao?.periodo ?? 'atual';
  }

  @override
  void dispose() {
    _textoController.dispose();
    _assuntoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 1.0;

    if (_editando) {
      final atualizada = Questao(
        id: widget.questao!.id,
        texto: _textoController.text.trim(),
        assunto: _assuntoController.text.trim(),
        periodo: _periodo,
        valor: valor,
        usadaEm: widget.questao!.usadaEm,
      );
      AppState.instancia.atualizarQuestao(atualizada);
    } else {
      final nova = Questao(
        id: 'q${DateTime.now().millisecondsSinceEpoch}',
        texto: _textoController.text.trim(),
        assunto: _assuntoController.text.trim(),
        periodo: _periodo,
        valor: valor,
      );
      AppState.instancia.adicionarQuestao(nova);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(_editando ? 'Questão atualizada.' : 'Questão adicionada ao banco.')),
    );
    Navigator.of(context).pop();
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
            onPressed: () {
              AppState.instancia.removerQuestao(widget.questao!.id);
              Navigator.of(dialogContext).pop(); // fecha o diálogo
              Navigator.of(context).pop(); // volta ao banco de questões
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar questão' : 'Nova questão'),
        actions: [
          if (_editando)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline),
              onPressed: _excluir,
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _periodo,
                      decoration: const InputDecoration(labelText: 'Período'),
                      items: const [
                        DropdownMenuItem(value: 'atual', child: Text('Atual')),
                        DropdownMenuItem(
                            value: 'historico', child: Text('Histórico')),
                      ],
                      onChanged: (valor) =>
                          setState(() => _periodo = valor ?? 'atual'),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvar,
                child: Text(_editando ? 'Salvar alterações' : 'Adicionar ao banco'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
