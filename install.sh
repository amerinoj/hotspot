#!/bin/bash +x
set -e
#set -x

#define values
ip_gw=192.168.4.1/24
ip_mask=255.255.255.0
dhcp_start=192.168.4.10
dhcp_end=192.168.4.50

# This script has been tested with the "2020-02-05-raspbian-buster-lite" image.
#test super user
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

#install
echo "Installing dependencies..."
apt-get update
apt-get --yes install dnsmasq hostapd	
echo "done."

echo "stoping services..."
systemctl stop dnsmasq
systemctl stop hostapd


#select wlan
echo -e "-------Wireless card config-------\n"
listcard=$(iw dev | grep wlan  | cut -d" " -f2 )
oldIFS=$IFS
IFS=$'\n'
choices=($listcard)
IFS=$oldIFS

PS3="Select your wireless card: "
select answer in "${choices[@]}"; do
       for item in "${choices[@]}"; do
	   if [[ $item == $answer ]]; then
               break 2;
           fi
       done
done
wcard=$answer
echo "Adapter select:"$wcard


############update /etc/dhcpcd.conf

if  grep -q "$wcard" "/etc/dhcpcd.conf" ; then
   if [[ "$(cat /etc/dhcpcd.conf | grep  -A3 wlan0)" != *"interface  "$wcard*"static ip_address="$ip_gw*"nohook  wpa_supplicant"* ]] ; then

        ip_only=$(echo "$ip_gw" | cut -d"/" -f 1)
         mask_only=$(echo "$ip_gw" | cut -d"/" -f 2)
         sed -i "s/$wcard/$wcard \n     static ip_address=$ip_only\/$mask_only \n      nohook wpa_supplicant/g" /etc/dhcpcd.conf 
   fi
else
    echo -e "interface  "$wcard"\n     static ip_address=$ip_gw \n      nohook  wpa_supplicant" >> /etc/dhcpcd.conf
fi 

# restart dhcpcd
service dhcpcd restart

##########config hostap

#default options hostap
if !  grep -q interface "/etc/hostapd/hostapd.conf" ; then

    echo -e "interface=wlan0" >> /etc/hostapd/hostapd.conf
    echo -e "driver=nl80211" >> /etc/hostapd/hostapd.conf
    echo -e "ssid=NameOfNetwork" >> /etc/hostapd/hostapd.conf
    echo -e "hw_mode=g" >> /etc/hostapd/hostapd.conf
    echo -e "channel=7" >> /etc/hostapd/hostapd.conf
    echo -e "wmm_enabled=0" >> /etc/hostapd/hostapd.conf
    echo -e "macaddr_acl=0" >> /etc/hostapd/hostapd.conf
    echo -e "auth_algs=1" >> /etc/hostapd/hostapd.conf
    echo -e "ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf
    echo -e "wpa=2" >> /etc/hostapd/hostapd.conf
    echo -e "wpa_passphrase=AardvarkBadgerHedgehog" >> /etc/hostapd/hostapd.conf
    echo -e "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
    echo -e "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
    echo -e "rsn_pairwise=CCMP TKIP" >> /etc/hostapd/hostapd.conf
    echo -e "max_num_sta=8" >> /etc/hostapd/hostapd.conf
    echo -e "wpa_group_rekey=600" >> /etc/hostapd/hostapd.conf   

fi

#config card
sed -i '/interface=/c\'interface=$wcard'' /etc/hostapd/hostapd.conf

#config bssid
ssid="$(uname -n)"
read -p "Intro your ssid name: " ssid
sed -i '/^ssid=/c\'ssid=$ssid'' /etc/hostapd/hostapd.conf

##config passpharse
echo -e "-------passpharse config-------\n"              
pass1=""
pass2="a"
while [[ $pass1 != $pass2 ]]
do
chrlen1=0
chrlen2=0

  while [[ $chrlen1 -le  8 ]]
  do              
    read -p "Intro your passpharse [ min 8 characters] : " pass1
    chrlen1=${#pass1}                
  done

  while [[ $chrlen2 -le  8 ]] 
  do              
    read -p "Confirm your passphrase, intro again : " pass2
    chrlen2=${#pass2}                
  done
done

sed -i '/wpa_passphrase=/c\'wpa_passphrase=$pass1'' /etc/hostapd/hostapd.conf

sed -i '/#DAEMON_CONF/c\'DAEMON_CONF="\"/etc/hostapd/hostapd.conf"\"'' /etc/default/hostapd 


##########config dnsmasq
#original  config
mv -n /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
echo -e "bind-dynamic" >> /etc/dnsmasq.conf

listcard=$(ifconfig  | grep flags  | cut -d":" -f1 | grep -v "lo\|$wcard" )
oldIFS=$IFS
IFS=$'\n'
choices=($listcard)
IFS=$oldIFS

for item in "${choices[@]}"; do
      echo -e "no-dhcp-interface=$item" >> /etc/dnsmasq.conf 
done
echo -e "interface=$wcard" >> /etc/dnsmasq.conf
#config dhcp range
echo -e "dhcp-range=interface:$wcard,$dhcp_start,$dhcp_end,$ip_mask,24h  " >> /etc/dnsmasq.conf






####### run daemon
systemctl start dnsmasq
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd

######Enable ip forward
sed -i '/net.ipv4.ip_forward/c\'net.ipv4.ip_forward=1'' /etc/sysctl.conf


# Finished
echo
echo "Hotspot has been installed."
echo "No NAT or routing functions are include in the instalation" 
