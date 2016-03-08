
## Create a Virtual Data Center in vCloud Air (and deploy an Internet accessible Docker host as a bonus)

## Massimo Re Ferre' [www.it20.info](http://www.it20.info)

This is a sample that I drafted with the idea of showing how to create a brand new VDC in vCloud Air (or any vCloud Director instance that supports this operational model). 
In addition, I have added the import and deployment of an OVA with some networking tweaks to show how to go from nothing to SSH into it. 

This sample script does the following (in details):

- reads your vCloud Air credentials (interactively)
- shows a list of instances for you to select one
- shows a list of VDC templates in the selected instance
- deploys a new VDC (called "MYVDC") in the selected instance
- creates a new routed network (called "DMZ") 
- enables DHCP on the routed network
- acquires a public IP on the Edge GW
- downloads an OVA 
- imports the OVA as a template into a private catalog 
- deploys the template as a vApp
- injects a script into the VM (which starts the docker deamon in the photon host) 
- creates SNAT/DNAT rules for outbound/inbound communications
- disables the Edge firewall (for sake of simplicity, don't do this!)

This script is provided as a sample for you to customize based on your own needs. 

It makes heavy usage of vca-cli (https://github.com/vmware/vca-cli). 

If everything goes well, this sample allows you to ssh into the public IP (as reported) of the VM and start using Docker on a Photon OS host. 
At the time of this writing, Photon OS Technical Preview 2 is the latest version available. 

## Requirements

This is the list of software the script expects to find on the system it runs on (with the version I have tested): 

- vca-cli (ver 15)
- curl 
- jq (ver 1.5) <- read note below
- ovftool (ver 4.1)

Note: jq needs to be at version 1.5 (I am brute forcing the download of the jq 1.5 executable in the script to be sure). Previous versions are known not to work with this script. 

You also need to have a valid vCloud Air account

## Usage

`./CreateVDCvCloudAir.sh` 

## License:

Apache Licensing version 2
