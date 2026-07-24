# Conselho de IA

Um conselho de IAs que **debate a sua decisão e se refuta** — em vez de te dar razão — ancorado em **como você pensa**.

Você já reparou que, quando você pede conselho pro ChatGPT, ele quase sempre concorda com você? Não é coincidência: modelos de linguagem são treinados pra agradar. Você descreve seu plano com entusiasmo, ele encontra motivos pra o plano ser bom. Isso é um espelho caro, não um conselho.

Este kit resolve isso com duas ideias:

1. **Perfil de pensamento** — um documento curto de como *você* julga (seus vieses, o que te convence, onde você erra). Sem isso, a IA te dá conselho genérico de LinkedIn. Com isso, ela argumenta de um jeito que fala com você.
2. **Conselho multi-lente com regra anti-claque** — três conselheiros com ângulos opostos (um cava o buraco, um ataca o mecanismo, um pensa como quem tá de fora), instruídos explicitamente a **discordar de você e um do outro**. Eles debatem em rodadas até um veredicto.

## Nível 0 — roda em 5 minutos, sem instalar nada

Você precisa de: **qualquer ChatGPT, Claude ou Gemini.** Só isso.

1. **Gere seu perfil.** Abra [`prompts/1-perfil-de-pensamento.md`](prompts/1-perfil-de-pensamento.md), cole numa sessão nova de IA, responda as 8 perguntas. Ela devolve seu perfil de pensamento. Salve num arquivo — você reusa em toda decisão.
2. **Rode o conselho.** Abra [`prompts/2-conselho.md`](prompts/2-conselho.md), cole numa sessão nova, junto com o seu perfil e a decisão que você está pensando. A IA assume as três personas, roda o debate e te entrega: veredicto, onde concordaram, onde brigaram, e a recomendação.
3. **Leia as tensões, não só o veredicto.** O ouro está em "onde brigaram" — é onde a decisão realmente mora.

> A regra que faz funcionar: os conselheiros são instruídos a tratar seu perfil como *"assim é como essa pessoa julga, inclusive onde ela erra — não é a resposta certa"*. Concordar com você não é o objetivo; testar sua ideia é.

## Nível 1 — o conselho de verdade, com 3 IAs reais

O nível 0 simula três conselheiros dentro de uma sessão só. Dá pra ir além: rodar **três modelos diferentes de verdade** (ex: Grok, GPT e Gemini), cada um cego ao que os outros disseram, debatendo em rodadas reais. Três famílias de modelo discordam mais do que três personas do mesmo modelo.

Isso exige um agente de linha de comando com múltiplos provedores conectados (Claude Code, Hermes ou similar). Veja [`SKILL.md`](SKILL.md) e [`scripts/council.sh`](scripts/council.sh) — vêm parametrizados pra você preencher com o seu host e os seus modelos.

## Por que isso existe

Método inspirado no [LLM Council](https://github.com/karpathy/llm-council) (Andrej Karpathy) — vários modelos revisando uns aos outros — somado à ideia de ancorar o debate em *como o usuário pensa*, não só na pergunta. O ganho não é a ferramenta; é o hábito de **externalizar seu julgamento e pressionar decisões por ângulos que discordam de você.**
