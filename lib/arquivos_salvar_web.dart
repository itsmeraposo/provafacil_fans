import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Navegador: não existe "pasta temporária" nem folha de compartilhamento
/// de arquivos, então baixa o arquivo pelo próprio navegador.
Future<void> salvarOuCompartilhar(
  Uint8List bytes,
  String nome,
  String mime,
) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: mime),
  );
  final endereco = web.URL.createObjectURL(blob);
  final link = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = endereco
    ..download = nome;
  link.click();
  web.URL.revokeObjectURL(endereco);
}
