# xbootimg
Extract header data, kernel, ramdisk, second and device tree from boot.img.

* Command:
> \$ sh xbootimg.sh boot.img

* Output:
Several files are created (warning: if the files exists, they are modified).

  * kernel
  * kernel-size
  * kernel-addr
  * ramdisk
  * ramdisk-size
  * ramdisk-addr
  * second
  * second-size
  * second-addr
  * dt
  * dt-size
  * page-size
  * tags-addr
  * os-version
  * name
  * cmdline
  * id
  * extra-cmdline


