#!/bin/bash
# Uso: smart_resize.sh <left|right|up|down> [alt]
#  sem "alt": a borda do lado da tecla anda na direção da tecla (grow);
#             se essa borda está colada na tela, a borda oposta anda na direção da tecla (shrink).
#  com "alt": prefere a borda oposta (shrink); se ela estiver colada na tela, cai no caso acima.
DIR="$1"; MODE="${2:-primary}"
STEP_PX=20     # usado em janelas flutuantes
STEP_PPT=5     # usado em janelas tiled (pontos percentuais do container pai)
TOL=3          # tolerância (px) para considerar a janela colada na borda

case "$DIR" in
  left) OPP=right;; right) OPP=left;; up) OPP=down;; down) OPP=up;;
  *) exit 2;;
esac

WS_RECT=$(i3-msg -t get_workspaces | jq -c '.[] | select(.focused).rect')
read -r FLOATING WX WY WW WH X Y W H < <(
  i3-msg -t get_tree | jq -r --argjson ws "$WS_RECT" '
    [recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true)][0] // empty
    | [ ((.floating // "") | endswith("_on")),
        $ws.x, $ws.y, $ws.width, $ws.height,
        .rect.x, .rect.y, .rect.width, .rect.height ] | @tsv')
[ -z "$H" ] && exit 0

blocked() {
  case "$1" in
    left)  [ $(( X - WX )) -le $TOL ] ;;
    right) [ $(( (WX + WW) - (X + W) )) -le $TOL ] ;;
    up)    [ $(( Y - WY )) -le $TOL ] ;;
    down)  [ $(( (WY + WH) - (Y + H) )) -le $TOL ] ;;
  esac
}
go() { i3-msg "resize $1 $2 $STEP_PX px or $STEP_PPT ppt" >/dev/null; }

if [ "$FLOATING" = true ]; then
  # flutuante: qualquer borda pode andar livremente
  if [ "$MODE" = alt ]; then go shrink "$OPP"; else go grow "$DIR"; fi
  exit 0
fi

if [ "$MODE" = alt ]; then
  if   ! blocked "$OPP"; then go shrink "$OPP"
  elif ! blocked "$DIR"; then go grow "$DIR"; fi
else
  if   ! blocked "$DIR"; then go grow "$DIR"
  elif ! blocked "$OPP"; then go shrink "$OPP"; fi
fi
