import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../arquivos.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../professor/painel_professor_screen.dart';

/// TELA · Revisão e geração da prova — passo 2 de 2.
///
/// Reordena/remove questões, preenche o cabeçalho e então:
/// - "Salvar rascunho"  → `POST /api/provas/rascunho`
/// - "Enviar para o coordenador" → `POST /api/provas/enviar`
/// - "Gerar PDF / DOCX" → `POST /api/provas/gerar-pdf` e `gerar-docx`
/// Só rascunhos podem ser editados; provas enviadas, aprovadas, reprovadas ou
/// impressas ficam somente para leitura (regra do servidor).
class RevisaoProvaScreen extends StatefulWidget {
  const RevisaoProvaScreen({
    super.key,
    required this.prova,
    this.provaNova = false,
  });

  final Prova prova;

  /// Indica que a prova ainda não foi salva no servidor.
  final bool provaNova;

  @override
  State<RevisaoProvaScreen> createState() => _RevisaoProvaScreenState();
}

class _RevisaoProvaScreenState extends State<RevisaoProvaScreen> {
  static const _instrucoesPadrao =
      'A avaliação deve ser realizada individualmente;\n'
      'Não é admitida nenhuma forma de consulta a qualquer tipo de material;\n'
      'Celulares devem permanecer desligados durante toda a avaliação.';

  late final TextEditingController _tituloController;
  late final TextEditingController _periodoController;
  late final TextEditingController _etapaController;
  late final TextEditingController _dataController;
  late final TextEditingController _valorController;
  late final TextEditingController _professorController;
  late final TextEditingController _instrucoesController;
  late String _curso;
  late List<Questao> _questoes;
  late String _provaId;
  bool _ocupado = false;

  bool get _travada => widget.prova.status != StatusProva.rascunho;

  bool get _decidida =>
      widget.prova.status == StatusProva.aprovada ||
      widget.prova.status == StatusProva.reprovada ||
      widget.prova.status == StatusProva.impressa;

  List<String> get _cursosOpcoes {
    final usuario = AppState.instancia.usuarioAtual;
    final lista = <String>{
      ...?usuario?.cursos,
      if (widget.prova.curso.isNotEmpty) widget.prova.curso,
    }.toList();
    return lista.isEmpty ? AppState.instancia.cursosDisponiveis : lista;
  }

  @override
  void initState() {
    super.initState();
    final prova = widget.prova;
    _provaId = widget.provaNova ? '' : prova.id;
    _tituloController = TextEditingController(text: prova.titulo);
    _periodoController = TextEditingController(text: prova.periodo);
    _etapaController = TextEditingController(text: prova.etapa);
    _dataController = TextEditingController(text: prova.data);
    _valorController = TextEditingController(text: prova.valorProva);
    _professorController = TextEditingController(text: prova.professor);
    _instrucoesController = TextEditingController(
      text: prova.instrucoes.trim().isEmpty
          ? _instrucoesPadrao
          : prova.instrucoes,
    );
    _curso = prova.curso.isNotEmpty ? prova.curso : _cursosOpcoes.first;
    _questoes = List.of(prova.questoes);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _periodoController.dispose();
    _etapaController.dispose();
    _dataController.dispose();
    _valorController.dispose();
    _professorController.dispose();
    _instrucoesController.dispose();
    super.dispose();
  }

  /// Monta a prova com o que está na tela, pronta para enviar ao servidor.
  Prova _provaAtual() {
    final titulo = _tituloController.text.trim();
    return Prova(
      id: _provaId,
      titulo: titulo.isEmpty ? 'Avaliação' : titulo,
      curso: _curso,
      professor: _professorController.text.trim(),
      data: _dataController.text.trim(),
      periodo: _periodoController.text.trim(),
      etapa: _etapaController.text.trim(),
      valorProva: _valorController.text.trim(),
      instrucoes: _instrucoesController.text.trim(),
      questoes: List.of(_questoes),
      status: widget.prova.status,
    );
  }

  bool _temQuestoes() {
    if (_questoes.isNotEmpty) return true;
    mostrarMensagem(context, 'Adicione ao menos uma questão antes de continuar.');
    return false;
  }

