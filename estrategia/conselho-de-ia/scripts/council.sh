#!/usr/bin/env bash
# Conselho multi-LLM — engine determinístico. Uso: council.sh <id>
# brief.md deve existir em $COUNCIL_DIR/<id>/. Genérico: configure via env abaixo.
set -uo pipefail

# ---- CONFIGURE ----
# ONESHOT: comando que envia 1 prompt e imprime só a resposta. Recebe o prompt em $1.
ONESHOT="${ONESHOT:-hermes -z}"
LEAN_FLAGS="${LEAN_FLAGS:---safe-mode -t todo}"        # cortam contexto do agente (conselheiros)
COUNCIL_DIR="${COUNCIL_DIR:-$HOME/.council}"
# Três lentes: nome:provider:modelo — USE TRÊS FAMÍLIAS DIFERENTES.
LENSES="${LENSES:-contrarian:PROVIDER_A:MODELO_A principios:PROVIDER_B:MODELO_B outsider:PROVIDER_C:MODELO_C}"
# -------------------

ID="${1:?id obrigatorio}"; D="$COUNCIL_DIR/$ID"; B="$D/brief.md"
[ -f "$B" ] || { echo "brief.md ausente em $D" >&2; exit 1; }

lens_desc() { case "$1" in
  contrarian) echo "CONTRARIAN. Cave o downside. Ache o modo de falha que ninguem quer olhar. Fure o otimismo.";;
  principios) echo "PRIMEIROS PRINCIPIOS. Ataque mecanismo e execucao: funciona COMO, exatamente? O que quebra na pratica?";;
  outsider)   echo "OUTSIDER. Enquadramento de mercado e alternativas. O que alguem de fora, sem apego, veria?";;
esac; }

ANTIECHO='REGRA: o perfil descreve COMO a pessoa julga, inclusive onde ela falha - NAO a resposta certa. Voce pode e deve afirmar que um vies dela esta errado aqui. Concordar nao e o objetivo; testar e. No maximo 12 linhas, sem preambulo.'

# roda o agente enxuto: nome provider modelo prompt_file out_file
# Nota: se uma lente falha, o marcador [LENTE ... FALHOU] entra como "parecer" nas
# rodadas seguintes. Não quebra o debate, mas a síntese deve tratar lente ausente
# explicitamente. Para exigir robustez, filtre marcadores de falha antes da rodada 2.
run() { timeout 300 $ONESHOT "$(cat "$4")" --provider "$2" -m "$3" $LEAN_FLAGS > "$5" 2>&1 \
        || echo "[LENTE $1 FALHOU OU ESTOUROU TIMEOUT]" > "$5"; }

for RD in 1 2 3; do
  for L in $LENSES; do N=${L%%:*}; R=${L#*:}; P=${R%%:*}; M=${R#*:}
    { cat "$B"; echo; echo "SUA LENTE: $(lens_desc "$N")"; echo; echo "$ANTIECHO"; echo
      case $RD in
        1) echo "RODADA 1 - de seu parecer sobre a pauta.";;
        2) echo "RODADA 2 - PARECERES DOS OUTROS (anonimos):"
           for O in $LENSES; do ON=${O%%:*}; [ "$ON" = "$N" ] && continue; echo; echo "--- parecer ---"; cat "$D/r1-$ON.md"; done
           echo; echo "TAREFA: aponte o ponto MAIS FRACO de cada. Nao concorde por educacao.";;
        3) echo "RODADA 3 - AS REFUTACOES:"; for O in $LENSES; do ON=${O%%:*}; echo; echo "--- refutacao ---"; cat "$D/r2-$ON.md"; done
           echo; echo "Declare: (a) recomendacao final em 1 frase; (b) onde CONVERGE; (c) onde o DESACORDO e IRREDUTIVEL. Max 8 linhas.";;
      esac
    } > "$D/p$RD-$N.txt"
    run "$N" "$P" "$M" "$D/p$RD-$N.txt" "$D/r$RD-$N.md" &
  done; wait
done

{ echo "# Debate — $ID"; for RD in 1 2 3; do echo; echo "## Rodada $RD"; for L in $LENSES; do N=${L%%:*}
    echo; echo "### $N"; cat "$D/r$RD-$N.md"; done; done; } > "$D/debate.md"

# sintese com contexto CHEIO (sem LEAN_FLAGS) — "voce", que conhece a pessoa
{ cat "$B"; echo; echo "===== DEBATE ====="; cat "$D/debate.md"
  cat <<'FIM'

===== SUA TAREFA =====
Leu o debate. Escreva a sintese EXATAMENTE assim, sem preambulo:

## Veredicto
<uma frase>
## Onde convergiram
<bullets>
## Tensoes vivas
<desacordos que NAO fecharam, dizendo qual lente defendeu o que>
## Recomendacao
<ancorada no perfil da pessoa; e a que pesa mais. Se o conselho errou o alvo, diga.>
FIM
} > "$D/p-sintese.txt"
timeout 600 $ONESHOT "$(cat "$D/p-sintese.txt")" > "$D/result.md" 2>&1 || echo "[SINTESE FALHOU]" > "$D/result.md"
echo "OK $ID" > "$D/DONE"
