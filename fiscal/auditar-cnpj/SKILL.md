---
name: auditar-cnpj
description: >-
  Audita um CNPJ brasileiro em 360 graus usando o MCP fiscal-brasil — roda em
  paralelo cadastro (Receita), Simples Nacional, certidão federal (CND), FGTS,
  compliance consolidado, risk score de due diligence, comparação de regimes
  tributários e simulação da reforma 2026 — e consolida tudo num report markdown
  com um score geral 0–100 ponderado e uma análise interpretativa de negócio
  (red flags, leitura do quadro, recomendação acionável). Ative quando o usuário
  disser "audita esse cnpj", "auditar cnpj", "/auditar-cnpj", "faz um raio-x do
  cnpj", "raio-x da empresa", "analisa esse cnpj", "due diligence do cnpj",
  "checa a saúde fiscal da empresa", "score dessa empresa", "vale a pena fechar
  com esse fornecedor", ou colar um CNPJ/razão social pedindo análise completa.
  NÃO use para: validar CPF (é pessoa física — use a tool validar_cpf direto);
  processar NF-e, NFS-e, SPED ou eSocial (precisam de XML/arquivo — use as tools
  específicas); consulta cadastral rápida de um campo só (use consultar_cnpj
  direto, sem o combo); auditar vários CNPJs em lote (é um por vez).
---

# Auditar CNPJ — Raio-X 360°

Combo que orquestra 8 ferramentas do MCP `fiscal-brasil` sobre **um** CNPJ,
consolida num **score geral 0–100** e adiciona uma **análise interpretativa**
que nenhuma tool entrega sozinha. Output: markdown no chat. Sem emojis.

Pré-requisito: MCP `fiscal-brasil` conectado no cliente (`uvx mcp-fiscal-brasil`).
As tools aparecem como `mcp__fiscal-brasil__<nome>`.

---

## Workflow

### 1. Resolver e validar o input

- Se o input for um **CNPJ** (com ou sem formatação): extrair os 14 dígitos.
- **Validar o dígito verificador offline ANTES de chamar qualquer tool** (não
  gastar API com número inválido). Algoritmo módulo 11 padrão de CNPJ.
  - Se o DV não bater: parar, avisar que o CNPJ é inválido, mostrar qual seria
    o DV correto para a base, e se uma troca de 1 dígito tornar o número válido
    sugerir a correção. Pedir reconfirmação. Não inventar dados.
- Se o input for um **nome / razão social** (sem número): a tool
  `listar_cnpjs_por_nome` NÃO faz busca real (APIs públicas não cobrem). Usar
  **web search** para achar o CNPJ, validar o DV do candidato, e confirmar com
  o usuário antes de auditar ("achei X — é essa?").

### 2. Coleta paralela (chamar as 8 tools numa só leva)

Disparar em paralelo sobre o CNPJ validado:

| # | Tool MCP | Perspectiva |
|---|----------|-------------|
| 1 | `mcp__fiscal-brasil__consultar_cnpj` | Cadastro: situação, CNAE, QSA, capital, porte, idade |
| 2 | `mcp__fiscal-brasil__consultar_simples_nacional` | Enquadramento Simples/MEI |
| 3 | `mcp__fiscal-brasil__consultar_certidao_federal` | CND federal (débitos Receita/PGFN) |
| 4 | `mcp__fiscal-brasil__consultar_certidao_fgts` | Regularidade FGTS (Caixa) |
| 5 | `mcp__fiscal-brasil__analyze_cnpj_compliance` | Compliance consolidado (score próprio) |
| 6 | `mcp__fiscal-brasil__risk_score_supplier` | Risk score de due diligence |
| 7 | `mcp__fiscal-brasil__compare_tax_regimes` | Comparação MEI/Simples/Presumido/Real |
| 8 | `mcp__fiscal-brasil__simular_transicao_reforma_tributaria` | Impacto IBS/CBS 2026 |

Tools 1–6 alimentam o score. Tools 7–8 alimentam só a análise de oportunidade
tributária (não entram no score de saúde/risco).

### 3. Classificar cada retorno (distinção crítica)

Para cada fonte, classificar em uma de três:

- **Resultado positivo** — fonte respondeu e o dado é bom (ex.: CND negativa = sem
  débito; FGTS regular; situação ATIVA). Pontua.
- **Resultado negativo** — fonte respondeu e o dado é ruim (ex.: CND positiva =
  tem débito; situação SUSPENSA/BAIXADA). Penaliza.
- **Indisponível / não-aplicável** — fonte deu erro técnico (timeout, 5xx) OU
  retornou "não encontrado" por não-aplicabilidade. Sai do denominador, NÃO
  penaliza, marca "N/D".
  - Atenção: Simples/MEI retornando "CNPJ não encontrado" para uma LTDA é
    NORMAL (não é optante) — é não-aplicável, não é erro nem dado negativo.

### 4. Calcular o Score Geral (0–100)

**Gate de situação cadastral** (vem do `consultar_cnpj`):
- ATIVA → cálculo normal abaixo.
- SUSPENSA / INAPTA → score limitado a no máximo 40.
- BAIXADA / NULA / INEXISTENTE → score limitado a no máximo 15 (empresa morta);
  marcar no veredito.

**Dimensões (empresa ATIVA), soma = 100 pontos:**

- **Regularidade fiscal — 35 pts**
  - CND federal negativa (sem débito) → 20; positiva-com-efeito-de-negativa → 15; positiva (débito) → 0.
  - FGTS regular → 15; irregular → 0.
