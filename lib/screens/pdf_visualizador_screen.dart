import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Mostra o PDF dentro do próprio app (sem abrir outro aplicativo), com
/// botões para imprimir e compartilhar/salvar.
class PdfVisualizadorScreen extends StatelessWidget {
  const PdfVisualizadorScreen({
    super.key,
    required this.bytes,
    required this.nome,
  });

  final Uint8List bytes;
  final String nome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          nome,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15),
        ),
      ),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: nome,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
      ),
    );
  }
}
