import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api.dart';
import '../config.dart';
import '../notificacoes.dart';
import '../theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/common.dart';

/// TELA · Enviar documento (comum aos três perfis).
///
/// Fluxo da Etapa 3: o usuário escolhe um PDF, PNG ou JPG com o seletor de
/// arquivos do aparelho, confere nome e tamanho, e envia por
/// `POST multipart/form-data` com o token (`Authorization: Bearer`). O servidor
/// lê o documento (texto do PDF ou OCR da imagem) e devolve o texto. Ao receber
/// 200, o app mostra uma notificação local de sucesso.
///
/// O servidor decide quem pode enviar: sem sessão responde 401, e a
/// Repografia recebe 403 (não tem acesso a essas rotas).
class EnviarDocumentoScreen extends StatefulWidget {
  const EnviarDocumentoScreen({super.key});

  @override
  State<EnviarDocumentoScreen> createState() => _EnviarDocumentoScreenState();
}

class _EnviarDocumentoScreenState extends State<EnviarDocumentoScreen> {
  static const List<String> _extensoes = ['pdf', 'png', 'jpg', 'jpeg'];

  PlatformFile? _arquivo;
  String? _erroArquivo; // validação do arquivo (antes de enviar)
  String? _erroEnvio; // resposta de erro da API (401, 403, ...)
  bool _enviando = false;
  double? _progresso; // 0 a 1 enquanto envia
  Map<String, dynamic>? _resultado;

  String _extensao(String nome) {
    final ponto = nome.lastIndexOf('.');
    return ponto < 0 ? '' : nome.substring(ponto + 1).toLowerCase();
  }

