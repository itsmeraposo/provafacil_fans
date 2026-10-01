import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Scaffold padrão das telas principais: AppBar + Drawer + corpo com
/// rolagem, garantindo consistência visual entre as telas do app.
class TelaPrincipal extends StatelessWidget {
  const TelaPrincipal({
    super.key,
    required this.titulo,
    required this.corpo,
    required this.drawer,
    this.acoes,
    this.botaoFlutuante,
  });

  final String titulo;
  final Widget corpo;
  final Widget drawer;
  final List<Widget>? acoes;
  final Widget? botaoFlutuante;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo), actions: acoes),
      drawer: drawer,
      floatingActionButton: botaoFlutuante,
      body: SafeArea(child: corpo),
    );
  }
}

/// Cartão de indicador numérico usado nos painéis (ex.: "Provas no
/// semestre", "Total de questões").
class CartaoIndicador extends StatelessWidget {
  const CartaoIndicador({
    super.key,
    required this.rotulo,
    required this.valor,
    this.icone,
  });

  final String rotulo;
  final String valor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icone != null) ...[
                Icon(icone, size: 16, color: AppColors.inkMuted),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  rotulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.inkMuted,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de seção com um contador opcional ao lado (ex.: "Questões (6)").
class TituloSecao extends StatelessWidget {
  const TituloSecao(this.texto, {super.key, this.contador});

  final String texto;
  final int? contador;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Flexible(
            child: Text(
              texto,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          if (contador != null) ...[
            const SizedBox(width: 6),
            Text(
              '($contador)',
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

/// Selo colorido de status de prova (rascunho, em revisão, aprovada...).
class SeloStatus extends StatelessWidget {
  const SeloStatus(this.status, {super.key});

  final StatusProva status;

  Color get _cor {
    switch (status) {
      case StatusProva.rascunho:
        return AppColors.inkMuted;
      case StatusProva.emRevisao:
        return AppColors.amber;
      case StatusProva.aprovada:
        return AppColors.moss;
      case StatusProva.reprovada:
        return AppColors.claret;
      case StatusProva.impressa:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _cor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.rotulo,
        style: TextStyle(
          color: cor,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Estado vazio padrão (evita telas "em branco" sem explicação nas listas).
class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.texto, this.icone});

  final String texto;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icone ?? Icons.inbox_outlined,
              size: 34, color: AppColors.inkFaint),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Grade de indicadores: 2 por linha, com altura que se ajusta ao conteúdo
/// (evita o texto "vazar" por cima de outros cartões).
class GradeIndicadores extends StatelessWidget {
  const GradeIndicadores({super.key, required this.itens});

  final List<CartaoIndicador> itens;

  @override
  Widget build(BuildContext context) {
    final linhas = <Widget>[];
    for (var i = 0; i < itens.length; i += 2) {
      if (linhas.isNotEmpty) linhas.add(const SizedBox(height: 10));
      linhas.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: itens[i]),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < itens.length
                    ? itens[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: linhas);
  }
}

/// Linha de prova (título, detalhe e selo de status) usada nos painéis.
/// O texto ocupa o espaço disponível e o selo nunca se sobrepõe a ele.
class LinhaProva extends StatelessWidget {
  const LinhaProva({
    super.key,
    required this.titulo,
    required this.detalhe,
    required this.status,
    required this.aoTocar,
  });

  final String titulo;
  final String detalhe;
  final StatusProva status;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detalhe,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SeloStatus(status),
            ],
          ),
        ),
      ),
    );
  }
}
