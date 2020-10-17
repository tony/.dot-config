sudo zfs create -o mountpoint=/usr/src tank/src
sudo zfs create -o mountpoint=/usr/ports tank/ports

sudo zfs create -o mountpoint=/tank/ccache tank/ccache
sudo zfs create -o mountpoint=/usr/docker tank/docker
sudo zfs create -o mountpoint=/var/cache/portshaker tank/portshaker
sudo zfs create -o mountpoint=/poudriere tank/poudriere
