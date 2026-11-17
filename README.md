# ProvaFácil FANS — App Flutter (Etapa 2)

Aplicativo em **Flutter/Dart** para montar, revisar e imprimir provas da
Faculdade de Nova Serrana. Funciona no **Android** e no **navegador (web)** e
conversa por **HTTP** com uma API Node/Express que grava em um banco real
(**Cloud Firestore**).

- **Servidor publicado:** https://prova-facil-fans.vercel.app
- **Repositório do servidor:** https://github.com/joaopcordeirons/ProvaFacilFANS

## Perfis de acesso

| Perfil | O que faz |
| --- | --- |
| **Professor** | Cria questões e monta provas |
| **Direção** | Revisa e aprova/reprova as provas |
| **Repografia** | Imprime as provas aprovadas |

## Como entrar

O login está **ligado**: o app pede **e-mail**, **senha** e o **perfil** e chama
`POST /api/auth/login`, que devolve um token (JWT).

**Contas de teste:**

| Perfil | E-mail | Senha |
| --- | --- | --- |
| Professor | `testelogin@uorak.com` | `Senha@2026` |
| Direção | `testedirecao@uorak.com` | `Senha@2026` |
| Repografia | `testerepo@uorak.com` | `Senha@2026` |

Também é possível criar uma conta pela opção de cadastro (senha com no mínimo
10 caracteres, com maiúscula, minúscula, número e caractere especial). Os
perfis **Direção** e **Repografia** exigem um código de convite fornecido pela
instituição.

Modo sem login (opcional, só para desenvolvimento): com `loginAtivo = false` em
`lib/config.dart`, o app chama `POST /api/auth/entrada-direta` com uma chave de
teste (`semLoginChave`). O servidor só aceita essa rota com `SEM_LOGIN=true` e a
mesma chave em `SEM_LOGIN_CHAVE`.

## Etapa 3 — Entrega de documentos

Nesta etapa o app ganhou login com token guardado de forma segura e a tela
**Enviar documento** (menu lateral, nos três perfis): o usuário escolhe um PDF,
PNG ou JPG, confere nome e tamanho e envia para o servidor por
`POST multipart/form-data`. O servidor lê o documento (texto do PDF ou OCR da
imagem) e devolve o texto, que aparece na tela. Ao receber a resposta 200, o
app mostra uma notificação local.

Fluxo: login → token guardado → **Enviar documento** → selecionar arquivo →
conferir nome e tamanho → enviar (com barra de progresso) → notificação.

| Nº | Requisito | Onde está |
| --- | --- | --- |
| 01 | Tela de login | `lib/screens/login_screen.dart` (campos E-mail, Senha e perfil) |
| 02 | Autenticação por token | `lib/app_state.dart` L300 (`entrar`, chama `POST /api/auth/login`); o token vem no corpo da resposta e é lido em `lib/api.dart` |
| 03 | Armazenamento do token | `lib/armazenamento_token.dart` (`flutter_secure_storage`: Keystore no Android, WebCrypto no navegador); gravado em `lib/api.dart` L100, restaurado em L71 e apagado em L63 |
| 04 | Requisições autenticadas | `lib/api.dart` (`Authorization: Bearer <token>` em toda requisição e no upload, L234) |
| 05 | Controle de acesso | Menu por perfil em `lib/widgets/app_drawer.dart`; o servidor responde 401 sem sessão e 403 para a Repografia em `/api/questoes`; ao abrir o app, a sessão guardada é conferida em `GET /api/auth/me` (`lib/app_state.dart` L319, `lib/main.dart` L118) |
| 06 | Seleção de arquivos | `lib/screens/enviar_documento_screen.dart` L82 (`file_picker`, só PDF, PNG e JPG) |
| 07 | Informações do arquivo | `lib/screens/enviar_documento_screen.dart` L245 (nome, tamanho e formato antes do envio) |
| 08 | Validação | `lib/screens/enviar_documento_screen.dart` L65 (sem arquivo, formato inválido ou acima de 4 MB, que é `limiteUploadBytes` em `lib/config.dart`) |
| 09 | Upload para a API | `lib/api.dart` L208 (`enviarArquivo`, `POST multipart/form-data` com Dio) para `/api/questoes/extrair-pdf` ou `/api/questoes/extrair-imagem` |
| 10 | Progresso do upload | `lib/api.dart` L230 (`onSendProgress`) e `lib/screens/enviar_documento_screen.dart` L294 (barra com porcentagem) |
| 11 | Respostas 200, 401 e 403 | `lib/api.dart` L158 (`_erroDeDados`) e `lib/screens/enviar_documento_screen.dart` L189: 200 mostra o texto lido, 401 leva ao login, 403 mostra "sem permissão" |
| 12 | Notificação local | `lib/notificacoes.dart` (+ `notificacoes_io.dart` com `flutter_local_notifications` no Android e `notificacoes_web.dart` no navegador), chamada em `lib/screens/enviar_documento_screen.dart` L167 depois do 200 |
| 13 | Logout | `lib/app_state.dart` L441 (`sair`: chama `POST /api/auth/logout`, limpa a sessão e apaga o token do armazenamento seguro) |

