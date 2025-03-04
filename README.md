I ran the following on WSL2 on Windows 11, using the Debian distro.
The instructions should be the same however you'll want to pull the correct linux kernel source for your NAS depending on which kernel version you're currently running, and for the appropriate architecture (The below was done for x86. Different options may be needed on `make` commands for compiling for a different `ARCH` )

1. Install packages for running a kernel build:
```
sudo apt install build-essential \
                  ncurses-dev \
                  bc \
                  libssl-dev \
                  libc6-i386 \
                  curl \
                  libproc-processtable-perl \
                  wget \
                  kmod
```

1. Download the Syno Kernel for your platform with:
```
wget --content-disposition https://global.synologydownload.com/download/ToolChain/Synology%20NAS%20GPL%20Source/7.2-64570/apollolake/linux-4.4.x.txz
```

1. unzip the kernel source:
```
xz -d < linux-4.4.x.txz| tar xvf -
```

1. Change to the kernel source folder:
```
cd linux-4.4.x
```

1. Copy the kernel config for your device / platform to .config in the kernel folder:
```
cp synoconfigs/apollolake .config
```

1. Edit the file `Makefile` in the kernel source folder, editing the EXTRAVERSTION to add the plus so that the kernel matches the `uname -r` output on the NAS you're compiling for:
```
VERSION = 4
PATCHLEVEL = 4
SUBLEVEL = 302
EXTRAVERSION = +
NAME = Blurry Fish Butt
```

1. Edit the `.config` file you copied, change modules you want to compile as modules to have `=m` if they were previously `is not set`:
```
CONFIG_IP_NF_RAW=m
CONFIG_IP6_NF_RAW=m
```

1. Run the following command, for new modules that weren't in the config file you'll be prompted how to compile. Hit RETURN to accept the defaults for these:
```
make oldconfig
```

1. Run the following commands:
```
make prepare
make modules_prepare
```

1. Build the modules you're wanting to build (example):
```
make M=net/ipv4/netfilter modules
make M=net/ipv6/netfilter modules
```

1. Your modules should now be available in the appropriate folders for copying to your synology. Given the above, they're in:
```
net/ipv4/netfilter/iptable_raw.ko
net/ipv6/netfilter/iptable_raw.ko
```

1. You can check the details of the mod by running, for example:
```
modinfo net/ipv4/netfilter/iptable_raw.ko
```
The `vermagic` line has to match the kernel version of your NAS precisely (including the `+` suffix):
```
filename:       net/ipv4/netfilter/iptable_raw.ko
license:        GPL
depends:        ip_tables
retpoline:      Y
vermagic:       4.4.302+ SMP mod_unload
```

1. You can now copy these files to your NAS in `/lib/modules`

1. Change the permissions and ownership of the new `.ko` files on the NAS:
```
sudo chown root:root /lib/modules/{iptable_raw.ko,ip6table_raw.ko}
sudo chmod 644 /lib/modules/{iptable_raw.ko,ip6table_raw.ko}
```

1. Load the modules:
```
sudo insmod /lib/modules/ip6table_raw
sudo insmod /lib/modules/iptable_raw
```

1. Assuming you received no errors, validate they're loaded:
```
$ sudo lsmod | grep raw
iptable_raw             1452  0
ip6table_raw            1456  0
ip6_tables             14933  14 ip6table_filter,ip6table_raw
ip_tables              14342  4 iptable_filter,iptable_mangle,iptable_nat,iptable_raw
x_tables               17395  24 ip6table_filter,xt_ipvs,xt_iprange,xt_mark,xt_recent,ip_tables,xt_tcpudp,ipt_MASQUERADE,xt_geoip,xt_limit,xt_state,xt_conntrack,xt_LOG,xt_mac,xt_nat,xt_set,xt_multiport,iptable_filter,ip6table_raw,xt_REDIRECT,iptable_mangle,ip6_tables,xt_addrtype,iptable_raw
```

1. If you want to load the libraries on startup, add the `insmod` lines from above to a Scheduled Task, running as `root` on boot.
