#!/usr/bin/env bash
set -euo pipefail

# --- activate env ---
source /opt/micromamba/etc/profile.d/micromamba.sh
micromamba activate diffpipe

: "${JUPYTER_PORT:=8888}"
: "${JUPYTER_TOKEN:=}"          # blank => no token
: "${TENSORBOARD_PORT:=6006}"
: "${TB_LOGDIR:=/workspace/output}"
: "${AUTO_GIT_PULL:=true}"      # set to false to skip repo update
: "${MODEL_PRESET:=}"           # e.g., wan22_low | wan22_high | wan22_i2v14b
: "${MODEL_URLS:=}"             # optional; semicolon or newline separated URLs
: "${HF_TOKEN:=}"               # optional Hugging Face token for private models

mkdir -p "${TB_LOGDIR}" /workspace/modelsext

# --- repo sync ---
if [ "${AUTO_GIT_PULL}" = "true" ]; then
  if [ -d /app/diffusion-pipe/.git ]; then
    echo "📥 Pulling latest diffusion-pipe..."
    git -C /app/diffusion-pipe reset --hard
    git -C /app/diffusion-pipe pull --ff-only || true
  else
    echo "📥 Cloning diffusion-pipe..."
    git clone https://github.com/tdrussell/diffusion-pipe.git /app/diffusion-pipe
  fi
else
  [ -d /app/diffusion-pipe ] || git clone https://github.com/tdrussell/diffusion-pipe.git /app/diffusion-pipe
fi

# --- optional HF auth ---
if [ -n "${HF_TOKEN}" ]; then
  hf_auth.sh "${HF_TOKEN}" || true
fi

# --- model fetch (if empty) ---
if [ -z "$(ls -A /workspace/modelsext 2>/dev/null || true)" ]; then
  get_models.sh "${MODEL_PRESET}" "${MODEL_URLS}" || true
fi

# --- services ---
jupyter lab       --ip=0.0.0.0 --port="${JUPYTER_PORT}"       --NotebookApp.token="${JUPYTER_TOKEN}" --NotebookApp.password=''       --NotebookApp.allow_origin='*' --no-browser       --ServerApp.terminado_settings='{"shell_command":["/bin/bash"]}' &

tensorboard --logdir "${TB_LOGDIR}" --host 0.0.0.0 --port "${TENSORBOARD_PORT}" &

echo "🚀 diffusion-pipe up"
echo "   Jupyter:     http://localhost:${JUPYTER_PORT}  (token: ${JUPYTER_TOKEN:-<none>})"
echo "   TensorBoard: http://localhost:${TENSORBOARD_PORT}  (logdir: ${TB_LOGDIR})"
echo "   Repo:        /app/diffusion-pipe"
echo "   Models:      /workspace/modelsext"
echo "   Preset:      ${MODEL_PRESET:-<none>}"

if [ "$#" -gt 0 ]; then
  exec "$@"
else
  tail -f /dev/null
fi
