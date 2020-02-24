A simple wifi hotspot for the Raspberry Pi 3.                        

The install script use dnsmasq and hostap to configure the hotspot
The script will no configured  routing, NAT or forwarding ip traffic 
## Installation

Quick Installation for Raspbian:

```bash
sudo -i
bash <(curl -s https://raw.githubusercontent.com/amerinoj/hotspot/master/install.sh)     
chmod +x install.sh
./install.sh

```
                                                                                   
## Config

The basics values are asking in the install script.
If you need customizer the ip range asidned by dhcp, edit install.sh and modify the default values

```
ip_gw=192.168.4.1/24
ip_mask=255.255.255.0
dhcp_start=192.168.4.10
dhcp_end=192.168.4.50
```
