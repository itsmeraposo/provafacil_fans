import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../mock_data.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../professor/painel_professor_screen.dart';

/// TELA · Revisão e geração da prova — passo 2 de 2.
///
/// Permite reordenar/remover questões, preencher o cabeçalho, salvar como
/// rascunho, enviar para a Direção revisar, ou gerar o arquivo (PDF/DOCX —
/// simulado nesta etapa, sem geração real de arquivo). Provas já aprovadas,
/// reprovadas ou impressas ficam somente leitura, como no protótipo web.
class RevisaoProvaScreen extends StatefulWidget {
  const RevisaoProvaScreen({
    super.key,
    required this.prova,
    this.provaNova = false,
  });

  final Prova prova;

  /// Indica que a prova ainda não foi salva em [AppState.provas].
  final bool provaNova;

  @override
  State<RevisaoProvaScreen> createState() => _RevisaoProvaScreenState();
}

class _RevisaoProvaScreenState extends State<RevisaoProvaScreen> {
  late final TextEditingController _tituloController;
  late final TextEditingController _etapaController;
  late final TextEditingController _dataController;
  late final TextEditingController _valorController;
  late final TextEditingController _professorController;
  late final TextEditingController _instrucoesController;
  late String _curso;
  late List<Questao> _questoes;
  bool _jaSalva = false;

  bool get _travada =>
      widget.prova.status == StatusProva.aprovada ||
      widget.prova.status == StatusProva.reprovada ||
      widget.prova.status == StatusProva.impressa;

  @override
  void initState() {
    super.initState();
    _jaSalva = !widget.provaNova;
    _tituloController = TextEditingController(text: widget.prova.titulo);
    _etapaController = TextEditingController(text: widget.prova.etapa);
    _dataController = TextEditingController(text: widget.prova.data);
    _valorController = TextEditingController(text: widget.prova.valorProva);
    _professorController = TextEditingController(text: widget.prova.professor);
    _instrucoesController = TextEditingController(
      text: 'A avaliação deve ser realizada individualmente;\n'
          'Não é admitida nenhuma forma de consulta a qualquer tipo de material;\n'
          'Celulares devem permanecer desligados durante toda a avaliação.',
    );
    _curso = cursosDisponiveis.contains(widget.prova.curso)
        ? widget.prova.curso
        : cursosDisponiveis.first;
    _questoes = List.of(widget.prova.questoes);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _etapaController.dispose();
    _dataController.dispose();
    _valorController.dispose();
    _professorController.dispose();
    _instrucoesController.dispose();
    super.dispose();
  }

  void _sincronizarProva() {
    widget.prova
      ..titulo = _tituloController.text.trim().isEmpty
          ? 'Avaliação'
          : _tituloController.text.trim()
      ..curso = _curso
      ..etapa = _etapaController.text.trim()
      ..data = _dataController.text.trim()
      ..valorProva = _valorController.text.trim()
      ..professor = _professorController.text.trim()
      ..questoes = _questoes;
  }

  void _garantirSalva() {
    if (!_jaSalva) {
      AppState.instancia.adicionarProva(widget.prova);
      _jaSalva = true;
    }
  }

  void _salvarRascunho() {
    _sincronizarProva();
    _garantirSalva();
    AppState.instancia.atualizarStatusProva(widget.prova.id, StatusProva.rascunho);
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Rascunho salvo.')));
  }

  void _enviarParaCoordenador() {
    if (_questoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos uma questão antes de enviar.')),
      );
      return;
    }
    _sincronizarProva();
    _garantirSalva();
    AppState.instancia
        .atualizarStatusProva(widget.prova.id, StatusProva.emRevisao);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prova enviada para a Direção revisar.')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PainelProfessorScreen()),
      (rota) => false,
    );
  }

  void _gerar(String formato) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Geração de $formato simulada nesta etapa (sem integração de backend).',
        ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passo 2 de 2 · Revisão'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_travada) _avisoTravada(),
            if (widget.prova.status == StatusProva.emRevisao)
              _avisoStatus(
                'Esta prova está em revisão pela Direção.',
                AppColors.amber,
              ),
            const TituloSecao('Cabeçalho da prova'),
            Card(
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
                      items: cursosDisponiveis
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
                            controller: _etapaController,
                            enabled: !_travada,
                            decoration: const InputDecoration(labelText: 'Etapa'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _dataController,
                            enabled: !_travada,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Data',
                              suffixIcon: Icon(Icons.calendar_today_outlined, size: 16),
                            ),
                            onTap: () async {
                              final selecionada = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2030),
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _valorController,
                            enabled: !_travada,
                            decoration:
                                const InputDecoration(labelText: 'Valor da prova'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _professorController,
                            enabled: !_travada,
                            decoration: const InputDecoration(labelText: 'Professor(a)'),
                          ),
                        ),
                      ],
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
            ),
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
              ],
            ),
            if (_questoes.isEmpty)
              const EstadoVazio(texto: 'Nenhuma questão nesta prova ainda.')
            else
              ...List.generate(_questoes.length, (indice) {
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
                                      fontSize: 11,
                                      color: AppColors.inkMuted)),
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
                          _botaoAcao(
                            Icons.close,
                            'Remover',
                            () => _remover(indice),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            if (!_travada) ...[
              OutlinedButton(
                onPressed: _salvarRascunho,
                child: const Text('Salvar rascunho'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _enviarParaCoordenador,
                child: const Text('Enviar para o coordenador'),
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: () => _gerar('PDF'),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Gerar PDF da prova'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _gerar('DOCX'),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Gerar DOCX (editável no Word)'),
            ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Esta prova já foi decidida pela Direção (${widget.prova.status.rotulo.toLowerCase()}) '
              'e está somente para leitura.',
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
