#!/usr/bin/env bash
set -euo pipefail

LLAMA_SERVER="$HOME/Applications/llama.cpp/build/bin/llama-server"
HOST="0.0.0.0"
PORT="${PORT:-8080}"

MODELS_PATH="$HOME/.cache/huggingface/hub"

# Format: name|model|ngl|ctx|kv|threads|extra_flags...
# extra_flags are split on spaces when building the command
CONFIGS=(
  # ⭐ Agentic coding — fastest MoE coder, 44 t/s at 128K, temperature=0.0
  "Qwopus35B-Coder-MTP (IQ4_XS)|$MODELS_PATH/models--Jackrong--Qwopus3.6-35B-A3B-Coder-MTP-GGUF/Qwopus3.6-35B-A3B-Coder-MTP-IQ4_XS.gguf|70|131072|q4_0|6|--n-cpu-moe 36"
  # General-purpose MoE MTP, same speed as coder (44 t/s)
  "Qwopus35B-A3B-MTP (Q4_K_M)|$MODELS_PATH/models--Jackrong--Qwopus3.6-35B-A3B-v1-MTP-GGUF/snapshots/fc4275aa78921179b28f8321c8502b252a7adbfe/Qwopus3.6-35B-A3B-v1-MTP-Q4_K_M.gguf|70|131072|q4_0|6|--n-cpu-moe 36"
  # Fallback MoE, good at 128K (40 t/s)
  "Qwopus35B-A3B-v1 (IQ4_XS)|$MODELS_PATH/models--Jackrong--Qwopus3.6-35B-A3B-v1-GGUF/snapshots/bd297a4fe8dd8f9987c2c7a5b1029834c9a76c3f/Qwopus3.6-35B-A3B-v1-IQ4_XS.gguf|70|131072|q4_0|6|--n-cpu-moe 36"
  # Small fast coder (78 t/s)
  "Qwopus9B-Coder (Exp-IQ4_XS)|$MODELS_PATH/models--Jackrong--Qwopus3.5-9B-Coder-GGUF/snapshots/b110611ae526cf4ed34af1d290054147639d0d5e/Qwopus3.5-9B-coder-Exp-IQ4_XS.gguf|99|131072|q4_0|4|"
  # Godot specialist — dense 27B, slow but domain-specific
  "Godoter-27B (Q4_K_S)|$MODELS_PATH/models--mradermacher--Godoter-27B-GGUF/blobs/06480d2997de0e9984929bd9e0dfc6638a2eca01ab2a6f6d8af419d935dc6b9c|38|32768|q4_0|6|"
  # Lightweight model (56 t/s)
  "Gemma-4-12B (Q4_K_XL)|$MODELS_PATH/models--unsloth--gemma-4-12B-it-qat-GGUF/snapshots/ceadd70e5c46c5a839a7fd622307dabe8fdea551/gemma-4-12B-it-qat-UD-Q4_K_XL.gguf|99|131072|q8_0|4|--reasoning-budget 0"
  # Ultra-compact code model (53 t/s)
  "North-Mini-Code-1.0 (UD-IQ1_M)|$MODELS_PATH/north-mini-code/North-Mini-Code-1.0-UD-IQ1_M.gguf|40|131072|q4_0|4|--jinja --reasoning off"
)

pick_model() {
  if command -v fzf &>/dev/null; then
    for cfg in "${CONFIGS[@]}"; do
      echo "${cfg%%|*}"
    done | fzf --height=14 --border --prompt="Select a model: " \
      --header='↑↓ navigate, Enter to confirm  |  Recommended: Qwopus35B-Coder-MTP (IQ4_XS) for agentic coding' --header-first
  else
    echo "Select a model:"
    select choice in "${CONFIGS[@]%%|*}"; do
      echo "$choice"
      break
    done
  fi
}

selected=$(pick_model)
[[ -z "$selected" ]] && echo "No model selected. Exiting." && exit 1

# Find matching config
cfg_line=""
for cfg in "${CONFIGS[@]}"; do
  if [[ "${cfg%%|*}" == "$selected" ]]; then
    cfg_line="$cfg"
    break
  fi
done

[[ -z "$cfg_line" ]] && echo "Config not found. Exiting." && exit 1

IFS='|' read -r name model ngl ctx kv threads extra <<< "$cfg_line"

echo "Selected: $name"
echo "Model:    $model"
echo "NGL:      $ngl"
echo "Context:  $ctx"
echo "KV cache: $kv"
echo "Threads:  $threads"
echo "Host:     $HOST:$PORT"
echo ""

CMD=("$LLAMA_SERVER"
  -m "$model"
  -ngl "$ngl"
  -t "$threads"
  -ctk "$kv"
  -ctv "$kv"
  -c "$ctx"
  --host "$HOST"
  --port "$PORT"
  -fa on
)

# Split extra flags on spaces into separate array elements
if [[ -n "$extra" ]]; then
  read -ra extra_arr <<< "$extra"
  CMD+=("${extra_arr[@]}")
fi

echo "Running: ${CMD[*]}"
echo ""

exec "${CMD[@]}"
