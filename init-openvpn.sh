#!/bin/bash
##centos7安装openvpn脚本
##
sourceinstall=/usr/local/src/openvpn
chmod -R 777 $sourceinstall
##时间时区同步，修改主机名
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ntpdate ntp1.aliyun.com
hwclock --systohc
echo "*/30 * * * * root ntpdate ntp1.aliyun.com" >> /etc/crontab

sed -i 's|SELINUX=.*|SELINUX=permissive|' /etc/selinux/config
sed -i 's|SELINUX=.*|SELINUX=permissive|' /etc/sysconfig/selinux 

rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid

yum -y install epel-release
yum -y install openssl openssl-devel lzo lzo-devel pam pam-devel automake pkgcon
yum install -y openvpn
yum install -y easy-rsa

mkdir -pv /etc/openvpn/
cp -R /usr/share/easy-rsa/ /etc/openvpn/
cp /usr/share/doc/openvpn-2.4.7/sample/sample-config-files/server.conf /etc/openvpn/
cp -r /usr/share/doc/easy-rsa-3.0.3/vars.example /etc/openvpn/easy-rsa/3.0.3/vars
#cp /usr/share/doc/openvpn-2.4.7/sample/sample-scripts/bridge-start  /etc/openvpn/
#cp /usr/share/doc/openvpn-2.4.7/sample/sample-scripts/bridge-stop  /etc/openvpn/

echo 'local 192.168.10.100
;port 1194
port 2195
;proto udp
proto tcp
dev tun
ca /etc/openvpn/easy-rsa/3.0.3/pki/ca.crt
cert /etc/openvpn/easy-rsa/3.0.3/pki/issued/wwwserver.crt
key /etc/openvpn/easy-rsa/3.0.3/pki/private/wwwserver.key
dh /etc/openvpn/easy-rsa/3.0.3/pki/dh.pem
tls-auth /etc/openvpn/ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 202.103.24.68"
push "dhcp-option DNS 114.114.114.114"
push "route 192.168.10.0 255.255.255.0"
client-to-client
keepalive 10 120
cipher AES-256-CBC
tls-auth ta.key 0 
comp-lzo
max-clients 100
user openvpn
group openvpn
persist-key
persist-tun
status openvpn-status.log
log-append openvpn.log
verb 3
mute 20
'> /etc/openvpn/server.conf


sed -i '45c set_var EASYRSA "$PWD"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '65c set_var EASYRSA_PKI             "$EASYRSA/pki"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '76c set_var EASYRSA_DN      "cn_only"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '84c set_var EASYRSA_REQ_COUNTRY    "CN"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '85c set_var EASYRSA_REQ_PROVINCE   "HUBEI"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '86c set_var EASYRSA_REQ_CITY       "WUHAN"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '87c set_var EASYRSA_REQ_ORG        "OpenVPN-CERTIFICATE-AUTHORITY"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '88c set_var EASYRSA_REQ_EMAIL      "me@example.net"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '89c set_var EASYRSA_REQ_OU         "OpenVPN EASY CA"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '97c set_var EASYRSA_KEY_SIZE       2048' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '105c set_var EASYRSA_ALGO           rsa' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '113c set_var EASYRSA_CA_EXPIRE      3650' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '117c set_var EASYRSA_CERT_EXPIRE    3650' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '134c set_var EASYRSA_NS_SUPPORT     "no"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '139c set_var EASYRSA_NS_COMMENT     "OpenVPN-CERTIFICATE-AUTHORITY"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '171c set_var EASYRSA_EXT_DIR        "$EASYRSA/x509-types"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '180c set_var EASYRSA_SSL_CONF       "$EASYRSA/openssl-1.0.cnf"' /etc/openvpn/easy-rsa/3.0.3/vars 
sed -i '192c set_var EASYRSA_DIGEST         "sha256"' /etc/openvpn/easy-rsa/3.0.3/vars 

#创建CA,         设置CA密码：sanxinca.com；设置Easy-RSA CA：OpenVPN-CERTIFICATE-AUTHORITY
cd /etc/openvpn/easy-rsa/3.0.3/
./easyrsa init-pki
source vars
./easyrsa gen-dh
openvpn --genkey --secret ta.key
cp -r ta.key /etc/openvpn/


echo "now let's begin /etc/openvpn/easy-rsa/3.0.3/easyrsa build-ca"
if [ ! -e /usr/bin/expect ] 
 then  yum install expect -y 
fi
echo '#!/usr/bin/expect
set timeout 60
set CAPASSWD [lindex $argv 0 ] 
set VCAPASSWD [lindex $argv 1 ] 
set EASYPASSWD [lindex $argv 2 ]
spawn /etc/openvpn/easy-rsa/3.0.3/easyrsa build-ca
expect {
"Enter PEM pass phrase" {send "$CAPASSWD\r";exp_continue}
"Verifying - Enter PEM pass phrase" {send "$VCAPASSWD\r";exp_continue}
"*Easy-RSA CA*" {send "$EASYPASSWD\r"}
}
interact ' > build-ca.exp 
chmod +x build-ca.exp
./build-ca.exp sanxinca.com sanxinca.com OpenVPN-CERTIFICATE-AUTHORITY
sleep 3
rm -rf build-ca.exp

