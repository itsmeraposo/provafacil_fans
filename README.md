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

## Integração com o servidor

O app conversa com a API do ProvaFácil (Node/Express + Firestore) pelo
endereço definido em `lib/config.dart` (`apiBaseUrl`). O login usa o cookie de
sessão do servidor (`provafacil_sessao`), guardado em memória por
`lib/api.dart`.

| Tela / botão | Endpoint |
| --- | --- |
| Entrar | `POST /api/auth/login` |
| Cadastre-se | `POST /api/auth/registrar` (+ `GET /api/constantes`) |
| Esqueci minha senha | `POST /api/auth/esqueci-senha` |
| Reenviar confirmação | `POST /api/auth/reenviar-verificacao` |
| Sair | `POST /api/auth/logout` |
| Perfil: salvar / alterar senha / excluir conta | `PUT /api/auth/perfil`, `POST /api/auth/alterar-senha`, `DELETE /api/auth/conta` |
| Painéis e Banco de Questões | `GET /api/questoes`, `GET /api/provas` |
| Nova questão / editar / excluir | `POST`, `PUT`, `DELETE /api/questoes[/:id]` |
| Salvar rascunho / Enviar para o coordenador | `POST /api/provas/rascunho`, `POST /api/provas/enviar` |
| Gerar PDF / DOCX | `POST /api/provas/gerar-pdf`, `gerar-docx` |
| Excluir rascunho | `DELETE /api/provas/:id` |
| Direção: ver PDF / aprovar / reprovar / em análise | `GET /api/provas/:id/previa-pdf`, `PATCH /api/provas/:id/revisao` |
| Repografia: abrir PDF / marcar e desfazer impressão | `GET /api/provas/:id/previa-pdf`, `PATCH /api/provas/:id/impressao` |

No Android, o `AndroidManifest.xml` precisa da permissão de internet e, para
servidor `http://` (desenvolvimento), de tráfego sem criptografia:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<application ... android:usesCleartextTraffic="true">
```

## Como executar

```bash
flutter pub get
flutter run
```

## Modo sem login (temporário)

A pedido do professor, o login está **desligado** nesta etapa:
`loginAtivo = false` em `lib/config.dart`. A tela de login vira "Acesso
direto" (só escolher o perfil) e o app pede a sessão ao servidor em
`POST /api/auth/entrada-direta`, usando a chave `semLoginChave`. Todo o resto
(questões, provas, PDF/DOCX) funciona com dados reais. O servidor precisa ter
`SEM_LOGIN=true` e `SEM_LOGIN_CHAVE` igual a `semLoginChave`. Para religar o
login: `loginAtivo = true` no app e apagar `SEM_LOGIN` no servidor.

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
  config.dart / api.dart / arquivos.dart / validators.dart   Servidor e utilitários
  app_state.dart                 Sessão e dados compartilhados entre telas
  widgets/
    app_drawer.dart               Menu lateral (por perfil)
    common.dart                     Componentes reutilizados
  screens/
    boas_vindas_screen.dart           Tela inicial (leva ao login)
    login_screen.dart                 Login
    cadastro_screen.dart              Criar conta
    recuperar_senha_screen.dart       Recuperar senha
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
