# 关于DNS

## 概述：
 
 <div align=center>
    <img src="http://ww2.sinaimg.cn/large/006tNc79gy1g3dik8zwa0j30ex05lglh.jpg" width="50%"/>
    <br>
 </div>

&emsp;&emsp;人们喜欢便于记忆的的主机名标识方式，而路由器则喜欢定长的、有层次结构的IP地址。为了折中这些不同的偏好，我们需要一种能进行主机名到IP地址转换的目录服务。这就是**域名系统（DNS）**。  

&emsp;&emsp;DNS：

* 一个由分层的DNS服务器实现的分布式数据库。
* 一个使得主机能够查询分布式数据库的应用层协议。

&emsp;&emsp;DNS协议运行在**UDP**之上，默认使用53号端口。  
&emsp;&emsp;DNS通常是由其他应用层协议所使用的，包括HTTP，SMTP和FTP，将用户提供的主机名解析为IP地址。除了进行主机名到IP地址的转换外，DNS还提供**主机别名服务（CName）**。

## 原理：

 <div align=center>
    <img src="http://ww3.sinaimg.cn/large/006tNc79gy1g3djpoy8tfj304s06kmx2.jpg" width="15%"/>
    <br>
 </div>

&emsp;&emsp;需要使用DNS服务的应用进程调用DNS进程，指明需要被转换的主机名。用户主机上的DNS接收到后，向网络中发送一个DNS查询报文。所有的DNS请求和回答报文使用UDP数据报经端口53发送。经过若干毫秒的时延后，用户主机上的DNS进程收到一个DNS回答报文。映射的结果将被传递到调用DNS进程的应用进程。因此，从用户主机上调用应用程序的角度看，DNS是一个提供简单、直接的转换服务的黑盒子。  
&emsp;&emsp;

