I ran the following on WSL2 on Windows 11, using the Debian distro.
I'll keep modigying these as I learn more. I think some of the steps aren't required but I'm keeping tabs on how to do this and will make sure ultimately there's a minimal set of steps to compile kernel modules.

Find your download URLs [here](https://archive.synology.com/download/ToolChain)

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

1. You will need a build folder that exists on an ext4 partition (not NTFS or FAT)
 * `mkdir /volume1`
 * `mkdir /volume1/synology-toolkit`
 * `mkdir /volume1/synology-toolkit/toolchains`
 * `cd /volume1/synology-toolkit`

2. Clone the toolkit repo and checkout the DSM version
 * `git clone https://github.com/SynologyOpenSource/pkgscripts-ng`
 * `cd pkgscripts-ng`
 * `git checkout DSM7.2`

3. create the chroot for your target
 * `sudo ./EnvDepot -v 7.2 -p apollolake`

4. Download and install the toolchain for your platform
 * `cd /volume1/synology-toolkit/toolchains`
 * `wget --content-disposition https://global.synologydownload.com/download/ToolChain/toolchain/7.2-72746/Intel%20x86%20Linux%204.4.180%20%28Apollolake%29/apollolake-gcc1220_glibc236_x86_64-GPL.txz` (find the URL for your platform)
 * `sudo tar xJf geminilake-gcc1220_glibc236_x86_64-GPL.txz -C /usr/local/`

5. Download and install the kernel source for your platform
 * `cd /volume1/synology-toolkit`
 * `wget --content-disposition https://global.synologydownload.com/download/ToolChain/Synology%20NAS%20GPL%20Source/7.2-64570/apollolake/linux-4.4.x.txz`
 * `sudo tar -Jxvf ./linux-3.10.x.txz -C /usr/local/x86_64-pc-linux-gnu/`

6. Change to the kernel source folder (change the folder name with your kernel version):
 * `cd /usr/local/x86_64-pc-linux-gnu/linux-4.4.x`

7. Copy the kernel config for your device / platform to .config in the kernel folder. The below example is for apollolake:
 * `sudo cp synoconfigs/apollolake .config`

8. Edit the file `Makefile` in the kernel source folder, editing the EXTRAVERSTION to add the plus so that the kernel matches the `uname -r` output on the NAS you're compiling for, and editing the `CROSS_COMPILE` and `ARCH` lines.
 * `EXTRAVERSION = +`
 * `ARCH            ?= x86_64`
 * `CROSS_COMPILE   ?= /usr/local/x86_64-pc-linux-gnu/bin/x86_64-pc-linux-gnu-`

9. Edit the `.config` file you copied, change modules you want to compile as modules to have `=m` if they were previously `is not set`:
 * `CONFIG_IP_NF_RAW=m`
 * `CONFIG_IP6_NF_RAW=m`

10. Modify the config based on the source:
 * `sudo make oldconfig` This will prompt you to choose how to build the added modules (just hit ENTER to accept the defaults)

11. Run the following commands:
 * `sudo make prepare`
 * `sudo make modules_prepare`

12. Build the modules you're wanting to build (example):
 * `sudo make M=net/ipv4/netfilter modules`
 * `sudo make M=net/ipv6/netfilter modules`
 * (alternatively just build all modules) `sudo make modules`

13. Your modules should now be available in the appropriate folders for copying to your synology. Given the above, they're in:
 * `net/ipv4/netfilter/iptable_raw.ko`
 * `net/ipv6/netfilter/iptable_raw.ko`

14. You can check the details of the mod by running, for example:
 * `sudo modinfo net/ipv4/netfilter/iptable_raw.ko` - The `vermagic` line has to match the kernel version of your NAS precisely (including the `+` suffix):
```
filename:       net/ipv4/netfilter/iptable_raw.ko
license:        GPL
depends:        ip_tables
retpoline:      Y
vermagic:       4.4.302+ SMP mod_unload
```

15. You can now copy these files to your NAS in `/lib/modules`

16. Change the permissions and ownership of the new `.ko` files on the NAS:
```
sudo chown root:root /lib/modules/{iptable_raw.ko,ip6table_raw.ko}
sudo chmod 644 /lib/modules/{iptable_raw.ko,ip6table_raw.ko}
```

17. Load the modules:
```
sudo insmod /lib/modules/ip6table_raw
sudo insmod /lib/modules/iptable_raw
```

18. Assuming you received no errors, validate they're loaded:
```
$ sudo lsmod | grep raw
iptable_raw             1452  0
ip6table_raw            1456  0
ip6_tables             14933  14 ip6table_filter,ip6table_raw
ip_tables              14342  4 iptable_filter,iptable_mangle,iptable_nat,iptable_raw
x_tables               17395  24 ip6table_filter,xt_ipvs,xt_iprange,xt_mark,xt_recent,ip_tables,xt_tcpudp,ipt_MASQUERADE,xt_geoip,xt_limit,xt_state,xt_conntrack,xt_LOG,xt_mac,xt_nat,xt_set,xt_multiport,iptable_filter,ip6table_raw,xt_REDIRECT,iptable_mangle,ip6_tables,xt_addrtype,iptable_raw
```

19. If you want to load the libraries on startup, add the `insmod` lines from above to a Scheduled Task, running as `root` on boot.
