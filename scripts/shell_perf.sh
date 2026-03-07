#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_ROOT="${SHELL_PERF_ARTIFACT_ROOT:-$ROOT_DIR/.artifacts/shell-perf}"
DEFAULT_RUNS="${SHELL_PERF_RUNS:-20}"
DEFAULT_WARMUP="${SHELL_PERF_WARMUP:-3}"

log() {
  printf '[shell-perf] %s\n' "$*"
}

die() {
  printf '[shell-perf] ERROR: %s\n' "$*" >&2
  exit 1
}

ensure_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

usage() {
  cat <<'USAGE'
Usage:
  shell_perf.sh bench [--run-dir DIR] [--runs N] [--warmup N] [--cwd DIR] [--with-fast-mode]
  shell_perf.sh matrix [--run-dir DIR] [--runs N] [--warmup N] [--cwd DIR]
  shell_perf.sh bench-components [--run-dir DIR] [--runs N] [--warmup N] [--cwd DIR]
  shell_perf.sh profile [--run-dir DIR] [--zsh-mode warm|cold]
  shell_perf.sh report [--run-dir DIR]
  shell_perf.sh deep [--run-dir DIR] [--runs N] [--warmup N] [--cwd DIR] [--with-fast-mode]
  shell_perf.sh compare --before DIR --after DIR

Environment:
  SHELL_PERF_ARTIFACT_ROOT  Override artifact directory root.
  SHELL_PERF_RUNS           Default runs for bench/deep (default: 20).
  SHELL_PERF_WARMUP         Default warmup runs (default: 3).

Notes:
  - Artifacts are written under .artifacts/shell-perf by default.
  - Set MISE_STARTUP_MODE=fast and STARSHIP_PROFILE=fast to benchmark opt-in fast-mode startup behavior.
USAGE
}

new_run_dir() {
  local ts dir
  ts="$(date +%Y%m%d-%H%M%S)"
  dir="$ARTIFACT_ROOT/$ts"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

write_latest() {
  local run_dir="$1"
  mkdir -p "$ARTIFACT_ROOT"
  printf '%s\n' "$run_dir" > "$ARTIFACT_ROOT/latest"
}

read_latest() {
  local latest_file="$ARTIFACT_ROOT/latest"
  [[ -f "$latest_file" ]] || die "No latest run found at $latest_file"
  cat "$latest_file"
}

normalize_run_dir() {
  local run_dir="$1"
  if [[ -z "$run_dir" ]]; then
    run_dir="$(new_run_dir)"
  fi
  mkdir -p "$run_dir"
  printf '%s\n' "$run_dir"
}

read_meta_value() {
  local meta_file="$1"
  local key="$2"
  [[ -f "$meta_file" ]] || return 0
  awk -F= -v key="$key" '$1 == key { print $2; exit }' "$meta_file"
}

extract_hyperfine_mean() {
  local hyperfine_txt="$1"
  local bench_name="$2"
  gawk -v bench_name="$bench_name" '
    /^Benchmark [0-9]+:/ {
      in_block = index($0, bench_name) > 0
      next
    }
    in_block && /Time \(mean/ {
      if (match($0, /([0-9.]+)[[:space:]]*(us|µs|ms|s)[[:space:]]*±/, m)) {
        print m[1] " " m[2]
        exit
      }
    }
  ' "$hyperfine_txt"
}

extract_hyperfine_stddev() {
  local hyperfine_txt="$1"
  local bench_name="$2"
  gawk -v bench_name="$bench_name" '
    /^Benchmark [0-9]+:/ {
      in_block = index($0, bench_name) > 0
      next
    }
    in_block && /Time \(mean/ {
      if (match($0, /([0-9.]+)[[:space:]]*(us|µs|ms|s)[[:space:]]*±[[:space:]]*([0-9.]+)[[:space:]]*(us|µs|ms|s)/, m)) {
        print m[3] " " m[4]
        exit
      }
    }
  ' "$hyperfine_txt"
}

to_ms() {
  local raw="$1"
  local value unit
  value="${raw%% *}"
  unit="${raw#* }"
  case "$unit" in
    us|µs)
      awk -v v="$value" 'BEGIN { printf "%.3f", v / 1000 }'
      ;;
    ms)
      awk -v v="$value" 'BEGIN { printf "%.3f", v }'
      ;;
    s)
      awk -v v="$value" 'BEGIN { printf "%.3f", v * 1000 }'
      ;;
    *)
      printf ''
      ;;
  esac
}

calc_delta_ms() {
  local before_ms="$1"
  local after_ms="$2"
  awk -v b="$before_ms" -v a="$after_ms" 'BEGIN { printf "%.3f", a - b }'
}

calc_delta_pct() {
  local before_ms="$1"
  local after_ms="$2"
  awk -v b="$before_ms" -v a="$after_ms" 'BEGIN { if (b == 0) print "0.0"; else printf "%.1f", ((a - b) / b) * 100 }'
}

calc_cv_pct() {
  local mean_ms="$1"
  local stddev_ms="$2"
  awk -v mean="$mean_ms" -v stddev="$stddev_ms" 'BEGIN { if (mean == 0) print "0.0"; else printf "%.2f", (stddev / mean) * 100 }'
}

stability_band() {
  local cv_pct="$1"
  awk -v cv="$cv_pct" '
    BEGIN {
      if (cv < 3.0) {
        print "excellent"
      } else if (cv < 6.0) {
        print "good"
      } else if (cv < 10.0) {
        print "fair"
      } else {
        print "noisy"
      }
    }
  '
}

write_meta() {
  local run_dir="$1"
  local mode="$2"
  local runs="$3"
  local warmup="$4"
  local cwd="$5"
  cat > "$run_dir/meta.env" <<META
MODE=$mode
RUNS=$runs
WARMUP=$warmup
CWD=$cwd
GENERATED_AT=$(date -Is)
META
}

