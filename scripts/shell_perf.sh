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
  shell_perf.sh profile [--run-dir DIR]
  shell_perf.sh report [--run-dir DIR]
  shell_perf.sh deep [--run-dir DIR] [--runs N] [--warmup N] [--cwd DIR] [--with-fast-mode]
  shell_perf.sh compare --before DIR --after DIR

Environment:
  SHELL_PERF_ARTIFACT_ROOT  Override artifact directory root.
  SHELL_PERF_RUNS           Default runs for bench/deep (default: 20).
  SHELL_PERF_WARMUP         Default warmup runs (default: 3).

Notes:
  - Artifacts are written under .artifacts/shell-perf by default.
  - Set MISE_STARTUP_MODE=fast to benchmark opt-in fast-mode startup behavior.
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

extract_hyperfine_mean() {
  local hyperfine_txt="$1"
  local bench_name="$2"
  awk -v bench_name="$bench_name" '
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
    commands+=("MISE_STARTUP_MODE=fast zsh -i -c exit" "MISE_STARTUP_MODE=fast fish -i -c exit")
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

cmd_profile() {
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
        die "Unknown profile option: $1"
        ;;
    esac
  done

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
  ZDOTDIR="$tmpdir" zsh -i -c exit > "$zprof_txt" 2>&1 || true
  rm -rf "$tmpdir"

  write_meta "$run_dir" "profile" "$DEFAULT_RUNS" "$DEFAULT_WARMUP" "$ROOT_DIR"
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

  if [[ -z "$run_dir" ]]; then
    run_dir="$(read_latest)"
  fi
  [[ -d "$run_dir" ]] || die "Run directory not found: $run_dir"

  local report_md="$run_dir/report.md"
  local hyperfine_txt="$run_dir/hyperfine.txt"
  local fish_prof_sorted="$run_dir/fish-startup.sorted.prof"
  local zprof_txt="$run_dir/zsh-zprof.txt"

  local zsh_default=""
  local fish_default=""
  local zsh_fast=""
  local fish_fast=""
  local zsh_default_ms=""
  local fish_default_ms=""
  local zsh_fast_ms=""
  local fish_fast_ms=""

  if [[ -f "$hyperfine_txt" ]]; then
    zsh_default="$(extract_hyperfine_mean "$hyperfine_txt" "zsh-startup" || true)"
    fish_default="$(extract_hyperfine_mean "$hyperfine_txt" "fish-startup" || true)"
    zsh_fast="$(extract_hyperfine_mean "$hyperfine_txt" "zsh-startup-fast" || true)"
    fish_fast="$(extract_hyperfine_mean "$hyperfine_txt" "fish-startup-fast" || true)"
    [[ -n "$zsh_default" ]] && zsh_default_ms="$(to_ms "$zsh_default")"
    [[ -n "$fish_default" ]] && fish_default_ms="$(to_ms "$fish_default")"
    [[ -n "$zsh_fast" ]] && zsh_fast_ms="$(to_ms "$zsh_fast")"
    [[ -n "$fish_fast" ]] && fish_fast_ms="$(to_ms "$fish_fast")"
  fi

  {
    printf '# Shell Performance Report\n\n'
    printf 'Run directory: `%s`\n\n' "$run_dir"
    printf 'Generated: `%s`\n\n' "$(date -Is)"

    printf '## Startup Benchmarks\n\n'
    if [[ -f "$hyperfine_txt" ]]; then
      printf '| Benchmark | Mean | Mean (ms) |\n'
      printf '|---|---:|---:|\n'
      [[ -n "$zsh_default" ]] && printf '| zsh-startup | %s | %s |\n' "$zsh_default" "$zsh_default_ms"
      [[ -n "$fish_default" ]] && printf '| fish-startup | %s | %s |\n' "$fish_default" "$fish_default_ms"
      [[ -n "$zsh_fast" ]] && printf '| zsh-startup-fast | %s | %s |\n' "$zsh_fast" "$zsh_fast_ms"
      [[ -n "$fish_fast" ]] && printf '| fish-startup-fast | %s | %s |\n' "$fish_fast" "$fish_fast_ms"
      printf '\n'
    else
      printf '_No hyperfine output found in this run._\n\n'
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

    if [[ -f "$fish_prof_sorted" ]] && grep -Eq 'mise hook-env|command mise|mise activate fish' "$fish_prof_sorted"; then
      any=1
      printf '%s\n' '- fish mise activation/hook environment updates are a primary startup bottleneck.'
      printf '%s\n' '- Improvement: keep defaults, and use opt-in `MISE_STARTUP_MODE=fast` in latency-sensitive contexts.'
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
