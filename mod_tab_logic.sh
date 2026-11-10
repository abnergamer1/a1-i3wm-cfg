#!/bin/bash
# Usado com $mod+Tab.
# Se houver mais de 1 workspace: alterna entre o workspace atual e o anterior (back_and_forth).
# Se houver apenas 1 workspace: foca a próxima tile (janela) dentro dele.

TREE=$(i3-msg -t get_tree)

# Total de workspaces abertos
TOTAL=$(i3-msg -t get_workspaces | jq 'length')

if [ "$TOTAL" -gt 1 ]; then
    i3-msg workspace back_and_forth
else
    # Só existe 1 workspace: cicla as janelas dele (independe de orientação/layout)
    CURRENT=$(i3-msg -t get_workspaces | jq '.[] | select(.focused).num')

    WINDOW_IDS=($(echo "$TREE" | jq -r "
      recurse(.nodes[]?, .floating_nodes[]?)
      | select(.type == \"workspace\" and .num == $CURRENT)
      | [recurse(.nodes[]?, .floating_nodes[]?) | select(.window != null) | .id]
      | .[]
    "))

    WINDOW_COUNT=${#WINDOW_IDS[@]}

    if [ "$WINDOW_COUNT" -gt 1 ]; then
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

        NEW_WIN_INDEX=$(( (WIN_INDEX + 1) % WINDOW_COUNT ))
        TARGET_ID=${WINDOW_IDS[$NEW_WIN_INDEX]}
        i3-msg "[con_id=$TARGET_ID] focus"
    fi
    # Se só tiver 0 ou 1 janela no único workspace, não há nada a fazer.
fi
