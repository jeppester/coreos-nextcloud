Create ignition file:

```sh
butane -d . --pretty --strict butane.yaml > main.ign
```

Create virtual machine

```sh
virt-install --name=fcos --vcpus=3 --ram=4096 --os-variant=fedora-coreos-stable \
    --import --network=bridge=virbr0 --graphics=none \
    --qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${PWD}/main.ign" \
    --disk=size=95,backing_store=${PWD}/fedora-coreos.qcow2
```
