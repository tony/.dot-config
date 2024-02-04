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

            poetry shell

            set -e __poetry_fish_initial_pwd
            if test -n "$__poetry_fish_final_pwd"
                cd "$__poetry_fish_final_pwd"
                set -e __poetry_fish_final_pwd
            end
          end
        end
    end
else
    function poetry -d "https://python-poetry.org"
        echo "Install https://python-poetry.org to use this plugin." > /dev/stderr
        return 1
    end
end
