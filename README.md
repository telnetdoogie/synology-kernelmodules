# Compiling Optional Kernel Modules for Synology
## (Primarily motivated by docker v28 requiring iptables_raw modules) - but could be extended and used for other things.

------------------

## Using Docker

I am just using docker now which automates all the above. All you have to pass is the platform name, like `apollolake` or `geminilake`

* mapping a volume like the below will automatically pull the created modules out of the build onto the host for publishing.

| :warning: I strongly advise you DO NOT run this in a container on your NAS as the host. The toolkit specifically advises against that, and I think given what it does with `/proc` it might not be a great idea. |
| --- |

```
docker build -t compile_modules .
docker run --privileged --rm -v ./compiled_modules:/compiled_modules:rw -e PLATFORM=apollolake compile_modules
```

## Experimental - Legacy builds

I've been attempting to build for older kernels, as yet unsuccessfully, but I leave a trail here lest someone can continue and make it work
I have made a 'legacy' Dockerfile for these older builds, where older compilers and OSes are required nmaybe.

```
docker build -t compile_modules_legacy ./Dockerfile_legacy
docker run --privileged --rm -v ./compiled_modules:/compiled_modules:rw -e PLATFORM=avoton compile_modules_legacy
```


---


## If you want to modify this...

`entrypoint.sh` is where everything happens. If you include additional files be sure to modify the Dockerfile to copy them into the container on build.
Currently, `entrypoint.sh` reads the `PLATFORM` value that's passed in, and uses that to set up the DSM toolchain which downloads the cross-compiler and sets the environment up for build.

`apply_patches.sh` gets called from `entrypoint.sh` before compilation, in case any modifications are needed to config or source.

Once module compilations are complete, compiled modules are copied out to the `/compiled_modules` folder

So... if you want to make significant changes to this, `entrypoint.sh` is the place to start. 

The way this is set up currently (the way I run it, with `--rm`) the container is stateless so DSM toolchain downloads etc happen anew each time.

Happy tinkering!

---



#### 20. If you want to load the libraries on startup, add the `insmod` lines from above to a Scheduled Task, running as `root` on boot.