  String _mimeDe(String extensao) {
    switch (extensao) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  String _tamanho(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1).replaceAll('.', ',')} KB';
    }
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(2).replaceAll('.', ',');
    return '$mb MB';
  }

  /// Item 08: formato e tamanho do arquivo. Devolve `null` se está tudo certo.
  String? _validar(PlatformFile arquivo) {
    if (!_extensoes.contains(_extensao(arquivo.name))) {
      return 'Formato não aceito. Escolha um arquivo PDF, PNG ou JPG.';
    }
    if (arquivo.size > limiteUploadBytes) {
      return 'O arquivo tem ${_tamanho(arquivo.size)}, e o limite é '
          '${_tamanho(limiteUploadBytes)}. Escolha um arquivo menor.';
    }
    if (arquivo.bytes == null) {
      return 'Não foi possível ler o arquivo. Tente escolher de novo.';
    }
    return null;
  }

  /// Item 06: seletor de arquivos do aparelho (PDF, PNG ou JPG).
  Future<void> _selecionar() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _extensoes,
        withData: true,
      );
      if (resultado == null || resultado.files.isEmpty) return; // cancelou
      final arquivo = resultado.files.single;
      if (!mounted) return;
      setState(() {
        _arquivo = arquivo;
        _erroArquivo = _validar(arquivo);
        _erroEnvio = null;
        _resultado = null;
        _progresso = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _erroArquivo = 'Não foi possível abrir o seletor de '
          'arquivos.');
    }
  }

  void _remover() {
    setState(() {
      _arquivo = null;
      _erroArquivo = null;
      _erroEnvio = null;
      _resultado = null;
      _progresso = null;
    });
  }

  /// Itens 09 a 12: envia o arquivo, mostra o progresso e, ao receber 200,
  /// avisa com uma notificação local.
  Future<void> _enviar() async {
    if (_enviando) return;

    final arquivo = _arquivo;
    if (arquivo == null) {
      setState(() => _erroArquivo = 'Selecione um arquivo antes de enviar.');
      return;
    }
    final erro = _validar(arquivo);
    if (erro != null) {
      setState(() => _erroArquivo = erro);
      return;
    }

    // O pedido de permissão precisa nascer deste toque (o navegador só aceita
    // assim). A resposta é esperada só depois do envio.
    final permissao = Notificacoes.pedirPermissao();

    setState(() {
      _enviando = true;
      _progresso = 0;
      _erroArquivo = null;
      _erroEnvio = null;
      _resultado = null;
    });

    final extensao = _extensao(arquivo.name);
    final caminho = extensao == 'pdf'
        ? '/api/questoes/extrair-pdf'
        : '/api/questoes/extrair-imagem';

    try {
      final resposta = await ApiClient.instancia.enviarArquivo(
        caminho,
        campo: 'arquivo',
        bytes: arquivo.bytes!,
        nomeArquivo: arquivo.name,
        mime: _mimeDe(extensao),
        aoProgredir: (enviados, total) {
          if (!mounted || total <= 0) return;
          setState(() => _progresso = enviados / total);
        },
      );
      await permissao;
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _progresso = 1;
        _resultado = resposta;
      });
      mostrarMensagem(context, 'Documento enviado com sucesso.');
      await Notificacoes.mostrar(
        'Documento enviado',
        '"${arquivo.name}" foi enviado com sucesso.',
      );
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _progresso = null;
        _erroEnvio = _mensagemDoErro(erro);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _progresso = null;
        _erroEnvio = 'Algo deu errado ao enviar o documento. Tente de novo.';
      });
    }
  }

  /// Item 11: cada código da API vira uma mensagem clara para o usuário.
  String _mensagemDoErro(ApiException erro) {
    switch (erro.status) {
      case 401:
        return 'Sessão inválida ou expirada (401). Entre novamente.';
      case 403:
        return 'Seu perfil não tem permissão para enviar documentos (403). '
            '${erro.mensagem}';
      default:
        return erro.mensagem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TelaPrincipal(
      titulo: 'Enviar documento',
      drawer: const AppDrawer(telaAtual: 'Enviar documento'),
      corpo: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Escolha um PDF, PNG ou JPG de até 4 MB. O servidor lê o '
                'documento e devolve o texto encontrado.',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _enviando ? null : _selecionar,
                icon: const Icon(Icons.attach_file),
                label: const Text('Selecionar arquivo'),
              ),
              const SizedBox(height: 14),
              if (_arquivo != null) _cartaoArquivo(_arquivo!),
              if (_erroArquivo != null) BannerErro(texto: _erroArquivo!),
              if (_enviando) _blocoProgresso(),
              if (_erroEnvio != null) BannerErro(texto: _erroEnvio!),
              FilledButton.icon(
                onPressed: _enviando ? null : _enviar,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Enviar documento'),
              ),
              if (_resultado != null) ...[
                const SizedBox(height: 18),
                _cartaoResultado(_resultado!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Item 07: nome e tamanho do arquivo escolhido, antes do envio.
  Widget _cartaoArquivo(PlatformFile arquivo) {
    final extensao = _extensao(arquivo.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rule),
      ),
      child: Row(
        children: [
          Icon(
            extensao == 'pdf'
                ? Icons.picture_as_pdf_outlined
                : Icons.image_outlined,
            color: AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arquivo.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tamanho: ${_tamanho(arquivo.size)}'
                  '  ·  Formato: ${extensao.toUpperCase()}',
                  style: const TextStyle(
                      color: AppColors.inkMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover arquivo',
            icon: const Icon(Icons.close),
            onPressed: _enviando ? null : _remover,
          ),
        ],
      ),
    );
  }

  /// Item 10: indicador visual do progresso do envio.
  Widget _blocoProgresso() {
    final valor = _progresso;
    final enviando = valor != null && valor < 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: enviando ? valor : null),
          const SizedBox(height: 6),
          Text(
            enviando
                ? 'Enviando... ${((valor ?? 0) * 100).round()}%'
                : 'Enviado. Aguardando o servidor ler o documento...',
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  /// Resposta 200: texto lido pelo servidor.
  Widget _cartaoResultado(Map<String, dynamic> resultado) {
    final texto = (resultado['texto'] ?? '').toString().trim();
    final paginas = resultado['paginas'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mossSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.moss.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 18, color: AppColors.moss),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Documento enviado com sucesso'
                  '${paginas != null ? ' ($paginas página(s))' : ''}',
                  style: const TextStyle(
                      color: AppColors.moss, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.rule),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                texto.isEmpty ? '(Nenhum texto encontrado no documento.)' : texto,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          if (texto.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: texto));
                  mostrarMensagem(context, 'Texto copiado.');
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar texto'),
              ),
            ),
        ],
      ),
    );
  }
}
