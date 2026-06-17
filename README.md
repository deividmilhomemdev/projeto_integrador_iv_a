# Projeto Integrador IV-A — Ouvidoria da Mulher

> Testes automatizados e versionamento colaborativo aplicados a um módulo real do aplicativo **Ouvidoria da Mulher**.

![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?logo=flutter&logoColor=white)
![Testes](https://img.shields.io/badge/Testes-flutter__test-success)
![Backend](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)
![Status](https://img.shields.io/badge/Status-Acad%C3%AAmico-blue)

Repositório referente à disciplina **Projeto Integrador IV-A** do curso de **Análise e Desenvolvimento de Sistemas (EaD)** da **PUC Goiás**.

- **Autor:** Deivid Milhomem
- **Professor:** Thalles Bruno G. N. dos Santos
- **Ano:** 2026

---

## Sobre o projeto

A proposta da disciplina foi exercitar **testes automatizados** (unitários e funcionais) e **controle de versão colaborativo** com Git/GitHub. Em vez de uma calculadora isolada, o conteúdo foi aplicado sobre um sistema real e já existente — o aplicativo **Ouvidoria da Mulher**, desenvolvido em projetos integradores anteriores.

A funcionalidade implementada nesta entrega foi definida em um encontro com o time da coordenação da Ouvidoria da Mulher (29/05/2026): a inclusão de um **CRUD** na página **"Materiais e Informações"**, que concentra conteúdos de uso comum (PDFs e imagens). Antes estática, a página passou a permitir a **inclusão e exclusão de itens** — operações de escrita restritas exclusivamente ao perfil **ADMIN**.

---

## Equivalência tecnológica (Java/JUnit → Flutter/flutter_test)

A ementa sugeria Java + JUnit 5. Como o app já é em Flutter, os testes foram escritos com o pacote nativo `flutter_test`, conceitualmente equivalente:

| Conceito | Java + JUnit 5 | Flutter + flutter_test |
|---|---|---|
| Caso de teste | `@Test` | `test( ... )` |
| Agrupamento | `@Nested` | `group( ... )` |
| Asserção | `assertEquals` / `assertTrue` | `expect(real, matcher)` |
| Espera de exceção | `assertThrows` | `expect(() => ..., throwsA(...))` |
| Teste funcional de UI | libs externas | `testWidgets` + `WidgetTester` (nativo) |
| Estrutura | Arrange–Act–Assert | Arrange–Act–Assert |

---

## Tecnologias

- **Flutter / Dart** — interface e regras de negócio
- **flutter_test** — testes unitários e de widget
- **Supabase** — persistência de dados e **Storage público** para arquivos (PDF e imagem)
- **Git / GitHub** — versionamento seguindo o método **GitFlow**

---

## Estrutura do módulo

```text
lib/
 ├─ ...                       # demais telas e serviços do app
 ├─ regras_negocio.dart       # regras puras: privilégio de ADMIN + validação de dados
 └─ detalhe_texto_page.dart   # interface; exibe controles de CRUD apenas para ADMIN
test/
 └─ ...                       # testes unitários (RegrasNegocio) e de widget (DetalheTextoPage)
```

- **`RegrasNegocio`** — classe Dart pura (sem dependência de UI, rede ou banco), responsável por validar o privilégio de administrador e o preenchimento dos dados. Por ser isolada, é totalmente testável de forma unitária.
- **`DetalheTextoPage`** — camada de apresentação. Renderiza os botões de inclusão/exclusão de forma condicional, conforme o resultado da `RegrasNegocio`.

---

## Como executar

Pré-requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado.

```bash
# 1. Clonar o repositório
git clone https://github.com/deividmilhomemdev/projeto_integrador_iv_a.git
cd projeto_integrador_iv_a

# 2. Instalar as dependências
flutter pub get

# 3. Rodar a aplicação
flutter run
```

---

## Executando os testes

```bash
# Roda toda a suíte (testes unitários + de widget)
flutter test
```

**Testes unitários** — cobrem a `RegrasNegocio` em três cenários: sucesso (ADMIN com dados válidos), falha (usuário comum sem privilégio) e valores nulos/vazios.

**Testes funcionais (widget)** — usam `testWidgets` e `WidgetTester` para renderizar a `DetalheTextoPage`, verificar a presença/ausência dos controles conforme o perfil e simular a interação do usuário (`tester.tap`).

---

## Fluxo de versionamento (GitFlow)

```bash
# Criação da branch de funcionalidade a partir da main
git checkout -b feature/crud-materiais-informacoes

# Commits regulares e atômicos durante o desenvolvimento
git add .
git commit -m "feat: adiciona CRUD em Materiais e Informacoes"

# Envio da branch e abertura de Pull Request para merge na main
git push origin feature/crud-materiais-informacoes
```

A incorporação à `main` foi feita via **Pull Request**, revisando o *diff* antes do **merge** — simulando o fluxo de uma equipe real.

---

## Observação de segurança

A validação de privilégio de ADMIN na `RegrasNegocio` atua no **lado do cliente** e controla a experiência do usuário. Em produção, ela deve ser a primeira camada de uma estratégia de **defesa em profundidade**, complementada por políticas de **Row Level Security (RLS)** no Supabase, garantindo a autorização na fonte dos dados — e não apenas na interface.

---

## Licença

Projeto desenvolvido em caráter acadêmico. Uso restrito a fins educacionais.
