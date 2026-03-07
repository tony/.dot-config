#!/usr/bin/env fish
# test_mise_cache.fish — Validates the two-layer mise caching in asdf.fish
#
# Tests cover:
#   1. Cold cache: both layers generate correctly
#   2. Warm cache: both layers serve from cache (no mise process spawn)
#   3. Cache invalidation: touching config files busts the right layer
#   4. Tool availability: PATH contains mise-managed tools after startup
#   5. State correctness: __MISE_DIFF and __MISE_SESSION are populated
#   6. Fast mode: Layer 2 (hook-env) is skipped
#   7. Signature coverage: all config files are tracked
#
# Usage:
#   fish scripts/test_mise_cache.fish
#
# The test creates an isolated cache directory so it doesn't interfere
# with the user's real cache. It requires mise to be installed.

set -g test_pass 0
set -g test_fail 0
set -g test_name ""

function _test_begin -a name
    set -g test_name $name
    printf "  %-55s " $name
end

function _test_ok
    set -g test_pass (math $test_pass + 1)
    echo "OK"
end

function _test_fail -a reason
    set -g test_fail (math $test_fail + 1)
    echo "FAIL"
    echo "    → $reason"
end

function _assert_eq -a actual expected label
    if test "$actual" = "$expected"
        return 0
    end
    _test_fail "$label: expected '$expected', got '$actual'"
    return 1
end

function _assert_contains -a haystack needle label
    if string match -q "*$needle*" "$haystack"
        return 0
    end
    _test_fail "$label: '$haystack' does not contain '$needle'"
    return 1
end

function _assert_file_exists -a path label
    if test -f "$path"
        return 0
    end
    _test_fail "$label: file not found: $path"
    return 1
end

# -----------------------------------------------------------------------
# Setup: create an isolated test environment
# -----------------------------------------------------------------------
# Use global variables for test state — fish functions cannot see
# the caller's local variables (lexical scoping, not dynamic).
set -g test_dir (mktemp -d /tmp/mise-cache-test.XXXXXX)
set -g test_cache "$test_dir/cache/fish"
set -g asdf_fish (realpath (status dirname)/../config/fish/conf.d/asdf.fish)

# Verify prerequisites
if not command -sq mise
    echo "SKIP: mise not installed"
    exit 0
end

if not test -f "$asdf_fish"
    echo "SKIP: asdf.fish not found at $asdf_fish"
    exit 1
end

echo "mise cache test suite"
echo "  test dir: $test_dir"
echo "  asdf.fish: $asdf_fish"
echo ""

