This repository contains the combined kernel-initramfs image for use in a test of QEMU's vhost-user-bridge application.

Generate bzImage from scratch by running `podman build --output . .` in the repository's top directory; note, this will overwrite the in-tree bzImage, so adjust for need accordingly.

bzImage sha256: `3790bf35e4ddfe062425bca45e923df5a5ee4de44e456d6b00cf47f04991d549`

Testing of the container image build was only performed with Podman; problems with building may occur with other tools, e.g., Docker.