- **Compliance consolidado — 25 pts** = `score` do `analyze_cnpj_compliance` (0–100) × 0,25.
- **Due diligence / risco — 20 pts** = inverso do `risk_score_supplier`: risco baixo → 20; médio → 10; alto → 0.
- **Saúde cadastral — 20 pts**
  - Idade: > 3 anos → 8; 1–3 anos → 5; < 1 ano → 2.
  - Capital social compatível com o porte → 6; irrisório vs porte → 2.
  - CNAE coerente e sem alertas no compliance → 6.

**Normalização por cobertura:** se uma dimensão está indisponível (N/D),
remover seu peso e renormalizar o total sobre as dimensões disponíveis.
Sempre reportar a cobertura (ex.: "6/6 dimensões" ou "5/6 — FGTS indisponível").

**Faixas do veredito:**
- 85–100 → Saudável / baixo risco
- 70–84 → Atenção pontual
- 50–69 → Risco moderado — revisar antes de fechar
- < 50 → Alto risco / irregular

### 5. Escrever a análise interpretativa

A camada de julgamento (não repetir os dados crus — interpretá-los):
- **Leitura do quadro:** porte vs capital, tempo de mercado, setor (CNAE),
  composição do QSA, coerência geral.
- **Red flags:** débitos, certidões positivas, capital irrisório para o porte,
  empresa muito nova, situação não-ativa, divergência CNAE × atividade.
- **Ângulo due diligence:** apto a contratar? Que garantias pedir?
- **Ângulo própria empresa:** o regime atual é o ótimo (tools 7–8)? Qual o
  impacto da reforma 2026? Há economia tributária na mesa?

Ser direto e opinativo. Se algo está ruim, dizer. Sem hedge.

### 6. Montar o report (formato na seção abaixo) e entregar no chat.

---

## Output Format

```
# Raio-X CNPJ — {RAZAO_SOCIAL}
CNPJ {nn.nnn.nnn/nnnn-nn} · {nome_fantasia} · consultado em {data}

## Score Geral: {score}/100 — {faixa do veredito}
{uma linha justificando o número}

## Perspectivas
| Dimensão | Resultado | Status |
|----------|-----------|--------|
| Situação cadastral | {ATIVA/...} | OK / ALERTA / N/D |
| Regularidade fiscal (CND) | {negativa/positiva} | ... |
| FGTS | {regular/irregular} | ... |
| Simples Nacional | {optante/não optante} | ... |
| Compliance | score {n}/100 | ... |
| Risco due diligence | {baixo/médio/alto} | ... |

## Pontos de atenção
- {red flags concretos, ou "Nenhum relevante."}

## Análise
{prosa interpretativa — leitura do quadro, ângulo DD e ângulo tributário}

## Recomendação
{acionável: apto/não apto a fechar; ou movimento tributário sugerido}

## Cobertura
Fontes no score: {X}/6. Indisponíveis (não penalizam): {lista ou "nenhuma"}.
Dados via MCP fiscal-brasil (BrasilAPI, Receita, Caixa, SEFAZ).
```

---

## Edge Cases

- **CNPJ com DV inválido:** parar antes de qualquer chamada de API; mostrar o DV
  correto da base; se troca de 1 dígito validar, sugerir; pedir reconfirmação.
- **Só veio o nome da empresa:** resolver via web search, validar DV do
  candidato, confirmar com o usuário antes de auditar.
- **Fonte indisponível (timeout/5xx):** marcar N/D, tirar do denominador do
  score, reportar na cobertura — nunca tratar indisponível como dado negativo.
- **Simples/MEI "não encontrado" em LTDA:** é não-optante (normal), não é erro
  nem ponto negativo.
- **Empresa BAIXADA/SUSPENSA:** aplicar o gate (teto 15/40) e destacar no topo —
  não deixar o número parecer melhor do que a realidade.
- **CND/FGTS exigindo captcha ou fora do ar (comum nos portais gov):** N/D +
  nota de que a certidão precisa ser puxada manualmente no portal.
- **Pedido de auditar vários CNPJs:** rodar um de cada vez (a skill é 1:1); avisar.

---

## Exemplos

### Exemplo 1 — CNPJ válido (caminho feliz)

**Input:** `audita o cnpj 11.222.333/0001-81`

**Output (resumido):** report completo com cabeçalho "Raio-X CNPJ — {RAZÃO
SOCIAL}", Score Geral com faixa (ex.: "78/100 — Atenção pontual" se CND/FGTS
vierem N/D), tabela de perspectivas (Situação ATIVA OK; Simples conforme
enquadramento; Compliance com score; risco de due diligence), pontos de
atenção, análise interpretativa (porte, setor/CNAE, tempo de mercado,
composição do QSA), recomendação e bloco de cobertura ("5/6 — FGTS N/D").

### Exemplo 2 — CNPJ com dígito verificador inválido

**Input:** `faz um raio-x do cnpj 42.750.901/0001-72`

**Output esperado:**
```
Esse CNPJ é inválido — o dígito verificador não bate (informado 72, correto
para a base 42.750.901/0001 seria 40). Não rodei nenhuma consulta.

Provável erro de digitação. Reconfere o número (cartão CNPJ / contrato social)
e me manda de novo, ou me passa a razão social que eu busco o CNPJ certo.
```

---

## Notas de manutenção

- `compare_tax_regimes` e `simular_transicao_reforma_tributaria` ficam fora do
  score de propósito (são oportunidade, não saúde). Não somar ao 0–100.
- Se a versão do MCP subir, conferir se os nomes de tools (seção 2) e os campos
  `score`/`risco` retornados mudaram.
