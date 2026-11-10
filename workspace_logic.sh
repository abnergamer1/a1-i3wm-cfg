#!/bin/bash
DIRECTION="$1"

TREE=$(i3-msg -t get_tree)

# Current workspace
CURRENT=$(echo "$TREE" | jq '[recurse(.nodes[]?, .floating_nodes[]?) | select(.type=="workspace" and (.nodes[]?.focused==true or .floating_nodes[]?.focused==true))][0].num')

# Fallback: pega workspace focado via get_workspaces (mais confiável)
CURRENT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).num')

# Lista, em ORDEM DE ÁRVORE (DFS), os con_id de todas as janelas (leaves) do workspace atual
WINDOW_IDS=($(echo "$TREE" | jq -r "
  recurse(.nodes[]?, .floating_nodes[]?)
  | select(.type == \"workspace\" and .num == $CURRENT)
  | [recurse(.nodes[]?, .floating_nodes[]?) | select(.window != null) | .id]
  | .[]
"))

WINDOW_COUNT=${#WINDOW_IDS[@]}

# Get ordered workspace numbers
WORKSPACES=($(i3-msg -t get_workspaces | jq '.[].num' | sort -n))

# Find current workspace index
INDEX=0
for i in "${!WORKSPACES[@]}"; do
    if [ "${WORKSPACES[$i]}" = "$CURRENT" ]; then
        INDEX=$i
        break
    fi
done
TOTAL=${#WORKSPACES[@]}

if [ "$WINDOW_COUNT" -le 1 ]; then
    # Só uma janela (ou nenhuma): troca de workspace
    if [ "$DIRECTION" = "next" ]; then
        NEW_INDEX=$(( (INDEX + 1) % TOTAL ))
    else
        NEW_INDEX=$(( (INDEX - 1 + TOTAL) % TOTAL ))
    fi
    TARGET=${WORKSPACES[$NEW_INDEX]}
    i3-msg workspace number "$TARGET"
else
    # Múltiplas janelas: acha a focada e pula pra próxima/anterior na árvore
    FOCUSED_ID=$(echo "$TREE" | jq "
      [recurse(.nodes[]?, .floating_nodes[]?) | select(.window != null and .focused == true)][0].id
    ")

    WIN_INDEX=0
    for i in "${!WINDOW_IDS[@]}"; do
        if [ "${WINDOW_IDS[$i]}" = "$FOCUSED_ID" ]; then
            WIN_INDEX=$i
            break
        fi
    done

    if [ "$DIRECTION" = "next" ]; then
        NEW_WIN_INDEX=$(( (WIN_INDEX + 1) % WINDOW_COUNT ))
    else
        NEW_WIN_INDEX=$(( (WIN_INDEX - 1 + WINDOW_COUNT) % WINDOW_COUNT ))
    fi

    TARGET_ID=${WINDOW_IDS[$NEW_WIN_INDEX]}
    i3-msg "[con_id=$TARGET_ID] focus"
fi
