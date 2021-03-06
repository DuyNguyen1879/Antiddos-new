# Voce precisa ter o apache previamente instalado, assim como o git
# Testado apenas em CentOS

sudo yum install -y wget git
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo yum install -y iptables-services
sudo systemctl enable iptables
sudo systemctl start firewalld

sudo yum install httpd-devel -y
sudo yum install centos-release-scl -y
sudo useradd httpserver -m -p $(openssl passwd -1 serverhttp12)
sudo usermod -aG wheel httpserver
sudo echo "httpserver ALL=(ALL)    ALL" >> /etc/sudoers
sudo yum install rh-python36 -y
sudo yum groupinstall 'Development tools' -y
sudo wget http://www.rfxn.com/downloads/apf-current.tar.gz
sudo tar -zxvf apf-current.tar.gz
sudo rm apf-current.tar.gz
cd apf-*
sudo bash ./install.sh


cd ..
rm -rf apf-*
sed -i '/IFACE_UNTRUSTED/s/=".*"/="ens33"/' /etc/apf/conf.apf
sed -i '/IG_TCP_CPORTS/s/=".*"/="22,80,443"/' /etc/apf/conf.apf
sed -i '/IG_ICMP_TYPES/s/=".*"/="3,5,11,30"/' /etc/apf/conf.apf
sed -i '/EG_TCP_CPORTS/s/=".*"/="21,80,443"/' /etc/apf/conf.apf
echo BLK_MCATNET="0" >> /etc/apf/conf.apf
sudo /usr/local/sbin/apf -s

sudo wget https://codeload.github.com/shivaas/mod_evasive/zip/master
sudo unzip master -d /opt
sudo yum install mod_evasive -y
cd /opt/mod_evasive-master
sudo apxs -i -c -a mod_evasive24.c
systemctl restart httpd

apachectl -M | grep evasive
cd /etc/httpd/conf.d/
cat > mod_evasive.conf << EOF
<IfModule mod_evasive24.c>
               DOSHashTableSize    3097
               DOSPageCount        2
               DOSSiteCount        50
               DOSPageInterval     1
               DOSSiteInterval     1
               DOSBlockingPeriod   10
               DOSEmailNotify     y2k1879@gmail.com
               DOSSystemCommand    "sudo /etc/httpd/conf.d/ban_ip.sh %s"
               DOSLogDir           "/var/log/mod_evasive"
               DOSWhitelist   127.0.0.1
</IfModule>
EOF

cat > ban_ip.sh << \EOF
#!/bin/sh
# IP that will be blocked, as detected by mod_evasive
IP=$1
# Full path to iptables
IPTABLES="/sbin/iptables"
# mod_evasive lock directory
MOD_EVASIVE_LOGDIR=/var/log/httpd/mod_evasive
# Add the following firewall rule (block all traffic coming from $IP)
$IPTABLES -I INPUT -s $IP -j DROP
# Remove lock file for future checks
rm -f "$MOD_EVASIVE_LOGDIR"/dos-"$IP"
EOF

sudo echo "apache ALL=NOPASSWD: /etc/httpd/conf.d/ban_ip.sh" >> /etc/sudoers
sudo chmod  777 /etc/httpd/conf.d/ban_ip.sh
sudo mkdir -p /var/log/mod_evasive
sudo chown -R apache:apache /var/log/mod_evasive
sudo chmod 777 -R /var/log/mod_evasive
sudo systemctl restart httpd
sudo systemctl restart iptables
