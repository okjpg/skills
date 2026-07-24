---
name: conselho-de-ia
description: >
  Conselheiro multi-LLM que opina sobre decisões de estratégia, produto ou
  conteúdo, ancorado num perfil de pensamento do usuário. Dá um take rápido e,
  quando a decisão tem stakes reais, escala para um conselho de três modelos de
  famílias diferentes que debatem em três rodadas (parecer, refutação,
  convergência) com regra anti-claque, rodando em background. Ativa em "conselho",
  "roda o conselho", "pede opinião do conselho", "leva isso pro conselho de ia",
  "o que o conselho acha". NÃO use para pergunta factual, geração de conteúdo
  final, ou operação de servidor. Template parametrizado — preencha os {{campos}}.
---

# Conselho de IA (template nível 1)

Versão de referência do método "Conselho de IA" para um agente de linha de comando com múltiplos provedores (Claude Code, Hermes ou similar). Roda três LLMs **reais** em vez de três personas numa sessão só.

> Este é um **template**. Substitua todo `{{campo}}` pela sua configuração antes de usar. Onde o nível 0 (ver `README.md`) roda em qualquer chat sem instalar nada, este nível exige infra própria.

## Configuração — preencha antes de usar

| Campo | O que é | Exemplo |
|-------|---------|---------|
| `{{AGENTE_ONESHOT}}` | comando que envia 1 prompt e imprime só a resposta | `hermes -z "<prompt>"` |
| `{{FLAG_PROVIDER}}` `{{FLAG_MODELO}}` | como escolher provider e modelo por chamada | `--provider X -m Y` |
| `{{FLAGS_ENXUTAS}}` | flags que cortam contexto do agente (conselheiro não precisa de ferramenta) | `--safe-mode -t todo` |
| `{{PERFIL_PATH}}` | onde vive o seu perfil de pensamento | `~/perfil-de-pensamento.md` |
| `{{PROVIDER_CONTRARIAN}}` / `{{MODELO_CONTRARIAN}}` | modelo da lente Contrarian | um modelo "espinhudo" |
| `{{PROVIDER_PRINCIPIOS}}` / `{{MODELO_PRINCIPIOS}}` | modelo da lente Primeiros Princípios | um modelo forte em raciocínio |
| `{{PROVIDER_OUTSIDER}}` / `{{MODELO_OUTSIDER}}` | modelo da lente Outsider | um modelo de outra família |

Regra de ouro: escolha **três famílias de modelo diferentes**. Três variações do mesmo modelo concordam demais.

## Workflow

1. Ler `{{PERFIL_PATH}}`. SE não existir → gerar primeiro com o prompt de perfil (ver `prompts/1-perfil-de-pensamento.md`). Não seguir com perfil vazio.
2. Montar o prompt do take rápido: perfil + a decisão do usuário + instrução de fechar com `conselho: sim — <motivo>` ou `conselho: não precisa`.
3. Rodar `{{AGENTE_ONESHOT}}` com contexto cheio (o take rápido é "você", precisa te conhecer).
4. Imprimir o take e a recomendação. SE `não precisa` → encerrar.
5. SE `sim` → perguntar ao usuário se deve rodar o conselho. Aguardar confirmação explícita. O conselho custa tempo e tokens; o gate é do usuário.
6. Após o "sim", rodar `scripts/council.sh <id>` em background (`setsid nohup ... </dev/null &`). Devolver o controle na hora.
7. Quando `result.md` aparecer, apresentar: Veredicto / Onde convergiram / Tensões vivas / Recomendação.

## Duas invocações — não misturar

- **Você** (take rápido e síntese final): agente com **contexto cheio** — precisa da sua memória/perfil.
- **Conselheiros**: agente com `{{FLAGS_ENXUTAS}}` — são estranhos, só sabem o que o prompt entrega. Cortar o contexto do agente derruba muito o custo por chamada.

## Regra anti-claque (obrigatória em todo prompt de conselheiro)

> Este perfil descreve como o usuário julga, inclusive onde ele falha — não descreve a resposta certa. Você pode e deve afirmar que um viés dele está errado nesta decisão. Concordar não é o objetivo; testar é.

SE as três lentes concordarem entre si E com o usuário na rodada 1 → tratar como claque, não consenso: na rodada 2, cada uma constrói o melhor caso contra a posição do usuário antes de convergir.

## Rodadas

1. **Parecer** — os três em paralelo, cada um pela sua lente.
2. **Refutação** — cada um lê os outros e aponta o ponto mais fraco. Sem concordar por educação.
3. **Convergência** — consenso ou desacordo irredutível declarado.
4. **Síntese** — o agente com contexto cheio escreve o veredicto por cima.

## Edge Cases

- Se um conselheiro falhar/estourar timeout: seguir com os outros dois e declarar qual lente faltou.
- Se `{{FLAG_PROVIDER}}` exigir `{{FLAG_MODELO}}` junto (comum): sempre passar o par.
- Se a pergunta for factual e não um julgamento: responder direto, não convocar o conselho.
- Se os três convergirem já na rodada 1: aplicar a regra anti-claque antes de aceitar o consenso.

## Examples

### Exemplo 1 — escalada
Input: `conselho: lanço meu produto como pago ou como isca gratuita?`
Output: take rápido ancorado no perfil, fechando com `conselho: sim — decisão de posicionamento com dois lados defensáveis`. Após confirmação, roda o conselho em background e entrega a síntese.

### Exemplo 2 — sem escalada
Input: `conselho: uso azul ou verde no botão?`
Output: take rápido curto, fechando com `conselho: não precisa — decisão reversível de baixo custo, teste A/B resolve`. Não convoca o conselho.
