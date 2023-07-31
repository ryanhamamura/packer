# packer

## Copy `template-credentials.pkr.hcl.example`
```sh 
cp template-credentials.pkrvars.hcl.example credentials.pkrvars.hcl
```
Replace example values with real values. 

### Run `packer init` on the `ubuntu-server-focal-docker` to install proxmox plugin 
```sh 
cd ubuntu-server-focal-docker
packer ubuntu-server-focal-docker.pkr.hcl
```
### Build image 
```sh 
packer build -var-file=../template-credentials.pkrvars.hcl ubuntu-server-focal-docker.pkr.hcl
```

