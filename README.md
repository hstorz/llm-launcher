# llm launcher 
### (optimzed for RTX 4070 12 GB VRAM + 32 GB RAM + 128K Context)

Terminal llm launcher script for `llama-server` with pre-configured models and optimal settings for specific hardware. 
Picks a model via fzf (or Bash `select`), then launches it with tuned flags.


## Requirements

- [llama.cpp](https://github.com/ggml-org/llama.cpp) — build with `cmake -B build && cmake --build build --target llama-server`
- [fzf](https://github.com/junegunn/fzf) (optional — falls back to `select`)

## Usage

```bash
# Default port
./llm_launcher.sh

# Custom port
PORT=8081 ./llm_launcher.sh
```

Edit the `CONFIGS` array at the top of the script to add or modify models.

## Config format

```
Display Name|/path/to/model.gguf|ngl|ctx|kv_type|threads|extra_flags
```

Fields are pipe-separated. Extra flags are split on spaces automatically.

Example:

```
"My Model|/models/my-model.gguf|99|32768|q8_0|4|--no-warmup"
```

## Sample models (tested on RTX 4070 with evalscope speed benchmark)

| Model | Ctx | VRAM | Speed |
|-------|-----|------|-------|
| Gemma-4-12B (Q4_K_XL) | 128K | 6.2 GB | 56 t/s |
| Qwopus35B-A3B (IQ4_XS) | 128K | 6.2 GB | 40 t/s |
| Qwopus9B-Coder (Exp-IQ4_XS) | 128K | 6.7 GB | 78 t/s |
| North-Mini-Code-1.0 (UD-IQ1_M) | 128K | 8.7 GB | 53 t/s |

## Customization

| Env var | Default | Description |
|---------|---------|-------------|
| `PORT` | `8080` | Server port |
| `HOST` | `0.0.0.0` | Bind address (edit variable in script) |
| `MODELS_PATH` | `~/.cache/huggingface/hub` | HF cache root (edit variable in script) |
| `LLAMA_SERVER` | `~/Applications/llama.cpp/build/bin/llama-server` | Binary path (edit variable in script) |
