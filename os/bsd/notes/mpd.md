# Musicpd (mpd)

## Set up fifo / visualization

```sh
$ mkdir ~/.ncmpcpp
$ cp /usr/share/doc/ncmpcpp/doc/config ~/.ncmpcpp/config
$ echo "visualizer_fifo_path = \"/tmp/mpd.fifo\"" >> ~/.ncmpcpp/config
$ echo "visualizer_output_name = \"My FIFO\"" >> ~/.ncmpcpp/config
```