cmd_bench() {
  local run_dir=""
  local runs="$DEFAULT_RUNS"
  local warmup="$DEFAULT_WARMUP"
  local cwd="$ROOT_DIR"
  local with_fast_mode=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run-dir)
        run_dir="$2"
        shift 2
        ;;
      --runs)
        runs="$2"
        shift 2
        ;;
      --warmup)
        warmup="$2"
        shift 2
        ;;
      --cwd)
        cwd="$2"
        shift 2
        ;;
      --with-fast-mode)
        with_fast_mode=1
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        die "Unknown bench option: $1"
        ;;
    esac
  done

  ensure_cmd hyperfine
  ensure_cmd zsh
  ensure_cmd fish

  run_dir="$(normalize_run_dir "$run_dir")"
  local hyperfine_txt="$run_dir/hyperfine.txt"
  local hyperfine_json="$run_dir/hyperfine.json"

  local -a names=(
    "zsh-startup"
    "fish-startup"
  )
  local -a commands=(
    "zsh -i -c exit"
    "fish -i -c exit"
  )

  if (( with_fast_mode )); then
    names+=("zsh-startup-fast" "fish-startup-fast")
    commands+=("MISE_STARTUP_MODE=fast STARSHIP_PROFILE=fast zsh -i -c exit" "MISE_STARTUP_MODE=fast STARSHIP_PROFILE=fast fish -i -c exit")
  fi

  local -a hf_args=(
    --style basic
    --warmup "$warmup"
    --runs "$runs"
    --export-json "$hyperfine_json"
  )

  local name
  for name in "${names[@]}"; do
    hf_args+=(--command-name "$name")
  done

  log "Running startup benchmarks (runs=$runs warmup=$warmup, cwd=$cwd)"
  (
    cd "$cwd"
    hyperfine "${hf_args[@]}" "${commands[@]}"
  ) | tee "$hyperfine_txt"

  # Capture quick facility outputs if available; these are diagnostics only.
  fish -ic 'functions -q shell_bench; and shell_bench' > "$run_dir/fish-shell_bench.txt" 2>&1 || true
  zsh -ic 'alias bench >/dev/null 2>&1 && bench' > "$run_dir/zsh-bench-alias.txt" 2>&1 || true

  write_meta "$run_dir" "bench" "$runs" "$warmup" "$cwd"
  write_latest "$run_dir"

  log "Benchmark artifacts written to: $run_dir"
}

cmd_matrix() {
  local run_dir=""
  local runs="$DEFAULT_RUNS"
  local warmup="$DEFAULT_WARMUP"
  local cwd="$ROOT_DIR"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run-dir)
        run_dir="$2"
        shift 2
        ;;
      --runs)
        runs="$2"
        shift 2
        ;;
      --warmup)
        warmup="$2"
        shift 2
        ;;
      --cwd)
        cwd="$2"
        shift 2
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        die "Unknown matrix option: $1"
        ;;
    esac
  done

  ensure_cmd gawk

  run_dir="$(normalize_run_dir "$run_dir")"
  cmd_bench --run-dir "$run_dir" --runs "$runs" --warmup "$warmup" --cwd "$cwd" --with-fast-mode

  local hyperfine_txt="$run_dir/hyperfine.txt"
  [[ -f "$hyperfine_txt" ]] || die "Expected startup benchmark output at $hyperfine_txt"
  local matrix_md="$run_dir/matrix.md"

  local zsh_default="" fish_default="" zsh_fast="" fish_fast=""
  local zsh_default_std="" fish_default_std="" zsh_fast_std="" fish_fast_std=""
  local zsh_default_ms="" fish_default_ms="" zsh_fast_ms="" fish_fast_ms=""
  local zsh_default_std_ms="" fish_default_std_ms="" zsh_fast_std_ms="" fish_fast_std_ms=""
  local zsh_default_cv="" fish_default_cv="" zsh_fast_cv="" fish_fast_cv=""
  local zsh_default_band="" fish_default_band="" zsh_fast_band="" fish_fast_band=""

  zsh_default="$(extract_hyperfine_mean "$hyperfine_txt" "zsh-startup" || true)"
  fish_default="$(extract_hyperfine_mean "$hyperfine_txt" "fish-startup" || true)"
  zsh_fast="$(extract_hyperfine_mean "$hyperfine_txt" "zsh-startup-fast" || true)"
  fish_fast="$(extract_hyperfine_mean "$hyperfine_txt" "fish-startup-fast" || true)"

  zsh_default_std="$(extract_hyperfine_stddev "$hyperfine_txt" "zsh-startup" || true)"
  fish_default_std="$(extract_hyperfine_stddev "$hyperfine_txt" "fish-startup" || true)"
  zsh_fast_std="$(extract_hyperfine_stddev "$hyperfine_txt" "zsh-startup-fast" || true)"
  fish_fast_std="$(extract_hyperfine_stddev "$hyperfine_txt" "fish-startup-fast" || true)"

  [[ -n "$zsh_default" ]] && zsh_default_ms="$(to_ms "$zsh_default")"
  [[ -n "$fish_default" ]] && fish_default_ms="$(to_ms "$fish_default")"
  [[ -n "$zsh_fast" ]] && zsh_fast_ms="$(to_ms "$zsh_fast")"
  [[ -n "$fish_fast" ]] && fish_fast_ms="$(to_ms "$fish_fast")"

  [[ -n "$zsh_default_std" ]] && zsh_default_std_ms="$(to_ms "$zsh_default_std")"
  [[ -n "$fish_default_std" ]] && fish_default_std_ms="$(to_ms "$fish_default_std")"
  [[ -n "$zsh_fast_std" ]] && zsh_fast_std_ms="$(to_ms "$zsh_fast_std")"
  [[ -n "$fish_fast_std" ]] && fish_fast_std_ms="$(to_ms "$fish_fast_std")"

  [[ -n "$zsh_default_ms" && -n "$zsh_default_std_ms" ]] && zsh_default_cv="$(calc_cv_pct "$zsh_default_ms" "$zsh_default_std_ms")"
  [[ -n "$fish_default_ms" && -n "$fish_default_std_ms" ]] && fish_default_cv="$(calc_cv_pct "$fish_default_ms" "$fish_default_std_ms")"
  [[ -n "$zsh_fast_ms" && -n "$zsh_fast_std_ms" ]] && zsh_fast_cv="$(calc_cv_pct "$zsh_fast_ms" "$zsh_fast_std_ms")"
  [[ -n "$fish_fast_ms" && -n "$fish_fast_std_ms" ]] && fish_fast_cv="$(calc_cv_pct "$fish_fast_ms" "$fish_fast_std_ms")"

  [[ -n "$zsh_default_cv" ]] && zsh_default_band="$(stability_band "$zsh_default_cv")"
  [[ -n "$fish_default_cv" ]] && fish_default_band="$(stability_band "$fish_default_cv")"
  [[ -n "$zsh_fast_cv" ]] && zsh_fast_band="$(stability_band "$zsh_fast_cv")"
  [[ -n "$fish_fast_cv" ]] && fish_fast_band="$(stability_band "$fish_fast_cv")"

  local zsh_gain_ms="" zsh_gain_pct="" fish_gain_ms="" fish_gain_pct=""
  if [[ -n "$zsh_default_ms" && -n "$zsh_fast_ms" ]]; then
    zsh_gain_ms="$(awk -v d="$zsh_default_ms" -v f="$zsh_fast_ms" 'BEGIN { printf "%.3f", d - f }')"
    zsh_gain_pct="$(awk -v d="$zsh_default_ms" -v f="$zsh_fast_ms" 'BEGIN { if (d == 0) print "0.0"; else printf "%.1f", ((d - f) / d) * 100 }')"
  fi
  if [[ -n "$fish_default_ms" && -n "$fish_fast_ms" ]]; then
    fish_gain_ms="$(awk -v d="$fish_default_ms" -v f="$fish_fast_ms" 'BEGIN { printf "%.3f", d - f }')"
    fish_gain_pct="$(awk -v d="$fish_default_ms" -v f="$fish_fast_ms" 'BEGIN { if (d == 0) print "0.0"; else printf "%.1f", ((d - f) / d) * 100 }')"
  fi

  {
    printf '# Startup Mode Matrix\n\n'
    printf 'Run directory: `%s`\n\n' "$run_dir"
    printf 'Generated: `%s`\n\n' "$(date -Is)"
    printf '## Startup Stability\n\n'
    printf '| Benchmark | Mean (ms) | Stddev (ms) | CV (%%) | Stability |\n'
    printf '|---|---:|---:|---:|---|\n'
    [[ -n "$zsh_default_ms" ]] && printf '| zsh-startup | %s | %s | %s | %s |\n' "$zsh_default_ms" "$zsh_default_std_ms" "$zsh_default_cv" "$zsh_default_band"
    [[ -n "$fish_default_ms" ]] && printf '| fish-startup | %s | %s | %s | %s |\n' "$fish_default_ms" "$fish_default_std_ms" "$fish_default_cv" "$fish_default_band"
    [[ -n "$zsh_fast_ms" ]] && printf '| zsh-startup-fast | %s | %s | %s | %s |\n' "$zsh_fast_ms" "$zsh_fast_std_ms" "$zsh_fast_cv" "$zsh_fast_band"
    [[ -n "$fish_fast_ms" ]] && printf '| fish-startup-fast | %s | %s | %s | %s |\n' "$fish_fast_ms" "$fish_fast_std_ms" "$fish_fast_cv" "$fish_fast_band"
    printf '\n'
    printf '## Fast Mode Gains\n\n'
    printf '| Shell | Default (ms) | Fast (ms) | Gain (ms) | Gain (%%) |\n'
    printf '|---|---:|---:|---:|---:|\n'
    [[ -n "$zsh_gain_ms" ]] && printf '| zsh | %s | %s | %s | %s%% |\n' "$zsh_default_ms" "$zsh_fast_ms" "$zsh_gain_ms" "$zsh_gain_pct"
    [[ -n "$fish_gain_ms" ]] && printf '| fish | %s | %s | %s | %s%% |\n' "$fish_default_ms" "$fish_fast_ms" "$fish_gain_ms" "$fish_gain_pct"
  } > "$matrix_md"

  log "Startup matrix written to: $matrix_md"
  cat "$matrix_md"
}

