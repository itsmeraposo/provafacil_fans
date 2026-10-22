import 'package:flutter/material.dart';

import '../../api.dart';
import '../../app_state.dart';
import '../../arquivos.dart';
import '../../models.dart';
import '../../preferencias.dart';
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
  final _formKey = GlobalKey<FormState>();
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
    // Prova do servidor com alterações guardadas no aparelho (feitas sem
    // conexão): mostra a versão editada.
    final prova = (widget.provaNova
            ? null
            : AppState.instancia.abrirEdicaoLocal(widget.prova.id)) ??
        widget.prova;
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
    AppState.instancia.revisaoAberta();
    // Prova nova: já guarda no aparelho desde a primeira tela de revisão.
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardarLocal());
  }

  @override
  void dispose() {
    AppState.instancia.revisaoFechada();
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

  /// Prova nova que ainda não foi para o servidor: guarda o que está na tela
  /// no aparelho, para o professor continuar depois de fechar o app.
  void _guardarLocal() {
    final usuario = AppState.instancia.usuarioAtual;
    if (usuario == null || !widget.provaNova || _travada) return;
    if (_provaId.isNotEmpty) return;
    Preferencias.salvarRascunhoLocal(usuario.id, _provaAtual());
  }

  /// Sem conexão, numa prova que ainda pode ser editada (nova ou rascunho do
  /// servidor): dá para guardar o pedido no aparelho.
  bool _semConexaoGuardavel(Object erro) =>
      erro is ApiException && erro.status == null && !_travada;

  /// Guarda a prova e o que o professor pediu (enviar, PDF ou DOCX) no
  /// aparelho e volta ao painel. Com a tela fechada, o app faz o pedido
  /// sozinho quando a internet voltar.
  Future<void> _guardarParaDepois(String acao, String mensagem) async {
    final usuario = AppState.instancia.usuarioAtual;
    if (_provaId.isEmpty) {
      // Prova nova: um rascunho local por usuário.
      if (usuario != null) {
        await Preferencias.salvarRascunhoLocal(usuario.id, _provaAtual());
        await Preferencias.salvarAcaoPendente(usuario.id, acao);
      }
    } else {
      // Prova que já está no servidor: guarda a edição ligada ao id dela.
      await AppState.instancia.guardarEdicaoLocal(_provaAtual(), acao);
    }
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PainelProfessorScreen()),
      (rota) => false,
    );
    mostrarMensagem(context, mensagem);
  }

  /// A prova já está no servidor: a cópia local não é mais necessária.
  void _limparLocal() {
    final usuario = AppState.instancia.usuarioAtual;
    if (usuario == null) return;
    if (widget.provaNova) Preferencias.apagarRascunhoLocal(usuario.id);
    if (_provaId.isNotEmpty) AppState.instancia.descartarEdicaoLocal(_provaId);
  }

  /// Confere as questões e os campos do cabeçalho antes de salvar, enviar ou
  /// gerar o arquivo. Provas somente para leitura não são validadas.
  bool _podeContinuar() {
    if (!_temQuestoes()) return false;
    if (_travada) return true;
    if (_formKey.currentState?.validate() ?? true) return true;
    mostrarMensagem(context, 'Corrija os campos destacados no cabeçalho.');
    return false;
  }

  String? _obrigatorio(String? valor) =>
      (valor == null || valor.trim().isEmpty) ? 'Obrigatório' : null;

  String? _validarPeriodo(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return 'Obrigatório';
    final numero = int.tryParse(texto);
    if (numero == null) return 'Digite um número';
    if (numero < 1 || numero > 10) return 'Entre 1 e 10';
    return null;
  }

  String? _validarValor(String? valor) {
    final texto = (valor ?? '').trim().replaceAll(',', '.');
    if (texto.isEmpty) return 'Obrigatório';
    final numero = double.tryParse(texto);
    if (numero == null) return 'Digite um número';
    if (numero <= 0 || numero > 100) return 'Entre 0,1 e 100';
    return null;
  }

  Future<void> _salvarRascunho() async {
    if (_ocupado || !_podeContinuar()) return;
    setState(() => _ocupado = true);
    try {
      final salva = await AppState.instancia.salvarRascunho(_provaAtual());
      _provaId = salva.id;
      _limparLocal();
      if (mounted) mostrarMensagem(context, 'Rascunho salvo.');
    } catch (erro) {
      if (!mounted) return;
      // Sem conexão (status nulo): a prova ou as alterações ficam no
      // aparelho e pode ser retomado e enviado depois.
      if (_semConexaoGuardavel(erro)) {
        // Sai da tela: com ela fechada, o app envia sozinho quando a
        // internet voltar.
        await _guardarParaDepois(
          'rascunho',
          'Sem conexão: alterações salvas neste aparelho. Serão enviadas '
          'automaticamente quando a internet voltar.',
        );
      } else {
        mostrarMensagem(context, textoDoErro(erro));
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _enviarParaCoordenador() async {
    if (_ocupado || !_podeContinuar()) return;
    setState(() => _ocupado = true);
    try {
      await AppState.instancia.enviarParaCoordenador(_provaAtual());
      _limparLocal();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PainelProfessorScreen()),
        (rota) => false,
      );
      mostrarMensagem(context, 'Prova enviada para a Direção revisar.');
    } catch (erro) {
      if (!mounted) return;
      if (_semConexaoGuardavel(erro)) {
        await _guardarParaDepois(
          'enviar',
          'Sem conexão: prova guardada neste aparelho. Será enviada ao '
          'coordenador automaticamente quando a internet voltar.',
        );
        return;
      }
      setState(() => _ocupado = false);
      mostrarMensagem(context, textoDoErro(erro));
    }
  }

  Future<void> _gerar(String formato) async {
    if (_ocupado || !_podeContinuar()) return;
    setState(() => _ocupado = true);
    try {
      // Prova nova: salva antes como rascunho, para o servidor não criar
      // outro registro a cada arquivo gerado.
      if (_provaId.isEmpty && !_travada) {
        final salva = await AppState.instancia.salvarRascunho(_provaAtual());
        _provaId = salva.id;
        _limparLocal();
      }
      final prova = _provaAtual();
      final bytes = await AppState.instancia.gerarArquivo(prova, formato);
      _limparLocal();
      final nome = Arquivos.nome(prova.titulo, formato);
      if (formato == 'pdf') {
        if (!mounted) return;
        await Arquivos.abrirPdfNoApp(context, bytes, nome);
      } else {
        await Arquivos.compartilhar(bytes, nome, mime: mimeDocx);
      }
    } catch (erro) {
      if (!mounted) return;
      if (_semConexaoGuardavel(erro)) {
        await _guardarParaDepois(
          formato,
          'Sem conexão: prova guardada neste aparelho. O '
          '${formato.toUpperCase()} será gerado automaticamente quando a '
          'internet voltar, e você será avisado para abrir.',
        );
      } else {
        mostrarMensagem(context, textoDoErro(erro));
      }
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
    _guardarLocal();
  }

  void _remover(int indice) {
    setState(() => _questoes.removeAt(indice));
    _guardarLocal();
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
                  _avisoFila(),
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
        child: Form(
          key: _formKey,
          onChanged: _guardarLocal,
          child: Column(
          children: [
            TextFormField(
              controller: _tituloController,
              enabled: !_travada,
              validator: _obrigatorio,
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
                  child: TextFormField(
                    controller: _periodoController,
                    enabled: !_travada,
                    validator: _validarPeriodo,
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
                  child: TextFormField(
                    controller: _dataController,
                    enabled: !_travada,
                    readOnly: true,
                    validator: (valor) =>
                        _obrigatorio(valor) == null ? null : 'Escolha a data',
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
                              locale: const Locale('pt', 'BR'),
                              helpText: 'Selecione a data',
                              cancelText: 'Cancelar',
                              confirmText: 'OK',
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
                  child: TextFormField(
                    controller: _valorController,
                    enabled: !_travada,
                    validator: _validarValor,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Valor da prova'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _professorController,
              enabled: !_travada,
              validator: _obrigatorio,
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

  /// Pedido feito sem conexão (enviar, PDF, DOCX) que ainda não foi cumprido.
  /// Continua valendo mesmo se o professor reabrir a prova; aqui ele pode
  /// cancelar.
  Widget _avisoFila() {
    return ValueListenableBuilder<String?>(
      valueListenable: Preferencias.acaoRascunhoLocal,
      builder: (context, acaoNova, _) {
        final acao = _provaId.isEmpty
            ? (widget.provaNova ? acaoNova : null)
            : AppState.instancia.acoesEdicoes[_provaId];
        final texto = switch (acao) {
          'enviar' => 'será enviada ao coordenador',
          'pdf' => 'o PDF será gerado',
          'docx' => 'o DOCX será gerado',
          _ => null,
        };
        if (texto == null || _travada) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            color: AppColors.claret.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.claret.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 18, color: AppColors.claret),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pedido guardado neste aparelho: $texto quando a internet '
                  'voltar.',
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.claret),
                ),
              ),
              TextButton(
                onPressed: _cancelarFila,
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelarFila() async {
    final usuario = AppState.instancia.usuarioAtual;
    if (_provaId.isEmpty) {
      if (usuario != null) await Preferencias.apagarAcaoPendente(usuario.id);
    } else {
      await AppState.instancia.guardarEdicaoLocal(_provaAtual(), 'rascunho');
    }
    if (mounted) {
      setState(() {});
      mostrarMensagem(context, 'Pedido cancelado. A prova continua guardada.');
    }
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