  Future<void> _salvarRascunho() async {
    if (_ocupado || !_temQuestoes()) return;
    setState(() => _ocupado = true);
    try {
      final salva = await AppState.instancia.salvarRascunho(_provaAtual());
      _provaId = salva.id;
      if (mounted) mostrarMensagem(context, 'Rascunho salvo.');
    } catch (erro) {
      if (mounted) mostrarMensagem(context, textoDoErro(erro));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _enviarParaCoordenador() async {
    if (_ocupado || !_temQuestoes()) return;
    setState(() => _ocupado = true);
    try {
      await AppState.instancia.enviarParaCoordenador(_provaAtual());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PainelProfessorScreen()),
        (rota) => false,
      );
      mostrarMensagem(context, 'Prova enviada para a Direção revisar.');
    } catch (erro) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      mostrarMensagem(context, textoDoErro(erro));
    }
  }

  Future<void> _gerar(String formato) async {
    if (_ocupado || !_temQuestoes()) return;
    setState(() => _ocupado = true);
    try {
      // Prova nova: salva antes como rascunho, para o servidor não criar
      // outro registro a cada arquivo gerado.
      if (_provaId.isEmpty && !_travada) {
        final salva = await AppState.instancia.salvarRascunho(_provaAtual());
        _provaId = salva.id;
      }
      final prova = _provaAtual();
      final bytes = await AppState.instancia.gerarArquivo(prova, formato);
      final nome = Arquivos.nome(prova.titulo, formato);
      if (formato == 'pdf') {
        if (!mounted) return;
        await Arquivos.abrirPdfNoApp(context, bytes, nome);
      } else {
        await Arquivos.compartilhar(bytes, nome, mime: mimeDocx);
      }
    } catch (erro) {
      if (mounted) mostrarMensagem(context, textoDoErro(erro));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _excluirRascunho() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir rascunho'),
        content: const Text('Esta prova será apagada. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.claret),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await AppState.instancia.excluirProva(_provaId);
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (_) => const PainelProfessorScreen()),
                  (rota) => false,
                );
                mostrarMensagem(context, 'Rascunho excluído.');
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

  void _mover(int indice, int deslocamento) {
    final destino = indice + deslocamento;
    if (destino < 0 || destino >= _questoes.length) return;
    setState(() {
      final item = _questoes.removeAt(indice);
      _questoes.insert(destino, item);
    });
  }

  void _remover(int indice) {
    setState(() => _questoes.removeAt(indice));
  }

  @override
  Widget build(BuildContext context) {
    final pontos = _questoes.fold<double>(0, (soma, q) => soma + q.valor);
    final podeExcluir = _provaId.isNotEmpty && !_travada;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passo 2 de 2 · Revisão'),
        actions: [
          if (podeExcluir)
            IconButton(
              tooltip: 'Excluir rascunho',
              icon: const Icon(Icons.delete_outline),
              onPressed: _ocupado ? null : _excluirRascunho,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_ocupado) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_decidida) _avisoTravada(),
                  if (widget.prova.status == StatusProva.emRevisao)
                    _avisoStatus(
                      'Esta prova está em revisão pela Direção.',
                      AppColors.amber,
                    ),
                  const TituloSecao('Cabeçalho da prova'),
                  _cabecalho(),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: TituloSecao('Ordem das questões',
                            contador: _questoes.length),
                      ),
                      const SizedBox(width: 8),
                      Text('${pontos.toStringAsFixed(1)} / 10,0 pts',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ],
                  ),
                  if (_questoes.isEmpty)
                    const EstadoVazio(texto: 'Nenhuma questão nesta prova ainda.')
                  else
                    ...List.generate(_questoes.length, _cartaoQuestao),
                  const SizedBox(height: 20),
                  if (!_travada) ...[
                    OutlinedButton(
                      onPressed: _ocupado ? null : _salvarRascunho,
                      child: const Text('Salvar rascunho'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _ocupado ? null : _enviarParaCoordenador,
                      child: const Text('Enviar para o coordenador'),
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: _ocupado ? null : () => _gerar('pdf'),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Gerar PDF da prova'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _ocupado ? null : () => _gerar('docx'),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Gerar DOCX (editável no Word)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    final cursos = _cursosOpcoes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: _tituloController,
              enabled: !_travada,
              decoration: const InputDecoration(labelText: 'Avaliação de'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _curso,
              decoration: const InputDecoration(labelText: 'Curso'),
              items: cursos
                  .map((curso) => DropdownMenuItem(
                      value: curso,
                      child: Text(curso, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged:
                  _travada ? null : (valor) => setState(() => _curso = valor!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _periodoController,
                    enabled: !_travada,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Período'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _etapaController,
                    enabled: !_travada,
                    decoration: const InputDecoration(labelText: 'Etapa'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dataController,
                    enabled: !_travada,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Data',
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                    ),
                    onTap: _travada
                        ? null
                        : () async {
                            final selecionada = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2035),
                              initialDate: DateTime.now(),
                            );
                            if (selecionada != null) {
                              _dataController.text =
                                  '${selecionada.day.toString().padLeft(2, '0')}/'
                                  '${selecionada.month.toString().padLeft(2, '0')}/'
                                  '${selecionada.year}';
                            }
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _valorController,
                    enabled: !_travada,
                    decoration:
                        const InputDecoration(labelText: 'Valor da prova'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _professorController,
              enabled: !_travada,
              decoration: const InputDecoration(labelText: 'Professor(a)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instrucoesController,
              enabled: !_travada,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Orientações gerais (uma por linha)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartaoQuestao(int indice) {
    final questao = _questoes[indice];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.accentSoft,
              child: Text('${indice + 1}',
                  style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(questao.texto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5)),
                  const SizedBox(height: 3),
                  Text('${questao.valor.toStringAsFixed(1)} pts',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkMuted)),
                ],
              ),
            ),
            if (!_travada) ...[
              const SizedBox(width: 4),
              _botaoAcao(
                Icons.arrow_upward,
                'Subir',
                indice == 0 ? null : () => _mover(indice, -1),
              ),
              _botaoAcao(
                Icons.arrow_downward,
                'Descer',
                indice == _questoes.length - 1
                    ? null
                    : () => _mover(indice, 1),
              ),
              _botaoAcao(Icons.close, 'Remover', () => _remover(indice)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _botaoAcao(IconData icone, String dica, VoidCallback? aoTocar) {
    return IconButton(
      tooltip: dica,
      icon: Icon(icone, size: 16),
      onPressed: aoTocar,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _avisoTravada() {
    final comentario = widget.prova.comentarioDirecao;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta prova já foi decidida pela Direção '
              '(${widget.prova.status.rotulo.toLowerCase()}) e está somente '
              'para leitura.'
              '${comentario != null ? '\nComentário: $comentario' : ''}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.amber),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avisoStatus(String texto, Color cor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: TextStyle(fontSize: 12.5, color: cor)),
          ),
        ],
      ),
    );
  }
}