Observações:

- O endpoint de upload já existia no servidor (`ProvaFacilFANS`): as rotas de
  extração de PDF e de imagem recebem o arquivo no campo `arquivo` e exigem o
  token. O arquivo é processado em memória e não fica guardado.
- O limite de 4 MB existe porque a Vercel limita o corpo das requisições a
  cerca de 4,5 MB.
- O 401 só aparece quando a sessão expira (o token vale 12 horas), então é
  tratado no código, mas difícil de provocar numa demonstração. O 403 é fácil:
  entre com a conta de Repografia e tente enviar um documento.
- Notificações: no Android 13 ou mais novo o app pede permissão na primeira
  vez; no navegador, o navegador pede para permitir notificações. Se a
  permissão for negada, o app só mostra o aviso na tela.
- No navegador, o armazenamento seguro exige HTTPS (ou `localhost`).

## Requisitos da prova × onde estão no app

| Requisito | Como foi atendido |
| --- | --- |
| Multiplataforma (Android e web) | Mesmo código roda nas duas; a sessão usa `Authorization: Bearer` (funciona no navegador) e o download de DOCX tem caminho próprio para web (`lib/arquivos_salvar_web.dart`) |
| Flutter e Dart | Todo o app em Dart |
| Comunicação HTTP | `lib/api.dart` (pacote `http`) fala com a API REST |
| Acesso a banco de dados | API Node/Express + **Cloud Firestore** (nada de dados fixos no código) |
| Persistência | Questões, provas e usuários ficam no Firestore; continuam lá depois de fechar e abrir o app. Também há persistência **local** com `SharedPreferences` (`lib/preferencias.dart`): a opção "Texto grande" (menu lateral) uma **cópia da última lista de questões**, usada quando o servidor ou a internet falham (aparece um aviso de "sem conexão"), o **uso sem conexão**, sempre sinalizado por uma faixa vermelha "SEM CONEXÃO COM O SERVIDOR" no topo de todas as telas (se a internet cair com o app aberto, ele continua com os dados guardados no aparelho; no modo sem login, o perfil que já entrou antes abre o painel mesmo sem internet) e o **cadastro de questão sem conexão**: a questão é guardada no aparelho (marcada como "Pendente de envio") e enviada ao servidor automaticamente quando a conexão volta |
| Consulta | Banco de questões e painéis listam dados com `GET /api/questoes` e `GET /api/provas` |
| Cadastro | Nova questão (`POST /api/questoes`), cadastro de conta e montagem/envio de provas |
| Atualização da interface | Depois de cadastrar, editar, excluir ou revisar, as telas recarregam os dados do servidor |
| Validação dos campos | Formulários de questão, cadastro, perfil e login impedem o envio de dados inválidos (`lib/validators.dart`) |
| Tratamento de erros | Falha de conexão, tempo esgotado e erros da API viram mensagens na tela (`ApiException` em `lib/api.dart`) |

