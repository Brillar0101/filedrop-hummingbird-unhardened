#!/usr/bin/env bash
#
# 01-boot-vm.sh
# Boot a SECOND Hummingbird VM for the unhardened File Drop stack.
# Same Hummingbird OS as the hardened project — only the container images differ.
#
# RUN THIS ON A LINUX HOST WITH KVM. Requires: podman, qemu-kvm, libvirt, virt-install.
# The base Hummingbird disk image must already be built (by filedrop-hummingbird's
# 01-build-and-boot-vm.sh).  This script copies it and boots a second VM.

set -euo pipefail

SOURCE_DISK="/var/lib/libvirt/images/qcow2/disk.qcow2"
OUTPUT_DIR="/var/lib/libvirt/images"
DISK="${OUTPUT_DIR}/hummingbird-unhardened.qcow2"
VM_NAME="hummingbird-unhardened"

if [[ ! -f "${SOURCE_DISK}" ]]; then
  echo "ERROR: Hummingbird disk image not found at ${SOURCE_DISK}." >&2
  echo "       Run filedrop-hummingbird/deploy/01-build-and-boot-vm.sh first" >&2
  echo "       to build the base Hummingbird image." >&2
  exit 1
fi

echo ">> Copying the Hummingbird disk image for the unhardened VM..."
sudo cp "${SOURCE_DISK}" "${DISK}"

echo ">> Booting the VM '${VM_NAME}'"
echo ">> Log in as: core / hummingbird   (leave the console with Ctrl+])"
sudo virt-install \
  --name "${VM_NAME}" \
  --memory 4096 --vcpus 2 \
  --import \
  --disk "${DISK}" \
  --os-variant fedora-rawhide \
  --graphics none \
  --console pty,target_type=serial

echo
echo ">> VM is up. Next: copy the project onto it and run 02-deploy-filedrop.sh inside the VM."
echo ">> For example, from this host:"
echo ">>   scp -r ~/projects/filedrop-unhardened core@<vm-ip>:~/"
