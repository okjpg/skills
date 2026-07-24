# Conselho de IA

**Toda IA que você já pediu conselho concordou com você. Isso não é porque você tem razão — é porque ela foi treinada pra agradar.**

Você descreve seu plano animado, o modelo encontra motivos pro plano ser bom. Você pede pra ele "ser crítico", ele faz três ressalvas educadas e volta a concordar. Isso é um espelho caro. Conselho de verdade é quando alguém que te conhece encontra o furo que você não quis ver.

Este kit constrói exatamente isso, com duas peças:

1. **Um perfil de pensamento** — um documento curto de *como você julga*: seus vieses, o que te convence, onde você historicamente erra. Sem ele, a IA te dá conselho genérico de LinkedIn. Com ele, ela argumenta de um jeito que fala com você.
2. **Um conselho de três lentes com regra anti-claque** — três conselheiros de ângulos opostos, instruídos por escrito a **discordar de você e um do outro**, debatendo em rodadas até um veredicto. Não é "pergunta pra 3 IAs". É três IAs proibidas de te bajular.

## O que você leva pro conselho

Decisões com dois caminhos defensáveis e custo real de errar. Alguns exemplos:

- *"Aceito esse cliente de consultoria de R$ 15k ou ele vai me distrair do produto pelos próximos dois meses?"*
- *"Lanço meu curso pago a R$ 97 ou de graça como isca pro programa maior?"*
- *"Contrato o segundo vendedor agora ou seguro mais um trimestre no aperto?"*
- *"Aceito o cheque do investidor-anjo ou continuo bootstrap e mantenho o controle?"*
- *"Essa pauta é boa ou já foi feita mil vezes por todo criador de tech?"*

O que **não** vai pro conselho: decisão reversível de baixo custo (a cor do botão — testa e mede) e pergunta factual (isso é busca, não julgamento).

## Nível 0 — roda em 5 minutos, sem instalar nada

Você precisa de: **qualquer ChatGPT, Claude ou Gemini.** Só.

1. **Gere seu perfil.** Cole [`prompts/1-perfil-de-pensamento.md`](prompts/1-perfil-de-pensamento.md) numa sessão nova, responda as 8 perguntas. Salve o resultado — você reusa em toda decisão.
2. **Rode o conselho.** Cole [`prompts/2-conselho.md`](prompts/2-conselho.md) numa sessão nova, junto com o seu perfil e a decisão. A IA assume as três lentes e debate.
3. **Leia as tensões, não só o veredicto.** O ouro está em *onde os conselheiros brigaram* — é ali que a decisão realmente mora.

O que sai tem esta cara:

```
## Veredicto
Aceite o cliente, mas com escopo fechado em 6 semanas e um "não" default a tudo fora dele.

## Onde convergiram
- R$ 15k não compensa perder o momentum do produto por 2 meses inteiros.
- O risco não é o dinheiro, é o escopo virar infinito.

## Tensões vivas
- Contrarian: recuse — todo projeto de cliente vira 3x o combinado, e você sabe disso.
- Outsider: aceite e use como estudo de caso pago pro seu próprio marketing.
- Primeiros Princípios: a pergunta certa não é sim/não, é "isso tem dono que não seja você?".

## Recomendação
Você rejeita trabalho que vira supervisão sua. Só aceite se alguém do time
puder ser dono da entrega. Se for você no gargalo, é não.
```

## Nível 1 — o conselho com 3 modelos reais

O nível 0 simula três conselheiros dentro de uma sessão. Dá pra ir além: rodar **três modelos de famílias diferentes de verdade** — cada um cego ao que os outros disseram, debatendo em rodadas reais. Três famílias discordam muito mais do que três personas do mesmo modelo.

Isso exige um agente de linha de comando com múltiplos provedores conectados (Claude Code, Hermes ou similar). O template vem pronto pra preencher: veja [`SKILL.md`](SKILL.md) e [`scripts/council.sh`](scripts/council.sh) — parametrizados com `{{campos}}` pro seu host e os seus modelos.

## Case real — como a gente roda isso na Pixel

A versão que a gente usa internamente é o topo dessa escada, e mostra até onde a ideia vai.

Nosso agente pessoal — a **Amora** — roda num servidor 24/7 sobre o Hermes. Ela acumulou **meses** de contexto sobre como a gente pensa e decide. Esse contexto vira o perfil de pensamento automaticamente, destilado de três fontes: o histórico do próprio agente, um grafo de conhecimento (gbrain) e uma camada de memória de "teoria da mente" ([Honcho](https://honcho.dev)) que modela padrões ao longo do tempo. Ninguém escreve o perfil à mão — ele é a sedimentação do que o agente já viu.

Quando bate uma decisão de verdade — *que corte dar numa palestra, aceitar um patrocínio, matar ou manter um produto* — funciona assim:

1. **Take rápido.** A Amora responde em segundos, ancorada no perfil, e crava se a decisão merece o conselho ou não. Barato por padrão.
2. **Se merece, o conselho dispara.** Três LLMs de famílias diferentes — **Grok, GPT e Gemini** — recebem o perfil e a pauta, e debatem: parecer → refutação → convergência. Cada um cego aos outros até a hora de refutar.
3. **A Amora sintetiza por cima.** Ela leu o debate inteiro e, como conhece a gente, dá o veredicto final — inclusive discordando do conselho quando ele erra o alvo.

O debate roda **em background, enquanto a gente segue trabalhando**, e o resultado cai na conversa quando fica pronto. Custo real de uma rodada completa (9 chamadas de modelo): **cerca de US$ 0,24 e poucos minutos** — porque dois dos três modelos entram por assinatura, e o overhead de contexto de cada conselheiro foi cortado em ~87%.

O detalhe que faz a diferença: uma **regra anti-claque** injetada em todo conselheiro — *"este perfil descreve como a pessoa julga, inclusive onde ela falha; não é a resposta certa. Você pode e deve dizer que ela está errada."* Sem isso, três modelos lendo "como o Bruno pensa" simplesmente devolvem o que o Bruno já pensa. Com isso, eles brigam — e é da briga que sai a decisão.

Você não precisa dessa máquina toda pra capturar 80% do valor. O nível 0 acima roda hoje, no seu chat, de graça. O case é só pra mostrar onde a estrada chega.

## Por que isso funciona

Método inspirado no [LLM Council](https://github.com/karpathy/llm-council) (Andrej Karpathy) — vários modelos revisando uns aos outros — somado à ideia de **ancorar o debate em como o usuário pensa**, não só na pergunta. O ganho não é a ferramenta. É o hábito de externalizar o seu julgamento e pressionar decisões por ângulos que discordam de você — em vez de pedir bênção pra uma IA que já decidiu concordar.
