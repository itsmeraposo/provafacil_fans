import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Android / iOS / desktop: grava num arquivo temporário e abre a folha de
/// compartilhamento do sistema (salvar, enviar, etc.).
Future<void> salvarOuCompartilhar(
  Uint8List bytes,
  String nome,
  String mime,
) async {
  final pasta = await getTemporaryDirectory();
  final arquivo = File('${pasta.path}/$nome');
  await arquivo.writeAsBytes(bytes, flush: true);
  await Share.shareXFiles(
    [XFile(arquivo.path, mimeType: mime)],
    subject: nome,
  );
}
