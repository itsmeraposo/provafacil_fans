import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/common.dart';
import 'montar_prova_screen.dart';
import 'questao_form_screen.dart';

/// TELA · Banco de Questões.
///
/// Lista mestre-detalhe: filtros por período e assunto, busca por
/// palavra-chave, botões de acesso à funcionalidade "Nova questão" (tela de
/// detalhes) e atalho para iniciar a montagem de uma prova.
class BancoQuestoesScreen extends StatefulWidget {
  const BancoQuestoesScreen({super.key});

  @override
  State<BancoQuestoesScreen> createState() => _BancoQuestoesScreenState();
}

class _BancoQuestoesScreenState extends State<BancoQuestoesScreen> {
  String? _filtroPeriodo;
  String? _filtroAssunto;
  final _buscaController = TextEditingController();

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<Questao> _questoesFiltradas() {
    final todas = AppState.instancia.questoes;
    final busca = _buscaController.text.trim().toLowerCase();
    return todas.where((questao) {
      if (_filtroPeriodo != null && questao.periodo != _filtroPeriodo) {
        return false;
      }
      if (_filtroAssunto != null && questao.assunto != _filtroAssunto) {
        return false;
      }
      if (busca.isNotEmpty &&
          !questao.texto.toLowerCase().contains(busca) &&
          !questao.assunto.toLowerCase().contains(busca)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todasQuestoes = AppState.instancia.questoes;
    final assuntos = todasQuestoes.map((q) => q.assunto).toSet().toList()..sort();
    final filtradas = _questoesFiltradas();

    return TelaPrincipal(
      titulo: 'Banco de Questões',
      drawer: const AppDrawer(telaAtual: 'Banco de Questões'),
      corpo: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 19),
                hintText: 'Buscar por palavra-chave ou assunto',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro('Todos os períodos', _filtroPeriodo == null,
                      () => setState(() => _filtroPeriodo = null)),
                  _chipFiltro('Atual', _filtroPeriodo == 'atual',
                      () => setState(() => _filtroPeriodo = 'atual')),
                  _chipFiltro('Histórico', _filtroPeriodo == 'historico',
                      () => setState(() => _filtroPeriodo = 'historico')),
                  const SizedBox(width: 10),
                  Container(width: 1, height: 22, color: AppColors.rule),
                  const SizedBox(width: 10),
                  _chipFiltro('Todos os assuntos', _filtroAssunto == null,
                      () => setState(() => _filtroAssunto = null)),
                  for (final assunto in assuntos)
                    _chipFiltro(assunto, _filtroAssunto == assunto,
                        () => setState(() => _filtroAssunto = assunto)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtradas.isEmpty
                ? const EstadoVazio(
                    texto:
                        'Nenhuma questão encontrada com os filtros atuais.',
                    icone: Icons.search_off,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtradas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, indice) =>
                        _cartaoQuestao(context, filtradas[indice]),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const QuestaoFormScreen()),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nova questão'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: filtradas.isEmpty
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const MontarProvaScreen()),
                            ),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Montar prova com estas questões'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String rotulo, bool selecionado, VoidCallback aoTocar) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(rotulo),
        selected: selecionado,
        onSelected: (_) => aoTocar(),
      ),
    );
  }

  Widget _cartaoQuestao(BuildContext context, Questao questao) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestaoFormScreen(questao: questao),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _selo(questao.assunto, AppColors.accent),
                        _selo(
                          questao.periodo == 'atual' ? 'Atual' : 'Histórico',
                          AppColors.inkMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${questao.valor.toStringAsFixed(1)} pts',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12.5)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                questao.texto,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 6),
              Text('Usada em ${questao.usadaEm} prova(s)',
                  style:
                      const TextStyle(color: AppColors.inkFaint, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selo(String texto, Color cor) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(texto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: cor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