cmd_bench_components() {
  local run_dir=""
  local runs="$DEFAULT_RUNS"
  local warmup="$DEFAULT_WARMUP"
  local cwd="$ROOT_DIR"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run-dir)
        run_dir="$2"
        shift 2
        ;;
      --runs)
        runs="$2"
        shift 2
        ;;
      --warmup)
        warmup="$2"
        shift 2
        ;;
      --cwd)
        cwd="$2"
        shift 2
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        die "Unknown bench-components option: $1"
        ;;
    esac
  done

  ensure_cmd hyperfine

  run_dir="$(normalize_run_dir "$run_dir")"
  local out_txt="$run_dir/components-hyperfine.txt"
  local out_json="$run_dir/components-hyperfine.json"
  local direct_txt="$run_dir/components-direct-hyperfine.txt"
  local shell_txt="$run_dir/components-shell-hyperfine.txt"
  local direct_json="$run_dir/components-direct-hyperfine.json"
  local shell_json="$run_dir/components-shell-hyperfine.json"

  local -a direct_names=()
  local -a direct_commands=()
  local -a shell_names=()
  local -a shell_commands=()
  local fzf_completion="${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/repos/github.com/junegunn/fzf/shell/completion.zsh"
  local fzf_bindings="${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/repos/github.com/junegunn/fzf/shell/key-bindings.zsh"
  local starship_fast_config="${XDG_CONFIG_HOME:-$HOME/.config}/starship-fast.toml"

  if [[ ! -r "$starship_fast_config" && -r "$ROOT_DIR/config/starship-fast.toml" ]]; then
    starship_fast_config="$ROOT_DIR/config/starship-fast.toml"
  fi

  if command -v sheldon >/dev/null 2>&1; then
    direct_names+=("component-sheldon-source")
    direct_commands+=("sheldon source")
  fi

  if [[ -r "$fzf_completion" && -r "$fzf_bindings" ]]; then
    shell_names+=("component-fzf-static-scripts")
    shell_commands+=("zsh -fc 'source \"$fzf_completion\"; source \"$fzf_bindings\"'")
  elif command -v fzf >/dev/null 2>&1; then
    direct_names+=("component-fzf-zsh-script")
    direct_commands+=("fzf --zsh")
  fi

  if command -v starship >/dev/null 2>&1; then
    direct_names+=("component-starship-prompt" "component-starship-right-prompt")
    direct_commands+=("starship prompt" "starship prompt --right")
    if [[ -r "$starship_fast_config" ]]; then
      local starship_fast_config_q
      printf -v starship_fast_config_q '%q' "$starship_fast_config"
      direct_names+=("component-starship-prompt-fast")
      direct_commands+=("env STARSHIP_PROFILE=fast STARSHIP_CONFIG=$starship_fast_config_q starship prompt")
    fi
  fi

  if command -v mise >/dev/null 2>&1; then
    direct_names+=("component-mise-hook-env-zsh" "component-mise-hook-env-fish")
    direct_commands+=("mise hook-env -s zsh" "mise hook-env -s fish")
  fi

  (( ${#direct_names[@]} > 0 || ${#shell_names[@]} > 0 )) || die "No component benchmarks available in current PATH"

  : > "$out_txt"
  local ran_direct=0
  local ran_shell=0

  if (( ${#direct_names[@]} > 0 )); then
    local -a hf_args_direct=(
      --style basic
      --warmup "$warmup"
      --runs "$runs"
      --shell none
      --export-json "$direct_json"
    )

    local name
    for name in "${direct_names[@]}"; do
      hf_args_direct+=(--command-name "$name")
    done

    log "Running direct component benchmarks (runs=$runs warmup=$warmup, cwd=$cwd, shell=none)"
    (
      cd "$cwd"
      hyperfine "${hf_args_direct[@]}" "${direct_commands[@]}"
    ) | tee "$direct_txt"

    cat "$direct_txt" >> "$out_txt"
    ran_direct=1
  fi

  if (( ${#shell_names[@]} > 0 )); then
    local -a hf_args_shell=(
      --style basic
      --warmup "$warmup"
      --runs "$runs"
      --export-json "$shell_json"
    )

    local name
    for name in "${shell_names[@]}"; do
      hf_args_shell+=(--command-name "$name")
    done

    log "Running shell component benchmarks (runs=$runs warmup=$warmup, cwd=$cwd, shell=default)"
    (
      cd "$cwd"
      hyperfine "${hf_args_shell[@]}" "${shell_commands[@]}"
    ) | tee "$shell_txt"

    if [[ -s "$out_txt" ]]; then
      printf '\n' >> "$out_txt"
    fi
    cat "$shell_txt" >> "$out_txt"
    ran_shell=1
  fi

  if (( ran_direct == 1 && ran_shell == 0 )); then
    cp "$direct_json" "$out_json"
  elif (( ran_direct == 0 && ran_shell == 1 )); then
    cp "$shell_json" "$out_json"
  else
    cat > "$out_json" <<JSON
{"direct_json":"$(basename "$direct_json")","shell_json":"$(basename "$shell_json")"}
JSON
  fi

  if command -v starship >/dev/null 2>&1; then
    (
      cd "$cwd"
      STARSHIP_LOG=trace starship timings
    ) > "$run_dir/starship-timings.txt" 2>&1 || true
  fi

  write_meta "$run_dir" "bench-components" "$runs" "$warmup" "$cwd"
  write_latest "$run_dir"
  log "Component benchmark artifacts written to: $run_dir"
}

cmd_profile() {
  local run_dir=""
  local zsh_mode="warm"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run-dir)
        run_dir="$2"
        shift 2
        ;;
      --zsh-mode)
        zsh_mode="$2"
        shift 2
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        die "Unknown profile option: $1"
        ;;
    esac
  done

  case "$zsh_mode" in
    warm|cold)
      ;;
    *)
      die "Invalid --zsh-mode: $zsh_mode (expected warm or cold)"
      ;;
  esac

  ensure_cmd fish
  ensure_cmd zsh

  run_dir="$(normalize_run_dir "$run_dir")"

  local fish_prof="$run_dir/fish-startup.prof"
  local fish_prof_sorted="$run_dir/fish-startup.sorted.prof"
  local zprof_txt="$run_dir/zsh-zprof.txt"

  log "Collecting fish startup profile"
  fish --profile-startup "$fish_prof" -i -c exit >/dev/null 2>&1
  sort -nr "$fish_prof" > "$fish_prof_sorted"

  log "Collecting zsh zprof profile"
  local tmpdir
  tmpdir="$(mktemp -d)"
  cat > "$tmpdir/.zshenv" <<ZSHENV
source "$ROOT_DIR/.zshenv"
ZSHENV
  cat > "$tmpdir/.zshrc" <<ZSHRC
zmodload zsh/zprof
source "$ROOT_DIR/.zshrc"
zprof
ZSHRC

  if [[ "$zsh_mode" == "warm" ]]; then
    local source_zcompdump="${HOME}/.zcompdump"
    if [[ -f "$source_zcompdump" ]]; then
      cp "$source_zcompdump" "$tmpdir/.zcompdump"
    else
      log "Warm zsh profile requested but $source_zcompdump was not found; falling back to cold behavior"
    fi
  fi

  ZDOTDIR="$tmpdir" zsh -i -c exit > "$zprof_txt" 2>&1 || true
  rm -rf "$tmpdir"

  write_meta "$run_dir" "profile" "$DEFAULT_RUNS" "$DEFAULT_WARMUP" "$ROOT_DIR"
  printf 'ZSH_PROFILE_MODE=%s\n' "$zsh_mode" >> "$run_dir/meta.env"
  write_latest "$run_dir"
  log "Profile artifacts written to: $run_dir"
}

cmd_report() {
  local run_dir=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run-dir)
        run_dir="$2"
        shift 2
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        die "Unknown report option: $1"
        ;;
    esac
  done

  ensure_cmd gawk

  if [[ -z "$run_dir" ]]; then
    run_dir="$(read_latest)"
  fi
  [[ -d "$run_dir" ]] || die "Run directory not found: $run_dir"

  local report_md="$run_dir/report.md"
  local hyperfine_txt="$run_dir/hyperfine.txt"
  local components_txt="$run_dir/components-hyperfine.txt"
  local fish_prof_sorted="$run_dir/fish-startup.sorted.prof"
  local zprof_txt="$run_dir/zsh-zprof.txt"
  local starship_timings_txt="$run_dir/starship-timings.txt"
  local meta_file="$run_dir/meta.env"
  local zsh_profile_mode
  zsh_profile_mode="$(read_meta_value "$meta_file" "ZSH_PROFILE_MODE")"

  local zsh_default=""
  local fish_default=""
  local zsh_fast=""
  local fish_fast=""
  local zsh_default_std=""
  local fish_default_std=""
  local zsh_fast_std=""
  local fish_fast_std=""
  local zsh_default_ms=""
  local fish_default_ms=""
  local zsh_fast_ms=""
  local fish_fast_ms=""
  local zsh_default_std_ms=""
  local fish_default_std_ms=""
  local zsh_fast_std_ms=""
  local fish_fast_std_ms=""
  local zsh_default_cv=""
  local fish_default_cv=""
  local zsh_fast_cv=""
  local fish_fast_cv=""
  local zsh_default_stability=""
  local fish_default_stability=""
  local zsh_fast_stability=""
  local fish_fast_stability=""
  local comp_sheldon=""
  local comp_fzf_static=""
  local comp_fzf_zsh=""
  local comp_starship=""
  local comp_starship_right=""
  local comp_starship_fast=""
  local comp_mise_hook_zsh=""
  local comp_mise_hook_fish=""
  local comp_sheldon_std=""
  local comp_fzf_static_std=""
  local comp_fzf_zsh_std=""
  local comp_starship_std=""
  local comp_starship_right_std=""
  local comp_starship_fast_std=""
  local comp_mise_hook_zsh_std=""
  local comp_mise_hook_fish_std=""
  local comp_sheldon_ms=""
  local comp_fzf_static_ms=""
  local comp_fzf_zsh_ms=""
  local comp_starship_ms=""
  local comp_starship_right_ms=""
  local comp_starship_fast_ms=""
  local comp_mise_hook_zsh_ms=""
  local comp_mise_hook_fish_ms=""
  local comp_sheldon_std_ms=""
  local comp_fzf_static_std_ms=""
  local comp_fzf_zsh_std_ms=""
  local comp_starship_std_ms=""
  local comp_starship_right_std_ms=""
  local comp_starship_fast_std_ms=""
  local comp_mise_hook_zsh_std_ms=""
  local comp_mise_hook_fish_std_ms=""
  local comp_sheldon_cv=""
  local comp_fzf_static_cv=""
  local comp_fzf_zsh_cv=""
  local comp_starship_cv=""
  local comp_starship_right_cv=""
  local comp_starship_fast_cv=""
  local comp_mise_hook_zsh_cv=""
  local comp_mise_hook_fish_cv=""
  local comp_sheldon_stability=""
  local comp_fzf_static_stability=""
  local comp_fzf_zsh_stability=""
  local comp_starship_stability=""
  local comp_starship_right_stability=""
  local comp_starship_fast_stability=""
  local comp_mise_hook_zsh_stability=""
  local comp_mise_hook_fish_stability=""

  if [[ -f "$hyperfine_txt" ]]; then
    zsh_default="$(extract_hyperfine_mean "$hyperfine_txt" "zsh-startup" || true)"
    fish_default="$(extract_hyperfine_mean "$hyperfine_txt" "fish-startup" || true)"
    zsh_fast="$(extract_hyperfine_mean "$hyperfine_txt" "zsh-startup-fast" || true)"
    fish_fast="$(extract_hyperfine_mean "$hyperfine_txt" "fish-startup-fast" || true)"
    zsh_default_std="$(extract_hyperfine_stddev "$hyperfine_txt" "zsh-startup" || true)"
    fish_default_std="$(extract_hyperfine_stddev "$hyperfine_txt" "fish-startup" || true)"
    zsh_fast_std="$(extract_hyperfine_stddev "$hyperfine_txt" "zsh-startup-fast" || true)"
    fish_fast_std="$(extract_hyperfine_stddev "$hyperfine_txt" "fish-startup-fast" || true)"
    [[ -n "$zsh_default" ]] && zsh_default_ms="$(to_ms "$zsh_default")"
    [[ -n "$fish_default" ]] && fish_default_ms="$(to_ms "$fish_default")"
    [[ -n "$zsh_fast" ]] && zsh_fast_ms="$(to_ms "$zsh_fast")"
    [[ -n "$fish_fast" ]] && fish_fast_ms="$(to_ms "$fish_fast")"
    [[ -n "$zsh_default_std" ]] && zsh_default_std_ms="$(to_ms "$zsh_default_std")"
    [[ -n "$fish_default_std" ]] && fish_default_std_ms="$(to_ms "$fish_default_std")"
    [[ -n "$zsh_fast_std" ]] && zsh_fast_std_ms="$(to_ms "$zsh_fast_std")"
    [[ -n "$fish_fast_std" ]] && fish_fast_std_ms="$(to_ms "$fish_fast_std")"
    [[ -n "$zsh_default_ms" && -n "$zsh_default_std_ms" ]] && zsh_default_cv="$(calc_cv_pct "$zsh_default_ms" "$zsh_default_std_ms")"
    [[ -n "$fish_default_ms" && -n "$fish_default_std_ms" ]] && fish_default_cv="$(calc_cv_pct "$fish_default_ms" "$fish_default_std_ms")"
    [[ -n "$zsh_fast_ms" && -n "$zsh_fast_std_ms" ]] && zsh_fast_cv="$(calc_cv_pct "$zsh_fast_ms" "$zsh_fast_std_ms")"
    [[ -n "$fish_fast_ms" && -n "$fish_fast_std_ms" ]] && fish_fast_cv="$(calc_cv_pct "$fish_fast_ms" "$fish_fast_std_ms")"
    [[ -n "$zsh_default_cv" ]] && zsh_default_stability="$(stability_band "$zsh_default_cv")"
    [[ -n "$fish_default_cv" ]] && fish_default_stability="$(stability_band "$fish_default_cv")"
    [[ -n "$zsh_fast_cv" ]] && zsh_fast_stability="$(stability_band "$zsh_fast_cv")"
    [[ -n "$fish_fast_cv" ]] && fish_fast_stability="$(stability_band "$fish_fast_cv")"
  fi

  if [[ -f "$components_txt" ]]; then
    comp_sheldon="$(extract_hyperfine_mean "$components_txt" "component-sheldon-source" || true)"
    comp_fzf_static="$(extract_hyperfine_mean "$components_txt" "component-fzf-static-scripts" || true)"
    comp_fzf_zsh="$(extract_hyperfine_mean "$components_txt" "component-fzf-zsh-script" || true)"
    comp_starship="$(extract_hyperfine_mean "$components_txt" "component-starship-prompt" || true)"
    comp_starship_right="$(extract_hyperfine_mean "$components_txt" "component-starship-right-prompt" || true)"
    comp_starship_fast="$(extract_hyperfine_mean "$components_txt" "component-starship-prompt-fast" || true)"
    comp_mise_hook_zsh="$(extract_hyperfine_mean "$components_txt" "component-mise-hook-env-zsh" || true)"
    comp_mise_hook_fish="$(extract_hyperfine_mean "$components_txt" "component-mise-hook-env-fish" || true)"
    comp_sheldon_std="$(extract_hyperfine_stddev "$components_txt" "component-sheldon-source" || true)"
    comp_fzf_static_std="$(extract_hyperfine_stddev "$components_txt" "component-fzf-static-scripts" || true)"
    comp_fzf_zsh_std="$(extract_hyperfine_stddev "$components_txt" "component-fzf-zsh-script" || true)"
    comp_starship_std="$(extract_hyperfine_stddev "$components_txt" "component-starship-prompt" || true)"
    comp_starship_right_std="$(extract_hyperfine_stddev "$components_txt" "component-starship-right-prompt" || true)"
    comp_starship_fast_std="$(extract_hyperfine_stddev "$components_txt" "component-starship-prompt-fast" || true)"
    comp_mise_hook_zsh_std="$(extract_hyperfine_stddev "$components_txt" "component-mise-hook-env-zsh" || true)"
    comp_mise_hook_fish_std="$(extract_hyperfine_stddev "$components_txt" "component-mise-hook-env-fish" || true)"
    [[ -n "$comp_sheldon" ]] && comp_sheldon_ms="$(to_ms "$comp_sheldon")"
    [[ -n "$comp_fzf_static" ]] && comp_fzf_static_ms="$(to_ms "$comp_fzf_static")"
    [[ -n "$comp_fzf_zsh" ]] && comp_fzf_zsh_ms="$(to_ms "$comp_fzf_zsh")"
    [[ -n "$comp_starship" ]] && comp_starship_ms="$(to_ms "$comp_starship")"
    [[ -n "$comp_starship_right" ]] && comp_starship_right_ms="$(to_ms "$comp_starship_right")"
    [[ -n "$comp_starship_fast" ]] && comp_starship_fast_ms="$(to_ms "$comp_starship_fast")"
    [[ -n "$comp_mise_hook_zsh" ]] && comp_mise_hook_zsh_ms="$(to_ms "$comp_mise_hook_zsh")"
    [[ -n "$comp_mise_hook_fish" ]] && comp_mise_hook_fish_ms="$(to_ms "$comp_mise_hook_fish")"
    [[ -n "$comp_sheldon_std" ]] && comp_sheldon_std_ms="$(to_ms "$comp_sheldon_std")"
    [[ -n "$comp_fzf_static_std" ]] && comp_fzf_static_std_ms="$(to_ms "$comp_fzf_static_std")"
    [[ -n "$comp_fzf_zsh_std" ]] && comp_fzf_zsh_std_ms="$(to_ms "$comp_fzf_zsh_std")"
    [[ -n "$comp_starship_std" ]] && comp_starship_std_ms="$(to_ms "$comp_starship_std")"
    [[ -n "$comp_starship_right_std" ]] && comp_starship_right_std_ms="$(to_ms "$comp_starship_right_std")"
    [[ -n "$comp_starship_fast_std" ]] && comp_starship_fast_std_ms="$(to_ms "$comp_starship_fast_std")"
    [[ -n "$comp_mise_hook_zsh_std" ]] && comp_mise_hook_zsh_std_ms="$(to_ms "$comp_mise_hook_zsh_std")"
    [[ -n "$comp_mise_hook_fish_std" ]] && comp_mise_hook_fish_std_ms="$(to_ms "$comp_mise_hook_fish_std")"
    [[ -n "$comp_sheldon_ms" && -n "$comp_sheldon_std_ms" ]] && comp_sheldon_cv="$(calc_cv_pct "$comp_sheldon_ms" "$comp_sheldon_std_ms")"
    [[ -n "$comp_fzf_static_ms" && -n "$comp_fzf_static_std_ms" ]] && comp_fzf_static_cv="$(calc_cv_pct "$comp_fzf_static_ms" "$comp_fzf_static_std_ms")"
    [[ -n "$comp_fzf_zsh_ms" && -n "$comp_fzf_zsh_std_ms" ]] && comp_fzf_zsh_cv="$(calc_cv_pct "$comp_fzf_zsh_ms" "$comp_fzf_zsh_std_ms")"
    [[ -n "$comp_starship_ms" && -n "$comp_starship_std_ms" ]] && comp_starship_cv="$(calc_cv_pct "$comp_starship_ms" "$comp_starship_std_ms")"
    [[ -n "$comp_starship_right_ms" && -n "$comp_starship_right_std_ms" ]] && comp_starship_right_cv="$(calc_cv_pct "$comp_starship_right_ms" "$comp_starship_right_std_ms")"
    [[ -n "$comp_starship_fast_ms" && -n "$comp_starship_fast_std_ms" ]] && comp_starship_fast_cv="$(calc_cv_pct "$comp_starship_fast_ms" "$comp_starship_fast_std_ms")"
    [[ -n "$comp_mise_hook_zsh_ms" && -n "$comp_mise_hook_zsh_std_ms" ]] && comp_mise_hook_zsh_cv="$(calc_cv_pct "$comp_mise_hook_zsh_ms" "$comp_mise_hook_zsh_std_ms")"
    [[ -n "$comp_mise_hook_fish_ms" && -n "$comp_mise_hook_fish_std_ms" ]] && comp_mise_hook_fish_cv="$(calc_cv_pct "$comp_mise_hook_fish_ms" "$comp_mise_hook_fish_std_ms")"
    [[ -n "$comp_sheldon_cv" ]] && comp_sheldon_stability="$(stability_band "$comp_sheldon_cv")"
    [[ -n "$comp_fzf_static_cv" ]] && comp_fzf_static_stability="$(stability_band "$comp_fzf_static_cv")"
    [[ -n "$comp_fzf_zsh_cv" ]] && comp_fzf_zsh_stability="$(stability_band "$comp_fzf_zsh_cv")"
    [[ -n "$comp_starship_cv" ]] && comp_starship_stability="$(stability_band "$comp_starship_cv")"
    [[ -n "$comp_starship_right_cv" ]] && comp_starship_right_stability="$(stability_band "$comp_starship_right_cv")"
    [[ -n "$comp_starship_fast_cv" ]] && comp_starship_fast_stability="$(stability_band "$comp_starship_fast_cv")"
    [[ -n "$comp_mise_hook_zsh_cv" ]] && comp_mise_hook_zsh_stability="$(stability_band "$comp_mise_hook_zsh_cv")"
    [[ -n "$comp_mise_hook_fish_cv" ]] && comp_mise_hook_fish_stability="$(stability_band "$comp_mise_hook_fish_cv")"
  fi

  {
    printf '# Shell Performance Report\n\n'
    printf 'Run directory: `%s`\n\n' "$run_dir"
    printf 'Generated: `%s`\n\n' "$(date -Is)"

    printf '## Startup Benchmarks\n\n'
    if [[ -f "$hyperfine_txt" ]]; then
      printf '| Benchmark | Mean | Mean (ms) | Stddev (ms) | CV (%%) | Stability |\n'
      printf '|---|---:|---:|---:|---:|---|\n'
      [[ -n "$zsh_default" ]] && printf '| zsh-startup | %s | %s | %s | %s | %s |\n' "$zsh_default" "$zsh_default_ms" "$zsh_default_std_ms" "$zsh_default_cv" "$zsh_default_stability"
      [[ -n "$fish_default" ]] && printf '| fish-startup | %s | %s | %s | %s | %s |\n' "$fish_default" "$fish_default_ms" "$fish_default_std_ms" "$fish_default_cv" "$fish_default_stability"
      [[ -n "$zsh_fast" ]] && printf '| zsh-startup-fast | %s | %s | %s | %s | %s |\n' "$zsh_fast" "$zsh_fast_ms" "$zsh_fast_std_ms" "$zsh_fast_cv" "$zsh_fast_stability"
      [[ -n "$fish_fast" ]] && printf '| fish-startup-fast | %s | %s | %s | %s | %s |\n' "$fish_fast" "$fish_fast_ms" "$fish_fast_std_ms" "$fish_fast_cv" "$fish_fast_stability"
      printf '\n'
    else
      printf '_No hyperfine output found in this run._\n\n'
    fi

    printf '## Component Benchmarks\n\n'
    if [[ -f "$components_txt" ]]; then
      printf '_Direct commands are measured with `hyperfine --shell=none` where possible to reduce shell wrapper noise._\n\n'
      printf '| Component | Mean | Mean (ms) | Stddev (ms) | CV (%%) | Stability |\n'
      printf '|---|---:|---:|---:|---:|---|\n'
      [[ -n "$comp_sheldon" ]] && printf '| component-sheldon-source | %s | %s | %s | %s | %s |\n' "$comp_sheldon" "$comp_sheldon_ms" "$comp_sheldon_std_ms" "$comp_sheldon_cv" "$comp_sheldon_stability"
      [[ -n "$comp_fzf_static" ]] && printf '| component-fzf-static-scripts | %s | %s | %s | %s | %s |\n' "$comp_fzf_static" "$comp_fzf_static_ms" "$comp_fzf_static_std_ms" "$comp_fzf_static_cv" "$comp_fzf_static_stability"
      [[ -n "$comp_fzf_zsh" ]] && printf '| component-fzf-zsh-script | %s | %s | %s | %s | %s |\n' "$comp_fzf_zsh" "$comp_fzf_zsh_ms" "$comp_fzf_zsh_std_ms" "$comp_fzf_zsh_cv" "$comp_fzf_zsh_stability"
      [[ -n "$comp_starship" ]] && printf '| component-starship-prompt | %s | %s | %s | %s | %s |\n' "$comp_starship" "$comp_starship_ms" "$comp_starship_std_ms" "$comp_starship_cv" "$comp_starship_stability"
      [[ -n "$comp_starship_right" ]] && printf '| component-starship-right-prompt | %s | %s | %s | %s | %s |\n' "$comp_starship_right" "$comp_starship_right_ms" "$comp_starship_right_std_ms" "$comp_starship_right_cv" "$comp_starship_right_stability"
      [[ -n "$comp_starship_fast" ]] && printf '| component-starship-prompt-fast | %s | %s | %s | %s | %s |\n' "$comp_starship_fast" "$comp_starship_fast_ms" "$comp_starship_fast_std_ms" "$comp_starship_fast_cv" "$comp_starship_fast_stability"
      [[ -n "$comp_mise_hook_zsh" ]] && printf '| component-mise-hook-env-zsh | %s | %s | %s | %s | %s |\n' "$comp_mise_hook_zsh" "$comp_mise_hook_zsh_ms" "$comp_mise_hook_zsh_std_ms" "$comp_mise_hook_zsh_cv" "$comp_mise_hook_zsh_stability"
      [[ -n "$comp_mise_hook_fish" ]] && printf '| component-mise-hook-env-fish | %s | %s | %s | %s | %s |\n' "$comp_mise_hook_fish" "$comp_mise_hook_fish_ms" "$comp_mise_hook_fish_std_ms" "$comp_mise_hook_fish_cv" "$comp_mise_hook_fish_stability"
      printf '\n'
    else
      printf '_No component benchmark output found in this run._\n\n'
    fi

    printf '## Top Fish Startup Hotspots\n\n'
    if [[ -f "$fish_prof_sorted" ]]; then
      printf '```text\n'
      awk '
        NR==1 { next }
        {
          cmd = $0
          sub(/^[[:space:]]*[0-9]+[[:space:]]+[0-9]+[[:space:]]+/, "", cmd)
          printf "%8.3f ms | %s\n", $1 / 1000, cmd
          if (++c >= 10) exit
        }
      ' "$fish_prof_sorted"
      printf '```\n\n'
    else
      printf '_No fish startup profile found in this run._\n\n'
    fi

    printf '## Top Zsh Hotspots (zprof)\n\n'
    if [[ -n "$zsh_profile_mode" ]]; then
      printf 'zsh profile mode: `%s`\n\n' "$zsh_profile_mode"
    fi
    if [[ -f "$zprof_txt" ]]; then
      printf '```text\n'
      awk '
        /^[[:space:]]*[0-9]+\)/ {
          gsub(/^[[:space:]]+/, "", $0)
          print
          if (++c >= 10) exit
        }
      ' "$zprof_txt"
      printf '```\n\n'
    else
      printf '_No zprof output found in this run._\n\n'
    fi

    printf '## Starship Timings (Ownership)\n\n'
    if [[ -f "$starship_timings_txt" ]]; then
      printf '```text\n'
      awk '/^[[:space:]]*[a-z0-9_:-]+[[:space:]]+-[[:space:]]+[0-9]+/ {print; if (++c >= 8) exit}' "$starship_timings_txt"
      printf '```\n\n'
    else
      printf '_No starship timings output found in this run._\n\n'
    fi

    printf '## Bottlenecks and Improvements\n\n'
    local any=0

    if [[ -f "$zprof_txt" ]] && grep -Eq 'compinit|compdump|compdef' "$zprof_txt"; then
      any=1
      printf '%s\n' '- zsh completion initialization is a major hotspot (`compinit`/`compdump`/`compdef`).'
      printf '%s\n' '- Improvement: prefer cached `compinit -C` on most startups, with explicit periodic full refresh.'
    fi

    if [[ -f "$zprof_txt" ]] && grep -Eq '_mise_hook|mise activate zsh' "$zprof_txt"; then
      any=1
      printf '%s\n' '- zsh mise activation contributes meaningful startup cost.'
      printf '%s\n' '- Improvement: keep default behavior, and benchmark optional `MISE_STARTUP_MODE=fast` (`--no-hook-env`) for opt-in speed mode.'
    fi

    if [[ -f "$zprof_txt" ]] && grep -Eq '_evalcache' "$zprof_txt"; then
      any=1
      printf '%s\n' '- zsh startup still shows `_evalcache` wrapper overhead.'
      printf '%s\n' '- Improvement: prefer direct signature-cached init for deterministic activation code paths.'
    elif [[ -f "$zprof_txt" ]] && grep -Eq '_mise_hook' "$zprof_txt"; then
      any=1
      printf '%s\n' '- zsh startup no longer shows `_evalcache`; remaining mise cost is now concentrated in `_mise_hook`.'
      printf '%s\n' '- Improvement: keep current cache path and tune hook frequency (`MISE_HOOK_ENV_*`) for additional wins.'
    fi

    if [[ -f "$fish_prof_sorted" ]] && grep -Eq 'mise hook-env|command mise|mise activate fish' "$fish_prof_sorted"; then
      any=1
      printf '%s\n' '- fish mise activation/hook environment updates are a primary startup bottleneck.'
      printf '%s\n' '- Improvement: keep defaults, and use opt-in `MISE_STARTUP_MODE=fast` in latency-sensitive contexts.'
    fi

    if [[ -f "$fish_prof_sorted" ]] && grep -Eq 'git rev-parse --show-toplevel|__auto_source_venv' "$fish_prof_sorted"; then
      any=1
      printf '%s\n' '- fish virtualenv auto-detection does git-root probing on startup.'
      printf '%s\n' '- Improvement: use a single git root probe per hook invocation and avoid repeated repository resolution.'
    fi

    if [[ -f "$zprof_txt" ]] && grep -Eq '_add_identities' "$zprof_txt"; then
      any=1
      printf '%s\n' '- zsh ssh-agent identity loading appears in startup hotspots (`_add_identities`).'
      printf '%s\n' '- Improvement: constrain startup identities via `zstyle :omz:plugins:ssh-agent identities ...`.'
    fi

    if [[ -f "$fish_prof_sorted" ]] && grep -Eq 'keychain --eval' "$fish_prof_sorted"; then
      any=1
      printf '%s\n' '- keychain startup invocation adds avoidable startup latency when agent vars are already valid.'
      printf '%s\n' '- Improvement: gate keychain execution on missing/invalid `SSH_AUTH_SOCK`.'
    fi

    if [[ -f "$fish_prof_sorted" ]] && grep -Eq 'poetry|command -s poetry|poetry env info -p' "$fish_prof_sorted"; then
      any=1
      printf '%s\n' '- poetry detection/activation checks appear in fish startup hotspots.'
      printf '%s\n' '- Improvement: avoid global startup command lookups; perform poetry checks only in poetry project contexts.'
    fi

    if [[ -n "$comp_starship_ms" ]] && awk -v ms="$comp_starship_ms" 'BEGIN {exit !(ms >= 10)}'; then
      any=1
      printf '%s\n' '- starship prompt rendering is a significant startup component in repository paths.'
      printf '%s\n' '- Improvement: keep default prompt, and use optional fast prompt profile that disables heavy modules (for example `git_status`) when needed.'
    fi

    if [[ -n "$comp_starship_ms" && -n "$comp_starship_fast_ms" ]]; then
      local starship_fast_delta starship_fast_pct
      starship_fast_delta="$(awk -v d="$comp_starship_ms" -v f="$comp_starship_fast_ms" 'BEGIN { printf "%.3f", d - f }')"
      starship_fast_pct="$(awk -v d="$comp_starship_ms" -v f="$comp_starship_fast_ms" 'BEGIN { if (d == 0) print "0.0"; else printf "%.1f", ((d - f) / d) * 100 }')"
      any=1
      printf '%s\n' "- measured starship fast profile gain: ${starship_fast_delta} ms (${starship_fast_pct}%) for \`starship prompt\`."
      printf '%s\n' '- Improvement: set `STARSHIP_PROFILE=fast` in latency-sensitive shells; default profile remains unchanged.'
    fi

    if [[ -n "$comp_mise_hook_fish_ms" ]] && awk -v ms="$comp_mise_hook_fish_ms" 'BEGIN {exit !(ms >= 20)}'; then
      any=1
      printf '%s\n' '- fish `mise hook-env` is a major startup cost center under current configuration.'
      printf '%s\n' '- Improvement: keep default behavior and use opt-in fast mode (`MISE_STARTUP_MODE=fast`) for latency-sensitive workflows.'
    fi

    if (( any == 0 )); then
      printf '%s\n' '- No major known bottleneck signatures matched. Inspect the top hotspot tables above for run-specific optimization opportunities.'
    fi

    printf '\n## Existing Quick Facilities\n\n'
    printf '%s\n' '- Fish cross-shell benchmark function: `shell_bench` in `config/fish/functions/shell_bench.fish`.'
    printf '%s\n' '- Fish-only startup benchmark function: `bench` in `config/fish/functions/bench.fish`.'
    printf '%s\n' '- Zsh startup benchmark alias: `bench` in `.zshrc`.'
  } > "$report_md"

  log "Report written to: $report_md"
  cat "$report_md"
}

cmd_deep() {
  local run_dir=""
  local runs="$DEFAULT_RUNS"
  local warmup="$DEFAULT_WARMUP"
  local cwd="$ROOT_DIR"
  local with_fast_mode=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --run-dir)
        run_dir="$2"
        shift 2
        ;;
      --runs)
        runs="$2"
        shift 2
        ;;
      --warmup)
        warmup="$2"
        shift 2
        ;;
      --cwd)
        cwd="$2"
        shift 2
        ;;
      --with-fast-mode)
        with_fast_mode=1
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        die "Unknown deep option: $1"
        ;;
    esac
  done

  run_dir="$(normalize_run_dir "$run_dir")"

  local -a bench_args=(--run-dir "$run_dir" --runs "$runs" --warmup "$warmup" --cwd "$cwd")
  if (( with_fast_mode )); then
    bench_args+=(--with-fast-mode)
  fi

  cmd_bench "${bench_args[@]}"
  cmd_bench_components --run-dir "$run_dir" --runs "$runs" --warmup "$warmup" --cwd "$cwd"
  cmd_profile --run-dir "$run_dir"
  cmd_report --run-dir "$run_dir"
}

