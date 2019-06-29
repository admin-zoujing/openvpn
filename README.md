# openvpn

Linux系统中，OpenVPN是一款性能良好的开源VPN，因而受到广泛的使用，不过最近有许多用户发现OpenVPN服务多次异常退出，这个问题该怎么解决呢？今天小编就教大家如何解决这个问题。

Linux系统Openvpn进程异常退出怎么办？

　　问题原因分析：

　　1. openvpn 服务器（虚拟机）的 内存不够了 因为只有 2G 内存

　　2. I/O过高，因为日志开启了 DEBUG 的原因，大量写日志操作，

　　3. 打开文件描述符不够，系统默认 1024

　　4. 有人恶意攻击openvpn 服务

　　根据猜测的4点，开始应对：

　　1. 首选把openpvn服务器（虚拟机）内存调整到了4G，重启后发现openvpn 服务在启动后的 几分钟还是异常掉，

　　2. 把日志调整为 error ，openvpn 在启动后 几分钟还是异常退出了。查看日志发现是

　　Feb 18 17:17:42 localhost openvpn［1219］： qn_anqiu/xxx.xxx.xxx.xx:27351 CRL： cannot read： /usr/local/cine/etc/keys/crl.pem： Too many open files （errno=24）

　　3. 有上面的错误日志提示，说明猜想的 第三点是对的。 执行命令：

　　shell $》 ulimit -SHn 65535

　　在启动 openvpn 进程后，正常了没有再次退出了。

　　4. 查看日志 发现有一个 IP 每分钟都在非正常请求 openvpn 服务器，直接在 iptables 过滤掉此IP

　　Feb 16 13:06:16 localhost openvpn［1219］： 58.244.191.51:47374 WARNING： Bad encapsulated packet length from peer （18245）， which must be 》 0 and 《 = 1544 -- please ensure that --tun-mtu or --link-mtu is equal on both peers -- this condition could also indicate a possible active attack on the TCP link -- ［Attemping restart.。。］

　　Feb 16 13:07:21 localhost openvpn［1219］： 58.244.191.51:6043 WARNING： Bad encapsulated packet length from peer （18245）， which must be 》 0 and 《 = 1544 -- please ensure that --tun-mtu or --link-mtu is equal on both peers -- this condition could also indicate a possible active attack on the TCP link -- ［Attemping restart.。。］

　　经过上面的修改，经过两天后 openvpn 还是异常掉了一次，经过查看日志还是老问题：

　　Feb 18 17:17:42 localhost openvpn［1219］： qn_anqiu/xxx.xxx.xxx.xx:27351 CRL： cannot read： /usr/local/cine/etc/keys/crl.pem： Too many open files （errno=24）

　　就算打开文件描述符进程也不应该掉啊，这说明是openvpn 的 BUG， crl.pem 该文件里存的是注销的证书，如果是注销的证书验证是不能通过，openvpn服务就会拒绝连接，我目前有 800多个客户端来连接，难道是每个连接都要请求该文件没有释放吗？就算没有释放65535 个文件描述符还是不够么？

　　为了解决问题只好修改配置文件把这个验证注销证书的参数去掉，在重启 openvpn 进程，就正常了再也没有出现过问题。具体如何产生还需要进一步观察和研究。

　　这就是解决OpenVPN服务出现多次异常退出的方法了，有遇到这种问题的用户，不妨试试小编的这种解决方法吧。
