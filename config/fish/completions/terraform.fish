function __complete_terraform
    set -lx COMP_LINE (commandline -cp)
    test -z (commandline -ct)
    and set COMP_LINE "$COMP_LINE "
    /usr/bin/terraform
end

complete -c terraform -f -a "(terraform --help | string match -r '^  \w.*' | string replace -r '^  (\w+).*' '$1')"