cmd_compare() {
  local before=""
  local after=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --before)
        before="$2"
        shift 2
        ;;
      --after)
        after="$2"
        shift 2
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        die "Unknown compare option: $1"
        ;;
    esac
  done

  ensure_cmd gawk
  [[ -n "$before" && -n "$after" ]] || die "compare requires --before DIR and --after DIR"

  local before_txt="$before/hyperfine.txt"
  local after_txt="$after/hyperfine.txt"
  [[ -f "$before_txt" ]] || die "Missing before hyperfine.txt: $before_txt"
  [[ -f "$after_txt" ]] || die "Missing after hyperfine.txt: $after_txt"

  local out_md="$after/compare.md"

  {
    printf '# Startup Benchmark Comparison\n\n'
    printf 'Before: `%s`\n\n' "$before"
    printf 'After: `%s`\n\n' "$after"
    printf '| Benchmark | Before (ms) | After (ms) | Delta (ms) | Delta (%%) |\n'
    printf '|---|---:|---:|---:|---:|\n'

    local bench
    for bench in zsh-startup fish-startup zsh-startup-fast fish-startup-fast; do
      local b_raw a_raw b_ms a_ms
      b_raw="$(extract_hyperfine_mean "$before_txt" "$bench" || true)"
      a_raw="$(extract_hyperfine_mean "$after_txt" "$bench" || true)"
      [[ -n "$b_raw" && -n "$a_raw" ]] || continue
      b_ms="$(to_ms "$b_raw")"
      a_ms="$(to_ms "$a_raw")"
      local delta pct
      delta="$(awk -v b="$b_ms" -v a="$a_ms" 'BEGIN { printf "%.3f", a - b }')"
      pct="$(awk -v b="$b_ms" -v a="$a_ms" 'BEGIN { if (b == 0) print "0.0"; else printf "%.1f", ((a - b) / b) * 100 }')"
      printf '| %s | %s | %s | %s | %s%% |\n' "$bench" "$b_ms" "$a_ms" "$delta" "$pct"
    done
  } > "$out_md"

  log "Comparison written to: $out_md"
  cat "$out_md"
}

main() {
  [[ $# -gt 0 ]] || {
    usage
    exit 1
  }

  local cmd="$1"
  shift

  case "$cmd" in
    bench)
      cmd_bench "$@"
      ;;
    matrix)
      cmd_matrix "$@"
      ;;
    bench-components)
      cmd_bench_components "$@"
      ;;
    profile)
      cmd_profile "$@"
      ;;
    report)
      cmd_report "$@"
      ;;
    deep)
      cmd_deep "$@"
      ;;
    compare)
      cmd_compare "$@"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      die "Unknown command: $cmd"
      ;;
  esac
}

main "$@"
