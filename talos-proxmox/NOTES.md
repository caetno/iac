# dnsmasq as PXE proxy DHCP

https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
`Dnsmasq supports PXE "proxy-DHCP", in this case another DHCP server on the network is responsible for allocating IP addresses, and dnsmasq simply provides the information given in --pxe-prompt and --pxe-service to allow netbooting. This mode is enabled using the proxy keyword in --dhcp-range.`

# Flatcar deployment

qm create "${VM_ID}" \
  --bios ovmf --efidisk0 local-lvm:1 \
  --arch x86_64 --machine q35 --args "-machine sata=off" \
  --cores 2 --memory 4096 \
  --net0 "virtio,bridge=vmbr0" --ipconfig0 "ip=dhcp" \
  --virtio0 "local-lvm:0,import-from=${IMAGE}" --boot order=virtio0 \
--scsihw virtio-scsi-pci --scsi0 local-lvm:cloudinit
