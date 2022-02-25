# flake8: noqa F821 E501 E266

import os

# Configuration file for ipython.
# c.InteractiveShellApp.code_to_run = ''

## Run the file referenced by the PYTHONSTARTUP environment variable at IPython
#  startup.
# c.InteractiveShellApp.exec_PYTHONSTARTUP = True

## List of files to run at IPython startup.
# c.InteractiveShellApp.exec_files = []

# lines of code to run at IPython startup.
"""
%autoreload 0

Disable automatic reloading.
%autoreload 1

Reload all modules imported with %aimport every time before executing the Python code typed.
%autoreload 2

Reload all modules (except those excluded by %aimport) every time before executing the Python code typed.
"""
c.InteractiveShellApp.exec_lines = [
    "%autoreload 2",
    "import uuid",
]

c.InteractiveShellApp.extensions = ["autoreload"]

VI_MODE = True if bool(os.environ.get("VIMODE", "")) else False

if VI_MODE:
    c.TerminalInteractiveShell.editing_mode = "vi"

c.TerminalInteractiveShell.display_completions = "readlinelike"
c.TerminalInteractiveShell.display_page = True
c.TerminalInteractiveShell.automagic = False
c.IPCompleter.merge_completions = False
c.IPCompleter.omit__names = 0