#创建服务端证书  设置server密码：openserver.com 设置wwwserver：OpenVPN-CERTIFICATE-AUTHORITY
echo "now let's begin /etc/openvpn/easy-rsa/3.0.3/easyrsa gen-req wwwserver"
if [ ! -e /usr/bin/expect ] 
 then  yum install expect -y 
fi
echo '#!/usr/bin/expect
set timeout 60
set CAPASSWD [lindex $argv 0 ] 
set VCAPASSWD [lindex $argv 1 ] 
set EASYPASSWD [lindex $argv 2 ]
spawn /etc/openvpn/easy-rsa/3.0.3/easyrsa gen-req wwwserver
expect {
"Enter PEM pass phrase" {send "$CAPASSWD\r";exp_continue}
"Verifying - Enter PEM pass phrase" {send "$VCAPASSWD\r";exp_continue}
"*wwwserver*" {send "$EASYPASSWD\r"}
}
interact ' > wwwserver.exp 
chmod +x wwwserver.exp
./wwwserver.exp openserver.com openserver.com OpenVPN-CERTIFICATE-AUTHORITY
sleep 3
rm -rf  wwwserver.exp


#签发证书,签约服务端证书 输入yes签发证书，输入ca密码：sanxinca.com
echo "now let's begin /etc/openvpn/easy-rsa/3.0.3/easyrsa sign-req server wwwserver "
if [ ! -e /usr/bin/expect ] 
 then  yum install expect -y 
fi
echo '#!/usr/bin/expect
set timeout 60
set CAPASSWD [lindex $argv 0 ] 
spawn /etc/openvpn/easy-rsa/3.0.3/easyrsa sign-req server wwwserver 
expect {
"Confirm request details" {send "yes\r";exp_continue}
"Enter pass phrase for /etc/openvpn/easy-rsa/3.0.3/pki/private/ca.key" {send "$CAPASSWD\r"}
}
interact ' > sign-req.exp 
chmod +x sign-req.exp
./sign-req.exp sanxinca.com 
sleep 3
rm -rf  sign-req.exp


#生成windows客户端用户：设置密码（123456） 注：结束前会提示输入ca密码：sanxinca.com
echo "now let's begin /etc/openvpn/easy-rsa/3.0.3/easyrsa build-client-full www001"
if [ ! -e /usr/bin/expect ] 
 then  yum install expect -y 
fi
echo '#!/usr/bin/expect
set timeout 60
set CLPASSWD [lindex $argv 0 ] 
set VCLPASSWD [lindex $argv 1 ] 
set CAPASSWD [lindex $argv 2 ] 
spawn /etc/openvpn/easy-rsa/3.0.3/easyrsa build-client-full www001
expect {
"Enter PEM pass phrase" {send "$CLPASSWD\r";exp_continue}
"Verifying - Enter PEM pass phrase" {send "$VCLPASSWD\r";exp_continue}
"Enter pass phrase for /etc/openvpn/easy-rsa/3.0.3/pki/private/ca.key" {send "$CAPASSWD\r"}
}
interact ' > client.exp 
chmod +x client.exp
./client.exp 123456 123456 sanxinca.com
sleep 3
rm -rf  client.exp

#开启网卡转发
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf 
sysctl -p 

#添加防火墙规则
systemctl start firewalld.service
firewall-cmd --state
firewall-cmd --zone=public --list-all
firewall-cmd --add-service=openvpn --permanent
firewall-cmd --add-port=2195/tcp --permanent
firewall-cmd --add-port=22/tcp --permanent
firewall-cmd --add-source=10.8.0.0 --permanent
firewall-cmd --query-source=10.8.0.0 --permanent
firewall-cmd --add-masquerade --permanent
firewall-cmd --query-masquerade --permanent
systemctl restart firewalld
firewall-cmd --list-all

#配置nat转发(注意修改网卡名称)
iptables -t nat -A POSTROUTING -o ens192 -j MASQUERADE 
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o ens192 -j MASQUERADE

#启动openvpn： 启动时输入服务端证书密码：openserver.com
setenforce permissive
getenforce
systemctl start openvpn@server
ps -aux |grep openvpn

#windows 64位官网下载就可以,客户端需要的证书：www001.crt、www001.key、ca.crt、ta.key
mkdir -p /etc/openvpn/client
cp -r /etc/openvpn/easy-rsa/3.0.3/pki/issued/www001.crt /etc/openvpn/client/
cp -r /etc/openvpn/easy-rsa/3.0.3/pki/private/www001.key /etc/openvpn/client/
cp -r /etc/openvpn/easy-rsa/3.0.3/pki/ca.crt /etc/openvpn/client/
cp -r /etc/openvpn/ta.key /etc/openvpn/client/
#客户端配置文件www001.ovpn（ip换为openvpn服务器外网ip）
echo 'client
dev tun
proto tcp
resolv-retry infinite
nobind
remote 192.168.10.100 2195 
ns-cert-type server
comp-lzo
ca ca.crt
cert www001.crt
key www001.key
tls-auth ta.key 1
keepalive 10 120
persist-key
persist-tun
verb 5
redirect-gateway
route-method exe
route-delay 2
status www001-status.log
log-append www001.log
' > /etc/openvpn/client/www001.ovpn
#安装OpenVPN客户端后，清空config文件夹，将www001.crt、www001.key、ca.crt、ta.key、www001.ovpn放入config中

#注意：服务器先开桥接，再启openvpn；先关闭openvpn，再桥接。