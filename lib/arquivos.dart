import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

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

  /// Abre a folha de compartilhamento do Android (salvar, enviar, etc.).
  static Future<void> compartilhar(
    Uint8List bytes,
    String nome, {
    required String mime,
  }) async {
    if (mime == mimePdf) {
      await Printing.sharePdf(bytes: bytes, filename: nome);
      return;
    }
    final pasta = await getTemporaryDirectory();
    final arquivo = File('${pasta.path}/$nome');
    await arquivo.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(arquivo.path, mimeType: mime)],
      subject: nome,
    );
  }
}
