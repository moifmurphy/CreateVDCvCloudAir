# usage
# ./CreateVDCvCloudAir.sh

# This sample script creates a new VDC in vCloud Air from an existing VDC template 
# It requires ovftool (4.1), vca-cli (15), curl and jq (min 1.5) to be installed on the system  
# It will also download, import and deploy an OVA. 
# In addition it will configure the Edge GW in the new VDC to talk allow traffic to/from the appliance

# given I had problems installing jq 1.5 using apt-get I am grabbing version 1.5 with brute-force 
curl -o ./jq -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
chmod +x jq 
echo 

read -p "Enter user name : " USER
echo -n Enter Password: 
read -s PASSWORD
echo

vca login $USER --password $PASSWORD
echo
vca instance
echo
read -p "Enter InstanceId you want to create the <photon> VDC in: " INSTANCEID
echo 

vca instance use --instance $INSTANCEID

echo
vca org list-templates
echo 
read -p "Enter the VDC template you want to use (DO NOT use -dr- VDCs): " TEMPLATEID
echo 

VCA_ORG_VDC_NAME='MYVDC'

vca vdc create --vdc $VCA_ORG_VDC_NAME --template "$TEMPLATEID"
vca vdc use --vdc $VCA_ORG_VDC_NAME
vca network create --network DMZ --gateway-ip 192.168.209.1 --netmask 255.255.255.0 --dns1 8.8.8.8 --pool 192.168.209.100-192.168.209.149
vca dhcp enable 
vca dhcp add --network DMZ --pool 192.168.209.50-192.168.209.99
vca gateway add-ip

echo 
curl -L -O https://dl.bintray.com/vmware/photon/ova/1.0TP2/x86_64/photon-1.0TP2.ova
echo 

VCA_URL=`vca -j instance info | ./jq --raw-output '.instance.region'` && echo $VCA_URL
VCA_ORG_NAME=`vca -j instance info | ./jq --raw-output '.instance.instanceAttributes' | ./jq --raw-output .orgName` && echo $VCA_ORG_NAME
VCA_CATALOG_NAME='default-catalog'


FILE_TO_UPLOAD='photon-1.0TP2.ova'
TEMPLATE_NAME_IN_VCA='photon-1.0TP2'

ovftool --acceptAllEulas --skipManifestCheck --vCloudTemplate=true --allowExtraConfig --X:logFile=vcd-upload.log --X:logLevel=verbose \
"${FILE_TO_UPLOAD}" \
"vcloud://${USER}:${PASSWORD}@${VCA_URL}?org=${VCA_ORG_NAME}&vdc=${VCA_ORG_VDC_NAME}&catalog=${VCA_CATALOG_NAME}&vappTemplate=${TEMPLATE_NAME_IN_VCA}"

echo
echo Getting ready to deploy the VM. Wait... 
echo

sleep 3m 

VAPP_NAME="photon-01"
VM_NAME=$VAPP_NAME
MANUAL_IP="192.168.209.49"

echo
vca vapp create -a $VAPP_NAME -V $VM_NAME -c $VCA_CATALOG_NAME -t $TEMPLATE_NAME_IN_VCA -n DMZ -m manual --ip $MANUAL_IP
echo
vca vapp customize --vapp $VAPP_NAME --vm $VM_NAME --file ./startdocker.sh
echo 

echo 
IP=`vca -j vm -a $VAPP_NAME | ./jq -r '.vms[0].IPs'` && echo "private IP:" $IP 
PUB_IP=`vca -j gateway | ./jq --raw-output '.gateways[0]."External IPs"'` && echo "public IP:" $PUB_IP
echo

vca nat add --type snat --original-ip 192.168.209.0/24 --translated-ip ${PUB_IP}
vca nat add --type dnat --original-ip ${PUB_IP} --original-port 22 --translated-ip $IP --translated-port 22 --protocol tcp

vca firewall disable 

echo
echo We are done! You can now connect to your VM by SSHing into ${PUB_IP} "[root / changeme -> note you will be asked to change the pwd]"
echo
