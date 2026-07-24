# skills

Skills públicas para Claude Code / agentes MCP.

## fiscal/

- **[auditar-cnpj](fiscal/auditar-cnpj/)** — Raio-X 360° de um CNPJ via MCP
  [fiscal-brasil](https://github.com/DeHor-Labs/mcp-fiscal-brasil): cadastro,
  Simples, certidões (CND/FGTS), compliance, risk score e regimes tributários,
  consolidados num score 0–100 com análise interpretativa. Requer o MCP
  `fiscal-brasil` conectado no cliente.

## estrategia/

- **[conselho-de-ia](estrategia/conselho-de-ia/)** — Um conselho de IAs que debate
  a sua decisão e se refuta (em vez de te dar razão), ancorado em como *você*
  pensa. **Nível 0** roda em 5 min em qualquer ChatGPT/Claude/Gemini, sem instalar
  nada (kit de prompts em `prompts/`). **Nível 1** é o template pra rodar 3 modelos
  reais debatendo via agente CLI. Método inspirado no LLM Council (Karpathy) +
  perfil de pensamento do usuário.

Cada skill traz `SKILL.md` + `evals/evals.json`.
