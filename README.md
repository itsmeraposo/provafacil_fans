# ProvaFácil FANS — App Flutter (etapa de navegação)

Este projeto implementa, em Flutter, as telas, os menus e os fluxos de
navegação definidos nas etapas anteriores do projeto ProvaFácil FANS,
conforme pedido no enunciado da atividade.

## Sobre os perfis de acesso

O enunciado da atividade usa os nomes genéricos **"Cliente"** e **"Usuário"**
para os perfis de acesso. Este projeto, porém, tem **três perfis reais**,
definidos nas etapas anteriores do sistema:

| Perfil do enunciado | Perfil real do ProvaFácil FANS |
|---|---|
| — | **Professor** — cria questões e monta provas |
| — | **Direção** — revisa e aprova/reprova as provas |
| — | **Repografia** — imprime as provas aprovadas |

Optamos por manter os três perfis reais (em vez de forçá-los em apenas dois
grupos "Cliente/Usuário"), pois é o que reflete fielmente o projeto e o
planejamento das etapas anteriores.

## O que está implementado nesta etapa

- Todas as telas previstas: boas-vindas, login, cadastro, recuperar senha, painéis, banco de questões, cadastro/edição
  de questão, montagem de prova (2 passos), revisão da Direção, impressão da
  Repografia e perfil.
- Navegação funcional entre todas as telas (`Navigator`), com botão de voltar
  operante em todas elas.
- Menu lateral (Drawer) com itens específicos para cada perfil, incluindo
  "Sair".
- Fluxos completos dos três perfis, do login até a ação final de cada um.
- Transições reais: botões executam ações, más ações atualizam status,
  telas se abrem/fecham corretamente e não há telas "sem saída".
- Interface visual consistente (mesma paleta de cores e componentes do
  protótipo web) entre todas as telas.

Como o enunciado permite, **não há integração real de backend/banco de
dados** nesta etapa — os dados (usuários, questões e provas) são simulados em
memória (`lib/mock_data.dart` e `lib/app_state.dart`), o suficiente para
demonstrar toda a navegação e os fluxos funcionando de ponta a ponta.

## Como executar

```bash
flutter pub get
flutter run
```

## Login de demonstração

Na tela de login, escolha o perfil desejado em "Entrar como" (Professor,
Direção ou Repografia) e toque em "Entrar" — e-mail/senha já vêm preenchidos
apenas para agilizar a demonstração.

## Estrutura do projeto

```
lib/
  main.dart                 Ponto de entrada
  theme.dart                 Paleta e tema visual
  models.dart                 Modelos (Usuario, Questao, Prova, Perfil)
  mock_data.dart               Dados simulados
  app_state.dart                 Sessão e dados compartilhados entre telas
  widgets/
    app_drawer.dart               Menu lateral (por perfil)
    common.dart                     Componentes reutilizados
  screens/
    boas_vindas_screen.dart           Tela inicial (leva ao login)
    login_screen.dart                 Login
    cadastro_screen.dart              Criar conta (simulado)
    recuperar_senha_screen.dart       Recuperar senha (simulado)
    perfil_screen.dart                 Perfil (comum aos 3 perfis)
    professor/
      painel_professor_screen.dart
      banco_questoes_screen.dart
      questao_form_screen.dart
      montar_prova_screen.dart          (passo 1/2)
      revisao_prova_screen.dart          (passo 2/2)
    direcao/
      painel_direcao_screen.dart
      revisao_direcao_screen.dart
    repografia/
      painel_repografia_screen.dart
      detalhe_impressao_screen.dart
```
