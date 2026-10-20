import 'dart:typed_data';

import 'package:printing/printing.dart';

// No Android usa a folha de compartilhamento; no navegador baixa o arquivo.
import 'arquivos_salvar_io.dart'
    if (dart.library.js_interop) 'arquivos_salvar_web.dart';

const String mimePdf = 'application/pdf';
const String mimeDocx =
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

/// Abrir, imprimir e compartilhar os arquivos gerados pelo servidor.
class Arquivos {
  /// Nome seguro de arquivo a partir do título da prova.
  static String nome(String titulo, String extensao) {
    final limpo = titulo
        .replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return '${limpo.isEmpty ? 'prova' : limpo}.$extensao';
  }

  /// Mostra o PDF na tela com as opções de imprimir e salvar do sistema.
  static Future<void> visualizarPdf(Uint8List bytes, String nome) async {
    await Printing.layoutPdf(name: nome, onLayout: (_) async => bytes);
  }

  /// Android: folha de compartilhamento (salvar, enviar, etc.). Navegador:
  /// baixa o arquivo.
  static Future<void> compartilhar(
    Uint8List bytes,
    String nome, {
    required String mime,
  }) async {
    if (mime == mimePdf) {
      await Printing.sharePdf(bytes: bytes, filename: nome);
      return;
    }
    await salvarOuCompartilhar(bytes, nome, mime);
  }
}
