This repository contains a combined kernel-initramfs image intended for a test of QEMU's vhost-user-bridge application.

Generate bzImage from scratch by running `podman build --output . .` in the repository's top directory; note, this will overwrite the in-tree bzImage, so adjust for need accordingly.

bzImage sha256: `8860d7aa59434f483542cdf25b42eacae0d4d4aa7ec923af9589d1ad4703d42b`

Testing of the container image build was only performed with Podman; problems with building may occur with other tools, e.g., Docker.