## Como executar

Requisitos: Flutter instalado (`flutter doctor` sem erros).

```bash
flutter pub get

# Android (emulador ou celular)
flutter run

# Navegador
flutter run -d chrome
```

Se a pasta `web/` não existir no seu clone, crie com
`flutter create . --platforms=web`.

APK de release:

```bash
flutter build apk --release
# saída: build/app/outputs/flutter-apk/app-release.apk
```

### Endereço do servidor

Definido em `lib/config.dart` (`apiBaseUrl`), já apontando para o servidor
publicado, então não é preciso subir nenhum servidor local. Para usar um
servidor local, veja as opções comentadas no próprio arquivo.

No Android, o `AndroidManifest.xml` precisa das permissões de internet e de
notificações (Android 13+):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

O `android/app/build.gradle.kts` já tem o *core library desugaring* ligado,
exigido pelo `flutter_local_notifications`.

## Integração com a API

| Tela / botão | Endpoint |
| --- | --- |
| Entrar (login) | `POST /api/auth/login` |
| Entrar (acesso direto, só com `loginAtivo = false`) | `POST /api/auth/entrada-direta` |
| Cadastre-se | `POST /api/auth/registrar` (+ `GET /api/constantes`) |
| Esqueci minha senha | `POST /api/auth/esqueci-senha` |
| Sair | `POST /api/auth/logout` |
| Perfil: salvar / alterar senha / excluir conta | `PUT /api/auth/perfil`, `POST /api/auth/alterar-senha`, `DELETE /api/auth/conta` |
| Painéis e Banco de Questões | `GET /api/questoes`, `GET /api/provas` |
| Nova questão / editar / excluir | `POST`, `PUT`, `DELETE /api/questoes[/:id]` |
| Salvar rascunho / Enviar para o coordenador | `POST /api/provas/rascunho`, `POST /api/provas/enviar` |
| Gerar PDF / DOCX | `POST /api/provas/gerar-pdf`, `gerar-docx` |
| Enviar documento (PDF / imagem) | `POST /api/questoes/extrair-pdf`, `POST /api/questoes/extrair-imagem` (multipart, campo `arquivo`) |
| Abrir o app com login guardado | `GET /api/auth/me` |
| Excluir rascunho | `DELETE /api/provas/:id` |
| Direção: ver PDF / aprovar / reprovar / em análise | `GET /api/provas/:id/previa-pdf`, `PATCH /api/provas/:id/revisao` |
| Repografia: abrir PDF / marcar impressão | `GET /api/provas/:id/previa-pdf`, `PATCH /api/provas/:id/impressao` |

A sessão é um token (JWT) devolvido pelo login, guardado em armazenamento
seguro (`flutter_secure_storage`) e enviado em `Authorization: Bearer <token>`
em toda requisição. Ao abrir o app, o token guardado é conferido em
`GET /api/auth/me`; se ainda vale, o app abre direto o painel.

## Estrutura do projeto

```
lib/
  main.dart                      Ponto de entrada
  theme.dart                     Paleta e tema visual
  models.dart                    Modelos (Usuario, Questao, Prova, Perfil)
  config.dart                    Endereço do servidor e chave do modo sem login
  api.dart                       Cliente HTTP, sessão e tratamento de erros
  app_state.dart                 Sessão e dados compartilhados entre telas
  arquivos.dart                  Abrir/compartilhar PDF e DOCX
  arquivos_salvar_io.dart        Android: folha de compartilhamento
  arquivos_salvar_web.dart       Navegador: download do arquivo
  validators.dart                Validação dos campos
  widgets/                       Menu lateral (por perfil) e componentes comuns
  screens/
    boas_vindas, login, cadastro, recuperar_senha, perfil
    professor/                   Painel, banco de questões, formulário de questão, montagem de prova
    direcao/                     Painel e revisão de provas
    repografia/                  Painel e impressão
```
