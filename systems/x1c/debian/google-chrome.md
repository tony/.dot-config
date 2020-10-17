https://productforums.google.com/d/msg/chrome/CtKF2BiskT8/K75XE8UKAAAJ

Open a terminal as root and enter this command: "sudo nano /usr/share/applications/chromium-browser.desktop"
and scroll down until you get to this line: "Exec= chromium-browser" Then add this two parameters
"--disable-gpu-driver-bug-workarounds --enable-native-gpu-memory-buffers" click Ctrl+O to save and Ctrl+X to exit.

Then enter this command as root again: "sudo nano /usr/share/X11/xorg.conf.d/20-intel.conf" and add this lines

.. code-block::

    Section "Device"
       Identifier  "Intel Graphics"
       Driver      "intel"
       Option      "AccelMethod"  "sna"
       Option      "TearFree"    "true"
       Option      "DRI"    "3"
    EndSection

Ctrl+O and Ctrl+X.

Open chromium and write to address bar: "chrome://flags/" and enter.

- Enable-zero-copy
- Enable Override Software Rendering List
- Enable Display 2D List Canvas

Finally open chrome settings and click on:

"Use hardware acceleration when available"
