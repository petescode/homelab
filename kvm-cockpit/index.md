# Setting up a KVM hypervisor with Cockpit

In this walk-through I am using a laptop to build as a KVM hypervisor

Laptop: Dell Precision 5520

Since this laptop doesn't have an Ethernet port, I used a USB-C-to-Ethernet cable

Start by installing CentOS 8 Stream, select the option for Virtualization Host, and use the Enable toggle to automatically configure the network connection

# Post install setup
```markdown
systemctl enable --now cockpit.socket
```
Determine IP address
```markdown
ip addr
```
At this point you can switch to a machine on the same network and use a browser to hit Cockpit at port 9090

In my case I am using a laptop with Fedora 32 Workstation installed

Once logged into Cockpit, use the menu on the left-hand side and select Terminal

This Terminal is nice because it lets you copy/paste from your workstation

Change hostname to something meaningful. In my case I am going to have two KVM hosts, one this laptop and another a PC tower.
```markdown
hostnamectl set-hostname "kvm-laptop"
```
Install updates
```markdown
yum install updates -y
```
Install virtual machine management for Cockpit 
```markdown
yum install cockpit-machines -y
```
Optional reboot now to update the hostname and if there were kernel updates
  
### At this point there's a couple of important things I need to address in order to start creating VMs:
1. Create a storage pool for the virtual disks
2. Setup a bridged network so that each VM will be on the same network as the rest of my home lab

# Create storage pool for virtual disks
Determine where you have a lot of storage. Virtual disks can be hundreds of Gb's
```markdown
df -h
```
In my case there's only 70Gb on the root filesystem but 850Gb for /home. So I will host the virtual disks there. Not ideal but it works.
```markdown
mkdir /home/vm-storage
```
Since I don't like that I will just make a link to somewhere that looks nicer
```markdown
ln --symbolic /home/vm-storage/ /vm-storage
```
Now I can point my disk files to simply /vm-storage

I'll do the same sort of thing to create a place to store ISO files:
```markdown
mkdir /home/vm-iso
ln --symbolic /home/vm-iso /vm-iso
```
Let's go ahead and grab an ISO for when we want to test creating a VM
```markdown
cd /vm-iso
wget https://download.fedoraproject.org/pub/fedora/linux/releases/33/Workstation/x86_64/iso/Fedora-Workstation-Live-x86_64-33-1.2.iso
```
    
The following steps can also be performed in the Cockpit GUI, but here I will stick to CLI.

Check the default storage pool. Right now since we haven't yet attempted to create a VM, there shouldn't be one:
```markdown
virsh pool-list
```
IF there is a default already, remove it with the following:
```markdown
virsh pool-destroy default
virsh pool-undefine default
```
Define a default storage pool:
```markdown
virsh pool-define-as --name default --type dir --target /vm-storage
virsh pool-autostart default && virsh pool-start default
```
Now if you do the list command again, you should see it as your default:
```markdown
virsh pool-list
```
To see this in the GUI, navigate the Virtual Machines, and click on the Storage Pools link at the top
    
# Setup a bridged network
Used the following link as a guide: https://phoenixnap.com/kb/install-kvm-centos
  
###  IMPORTANT: as part of this process you will delete the current network interface, which will then disconnect you from Cockpit. Do this process from a direct terminal on the KVM host.
        
Identify the current network interface:
```markdown
nmcli connection show
```
Ignore the virtual bridge interface (virbr0) for now.

Take note of the name of the network device. For example, mine shows as "enp62s0u1"

Delete the current network interface:
```markdown
nmcli connection delete <uuid of your interface>
```
Create the new bridge interface:
```markdown
nmcli connection add type bridge autoconnect yes con-name kvmbr1 ifname kvmbr1
```
Note here that I chose "kvmbr1" arbitrarily. I wanted to distinguish it from the other virtual bridge interface.

Modify the connection settings to set the IP, gateway, and DNS server
```markdown
nmcli connection modify kvmbr1 ipv4.addresses 10.X.X.X/24 ipv4.method manual
nmcli connection modify kvmbr1 ipv4.gateway 10.X.X.X
nmcli connection modify kvmbr1 ipv4.dns 10.X.X.X
```
Add a bridge slave
```markdown
nmcli connection add type bridge-slave autoconnect yes con-name enp62s0u1 ifname enp62s0u1 master kvmbr1
```
Bring the bridge interface up
```markdown
nmcli connection up kvmbr1
```
You should now see both kvmb1 and enp62s0u1 (in my case) as green
```markdown
nmcli connection show
```
Now you should be able to reconnect to Cockpit at the IP address you provided

Create a test VM from the Virtual Machines menu.

Once created, you should notice that the .qcow2 file (the virtual disk) is at the location you specified as the storage pool.

Also notice that the VM by default has an IP address in the same network as the KVM host.
  
  
