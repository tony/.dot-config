# https://github.com/ryoppippi/fish-poetry/blob/main/conf.d/fish-poetry.fish
# license: MIT (2024-02-04, 2e5369f)
#
# https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e
# originally from https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e

if command -s poetry > /dev/null

    # complete --command poetry --arguments "(env _POETRY_COMPLETE=complete-fish COMMANDLINE=(commandline -cp) poetry)" -f

    # function that loads environment variables from a file
    function posix-source
        for i in (cat $argv)
            if test (echo $i | sed -E 's/^[[:space:]]*(.).+$/\\1/g') != "#" && test -n $i
                set arr (string split -m1 = $i)
                set -gx $arr[1] $arr[2]
            end
        end
    end


    function __poetry_shell_activate --on-variable PWD
        if status --is-command-substitution
            return
        end
        if not test -e "$PWD/pyproject.toml"
            if not string match -q "$__poetry_fish_initial_pwd"/'*' "$PWD/"
                set -U __poetry_fish_final_pwd "$PWD"
                exit
            end
            return
        end

        if not test -n "$POETRY_ACTIVE"
          if poetry env info -p >/dev/null 2>&1
            set -x __poetry_fish_initial_pwd "$PWD"
            if test "$FISH_POETRY_LOAD_ENV" -a -e "$PWD/.env"
                echo "Setting environment variables..."
                posix-source $PWD/.env
            end

            poetry shell --quiet --no-ansi

            set -e __poetry_fish_initial_pwd
            if test -n "$__poetry_fish_final_pwd"
                cd "$__poetry_fish_final_pwd"
                set -e __poetry_fish_final_pwd
            end
          end
        end
    end
    __poetry_shell_activate
else
    function poetry -d "https://python-poetry.org"
        echo "Install https://python-poetry.org to use this plugin." > /dev/stderr
        return 1
    end
end

# Based on https://gist.github.com/tommyip/cf9099fa6053e30247e5d0318de2fb9e
# Based on https://gist.github.com/bastibe/c0950e463ffdfdfada7adf149ae77c6f
# Based on https://github.com/nakulj/auto-venv/
# Changes:
# * Instead of overriding cd, we detect directory change. This allows the script to work
#   for other means of cd, such as z.
# * Update syntax to work with new versions of fish.
function __auto_source_venv --on-variable PWD --description "Activate/Deactivate virtualenv on directory change"
  status --is-command-substitution; and return

  # Check if we are inside a git repository
  if git rev-parse --show-toplevel &>/dev/null
    set dir (realpath (git rev-parse --show-toplevel))
  else
    set dir (pwd -P)
  end

  # Find a virtual environment in the directory
  set VENV_DIR_NAMES env .env venv .venv
  for venv_dir in $dir/$VENV_DIR_NAMES
    if test -e "$venv_dir/bin/activate.fish"
      break
    end
  end

  # Activate venv if it was found and not activated before
  if test "$VIRTUAL_ENV" != "$venv_dir" -a -e "$venv_dir/bin/activate.fish"
    source $venv_dir/bin/activate.fish
  # Deactivate venv if it is activated but the directory doesn't exist
  else if not test -z "$VIRTUAL_ENV" -o -e "$venv_dir"
      # deactivate
  end
end

__auto_source_venv