# Helper: source asdf.fish in a clean sub-environment
# Uses XDG_CACHE_HOME override to isolate cache files.
function _source_asdf_isolated
    # Run in a sub-fish with isolated cache directory.
    # XDG_CACHE_HOME points to our test dir so cache files land there.
    env XDG_CACHE_HOME="$test_dir/cache" \
        MISE_DATA_DIR="$HOME/.config/mise" \
        MISE_STARTUP_MODE="$argv[1]" \
        fish --no-config -c "
            source $asdf_fish 2>/dev/null
            echo PATH_HAS_MISE=(string match -q '*/mise/installs/*' \$PATH; and echo yes; or echo no)
            echo MISE_DIFF_SET=(set -q __MISE_DIFF; and echo yes; or echo no)
            echo MISE_SESSION_SET=(set -q __MISE_SESSION; and echo yes; or echo no)
            echo GOROOT_SET=(test -n \"\$GOROOT\"; and echo yes; or echo no)
            echo HOOK_ENV_EVAL=(functions -q __mise_env_eval; and echo yes; or echo no)
            echo HOOK_PREEXEC=(functions -q __mise_env_eval_2; and echo yes; or echo no)
        " 2>/dev/null
end

# -----------------------------------------------------------------------
# Test 1: Cold cache — both layers generate files
# -----------------------------------------------------------------------
_test_begin "cold cache: generates activate cache"
rm -rf "$test_cache"
_source_asdf_isolated default > /dev/null
if _assert_file_exists "$test_cache/mise_activate.fish" "activate cache"
    _test_ok
end

_test_begin "cold cache: generates activate signature"
_assert_file_exists "$test_cache/mise_activate.signature" "activate sig"
and _test_ok

_test_begin "cold cache: generates hookenv cache"
_assert_file_exists "$test_cache/mise_hookenv.fish" "hookenv cache"
and _test_ok

_test_begin "cold cache: generates hookenv signature"
_assert_file_exists "$test_cache/mise_hookenv.signature" "hookenv sig"
and _test_ok

# -----------------------------------------------------------------------
# Test 2: Warm cache — verify cache contents are valid
# -----------------------------------------------------------------------
_test_begin "warm cache: activate cache has mise wrapper"
set -l activate_content (cat "$test_cache/mise_activate.fish" 2>/dev/null)
_assert_contains "$activate_content" "function mise" "activate content"
and _test_ok

_test_begin "warm cache: activate has hook functions (not --no-hook-env)"
# The cached activate SHOULD contain __mise_env_eval function definition
# (needed for cd-time tool switching) but NOT a bare __mise_env_eval call
if not string match -q "*function __mise_env_eval*" "$activate_content"
    _test_fail "activate cache missing __mise_env_eval function (hooks not registered)"
else if string match -qr '^\s*__mise_env_eval\s*;?\s*$' "$activate_content"
    _test_fail "activate cache contains bare __mise_env_eval call (should be stripped)"
else
    _test_ok
end

_test_begin "warm cache: hookenv cache sets PATH"
set -l hookenv_content (cat "$test_cache/mise_hookenv.fish" 2>/dev/null)
_assert_contains "$hookenv_content" "set -gx PATH" "hookenv PATH"
and _test_ok

_test_begin "warm cache: hookenv cache sets __MISE_DIFF"
_assert_contains "$hookenv_content" "__MISE_DIFF" "hookenv DIFF"
and _test_ok

# -----------------------------------------------------------------------
# Test 3: Tool availability — PATH contains mise tools
# -----------------------------------------------------------------------
_test_begin "tools: PATH includes mise installs after startup"
set -l state_lines (string split \n -- (_source_asdf_isolated default))
set -l path_has_mise ""
set -l diff_set ""
set -l session_set ""
set -l hook_env_eval ""
set -l hook_preexec ""
for line in $state_lines
    if string match -q 'PATH_HAS_MISE=*' "$line"
        set path_has_mise (string replace 'PATH_HAS_MISE=' '' "$line")
    else if string match -q 'MISE_DIFF_SET=*' "$line"
        set diff_set (string replace 'MISE_DIFF_SET=' '' "$line")
    else if string match -q 'MISE_SESSION_SET=*' "$line"
        set session_set (string replace 'MISE_SESSION_SET=' '' "$line")
    else if string match -q 'HOOK_ENV_EVAL=*' "$line"
        set hook_env_eval (string replace 'HOOK_ENV_EVAL=' '' "$line")
    else if string match -q 'HOOK_PREEXEC=*' "$line"
        set hook_preexec (string replace 'HOOK_PREEXEC=' '' "$line")
    end
end
_assert_eq "$path_has_mise" "yes" "PATH has mise tools"
and _test_ok

_test_begin "tools: __MISE_DIFF is set after startup"
_assert_eq "$diff_set" "yes" "__MISE_DIFF"
and _test_ok

_test_begin "tools: __MISE_SESSION is set after startup"
_assert_eq "$session_set" "yes" "__MISE_SESSION"
and _test_ok

# -----------------------------------------------------------------------
# Test 3b: Hook registration — hooks are present for cd-time switching
# -----------------------------------------------------------------------
_test_begin "hooks: __mise_env_eval is registered (fish_prompt)"
_assert_eq "$hook_env_eval" "yes" "__mise_env_eval function"
and _test_ok

_test_begin "hooks: __mise_env_eval_2 is registered (fish_preexec)"
_assert_eq "$hook_preexec" "yes" "__mise_env_eval_2 function"
and _test_ok

# -----------------------------------------------------------------------
# Test 4: Cache invalidation — touching config busts the right layer
# -----------------------------------------------------------------------

# 4a: Stale activate signature triggers regeneration
_test_begin "invalidation: stale activate sig triggers regen"
# Ensure cache exists first
rm -rf "$test_dir/cache"
_source_asdf_isolated default > /dev/null
# Now corrupt the signature
echo "stale-signature" > "$test_cache/mise_activate.signature"
_source_asdf_isolated default > /dev/null
set -l new_activate_sig (cat "$test_cache/mise_activate.signature" 2>/dev/null)
if test "$new_activate_sig" != "stale-signature"
    _test_ok
else
    _test_fail "signature unchanged after invalidation"
end

# 4b: Stale hookenv signature triggers regeneration
_test_begin "invalidation: stale hookenv sig triggers regen"
echo "stale-hookenv-sig" > "$test_cache/mise_hookenv.signature"
_source_asdf_isolated default > /dev/null
set -l new_hookenv_sig (cat "$test_cache/mise_hookenv.signature" 2>/dev/null)
if test "$new_hookenv_sig" != "stale-hookenv-sig"
    _test_ok
else
    _test_fail "hookenv signature not regenerated"
end

# -----------------------------------------------------------------------
# Test 5: Fast mode — Layer 2 is skipped
# -----------------------------------------------------------------------
_test_begin "fast mode: skips hookenv cache"
rm -rf "$test_dir/cache"
set -l fast_state_lines (string split \n -- (_source_asdf_isolated fast))
set -l fast_path ""
for line in $fast_state_lines
    if string match -q 'PATH_HAS_MISE=*' "$line"
        set fast_path (string replace 'PATH_HAS_MISE=' '' "$line")
    end
end
# In fast mode, tools are NOT in PATH at startup
_assert_eq "$fast_path" "no" "fast mode PATH"
and _test_ok

_test_begin "fast mode: does not create hookenv cache"
if test -f "$test_cache/mise_hookenv.fish"
    _test_fail "hookenv cache should not exist in fast mode"
else
    _test_ok
end

_test_begin "fast mode: still creates activate cache"
_assert_file_exists "$test_cache/mise_activate.fish" "activate in fast mode"
and _test_ok

# -----------------------------------------------------------------------
# Test 6: Signature coverage — all config files tracked
# -----------------------------------------------------------------------
_test_begin "signature: includes global config.toml"
rm -rf "$test_dir/cache"
_source_asdf_isolated default > /dev/null
set -l sig (cat "$test_cache/mise_hookenv.signature" 2>/dev/null)
_assert_contains "$sig" "config.toml" "config.toml in sig"
and _test_ok

_test_begin "signature: includes ~/.tool-versions"
_assert_contains "$sig" ".tool-versions" "global .tool-versions in sig"
and _test_ok

_test_begin "signature: tracks absent files"
_assert_contains "$sig" "absent" "absent marker"
and _test_ok

# -----------------------------------------------------------------------
# Test 7: Performance — warm cache is fast
# -----------------------------------------------------------------------
_test_begin "performance: warm cache startup under 100ms"
# Regenerate cache first
rm -rf "$test_dir/cache"
_source_asdf_isolated default > /dev/null

# Time warm cache (includes fish process spawn overhead)
set -l t1 (date +%s%N)
_source_asdf_isolated default > /dev/null
set -l t2 (date +%s%N)
set -l ms (math "($t2 - $t1) / 1000000")

if test $ms -lt 100
    _test_ok
else
    _test_fail "warm cache took "$ms"ms (expected <100ms)"
end

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
echo ""
echo "Results: $test_pass passed, $test_fail failed"

# Cleanup
rm -rf "$test_dir"

if test $test_fail -gt 0
    exit 1
end
exit 0
