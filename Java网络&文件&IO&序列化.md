### 网络基础概念

#### 网络、分组报文、协议

计算机网络：通信信道和主机(hosts)和路由器(routers)相互连接组成

主机：指运行应用程序的计算机，这些应用程序包括网络浏览器(Web browser)，即时通讯代理(IM agent)，或者是文件共享程序

路由器：将信息从一个通信信道传递或转发(forward)到另一个通信信道，一些主机先连接到路由器，路由器再连接到其他路由器，这样就形成了网络。这种布局使每个主机只需要用到数量相对较少的通信信道

通信信道(communication channel)：将字节序列从一个主机传输到另一个主机的一种手段，可能是有线电缆，如以太网(Ethernet)，也可能是无线，如WiFi，或是其他方式的连接

分组报文(packets)：指由程序创建和解释的字节序列，一组报文包括了网络用来完成工作的控制信息，还包括一些用户数据

协议(protocol)：相当于是相互通信的程序间达成的一种约定，它规定了分组报文的交换方式和它们包含的意义。一组协议规定了分组报文的结构(例如报文中的哪一部分表明了其目的地址)以及怎样对报文中所包含的信息进行解析

TCP/IP协议族：通常驻留在主机的操作系统中。应用程序通过套接字API对UDP协议和TCP协议所提供的服务进行访问。数据流从一个应用程序，经过TCP协议层和IP协议层，通过网络，再反向经过IP协议层和TCP协议层传输到另一端的应用程序

网络层：TCP/IP协议族中的IP协议属于网络层，它使两个主机间的一系列通信信道和路由器看起来像是一条单一的主机到主机的信道。IP协议提供了一种数据报服务，每组分组报文都由网络独立处理和分发，为了实现这个功能，每个IP报文必须包含一个保存其目的地址(address)的字段。IP协议只是一个"尽力而为"(best-effort)的协议，它试图分发每一个分组报文，但在网络传输过程中，偶尔也会发生丢失报文，使报文顺序被打乱，或重复发送报文的情况

传输层：提供了两种可选择的协议，TCP协议和UDP协议。这两种协议都建立在IP层所提供的服务基础上，但根据应用程序协议(application
protocols)的不同需求，它们使用了不同的方法来实现不同方式的传输。TCP协议和UDP协议有一个共同的功能，即寻址。IP协议将分组报文分发到了不同的主机，因为同一主机上可能有多个应用程序在使用网络。TCP协议和UDP协议使用的地址叫做端口号(port numbers)，使用端口号来区分同一主机中的不同应用程序。TCP协议和UDP协议也称为端到端传输协议(end-to-end transport protocols)，因为它们将数据从一个应用程序传输到另一个应用程序，而IP协议只是将数据从一个主机传输到另一主机。TCP协议能够检测和恢复IP层提供的主机到主机的信道中可能发生的报文丢失、重复及其他错误。TCP协议提供了一个可信赖的字节流(reliable byte-stream)信道，这样应用程序就不需要再处理上述的问题。TCP协议是一种面向连接(connection-oriented)的协议，在使用它进行通信之前，两个应用程序之间首先要建立一个TCP连接，这涉及到相互通信的两台主机的TCP部件间完成的握手消息(handshake messages)的交换。使用TCP协议在很多方面都与文件的输入输出(I/O，Input/Output)相似。实际上，由一个程序写入的文件再由另一个程序读取就是一个TCP连接的适当模型。另一方面，UDP协议并不尝试对IP层产生的错误进行修复，它仅仅简单地扩展了IP协议"尽力而为"的数据报服务，使它能够在应用程序之间工作，而不是在主机之间工作。因此，使用了UDP协议的应用程序必须为处理报文丢失、顺序混乱等问题做好准备

#### 地址

一个程序要与另一个程序通信，就要给网络提供足够的信息，使其能够找到另一个程序。在TCP/IP协议中，有两部分信息用来定位，互联网地址(Internet address)和端口号(port number)。其中互联
网地址由IP协议使用，而附加的端口地址信息由传输协议(TCP或IP协议)对其进行解析

互联网地址由二进制的数字组成，有两种型式，分别对应了两个版本的标准互联网协议，即IPv4和IPv6。IPv4的地址长32位，IPv6的地址长128位。IPv4地址被表示为一组4个十进制数，每两个数字之间由圆点隔开(如：10.1.2.3)，这种表示方法叫做点分形式(dotted-quad)。点分形式字符串中的4个数字代表了互联网地址的4个字节，也就是说，每个数字的范围是0到255。IPv6地址的16个字节由几组16进制的数字表示，这些16进制数之间由冒号隔开(如：2000:fdb8:0000:0000:0001:00ab:853c:39a1)。每组数字分别代表了地址中的两个字节，并且每组开头的0可以省略

TCP或UDP协议中的端口号总与一个互联网地址相关联。端口号是一组16位的无符号二进制数，每个端口号的范围是1到65535(0被保留)

每个版本的IP协议都定义了一些特殊用途的地址。其中值得注意的一个是回环地址(loopback address)，该地址总是被分配个一个特殊的回环接口(loopback interface)。回环接口是一种虚拟设备，它的功能只是简单地将发送给它的报文直接回发给发送者。回环接口在测试中非常有用，因为发送给这个地址的报文能够立即返回到目标地址。而且每台主机上都有回环接口，即使当这台计算机没有其他接口(也就是说没有连接到网络)，回环接口也能使用。IPv4的回环地址是127.0.0.1，IPv6的回环地址是0:0:0:0:0:0:0:1

IPv4地址中的另一种特殊用途的保留地址包括那些"私有用途"的地址。它们包括IPv4中所有以10或192.168开头的地址，以及第一个数是172，第二个数在16到31的地址。(在IPv6中没有相应的这类地址)这类地址最初是为了在私有网络中使用而设计的，不属于公共互联网的一部分。通过NAT(Network Address Translation，网络地址转换)设备连接到互联网。NAT设备的功能就像一个路由器，转发分组报文时将转换(重写)报文中的地址和端口。更准确地说，它将一个接口中报文的私有地址端口对(private address, port pairs)映射成另一个接口中的公有地址端口对(public address, port pairs)。这就使一小组主机(如家庭网络)能够有效地共享同一个IP地址。重要的是这些内部地址不能从公共互联网访问

相关的类型的地址包括本地链接(link-local)，或称为"自动配置"地址。IPv4中，这类地址由169.254开头，在IPv6中，前16位由FE8开头的地址是本地链接地址。这类地址只能用来在连接到同一网络的主机之间进行通信，路由器不会转发这类地址的信息

另一类地址由多播(multicast)地址组成。普通的IP地址(有时也称为"单播"地址)只与唯一一个目的地址相关联，而多播地址可能与任意数量的目的地址关联。IPv4中的多播地址在点分格式中，第一个数字在224到239之间。IPv6中，多播地址由FF开始

#### 域名

互联网协议只能处理二进制的网络地址，而不是域名。当使用域名来进行通信时，系统将做一些额外的工作把域名解析成地址。一是相对于点分形式(或IPv6中的十六进制数字串)，人们更容易记住域名;二是域名提供了一个间接层，使IP地址的变化对用户不可见

域名系统(DNS,Domain Name System)是一种分布式数据库，它将域名映射成真实的互联网地址。DNS协议允许连接到互联网的主机通过TCP或UDP协议从DNS数据库中获取信息

#### 客户端与服务器

客户端(client)和服务器(server)这两个术语代表了两种角色:客户端是通信的发起者，而服务器程序则被动等待客户端发起通信，并对其作出响应。客户端与服务器端的区别非常重要，因为客户端首先需要知道服务器的地址和端口号，反之则不需要

通常情况，客户端使用URL(Universal Resource Locator，统一资源定位符，由协议、主机、端口、路径组成)，再通过域名解析服务获取其相应的互联网地址。获取服务器的端口号则是另一种情况。从原理上来讲，服务器可以使用任何端口号，但客户端必须能够获知这些端口号。在互联网上，一些常用的端口号被约定赋给了某些应用程序。例如，端口号21被FTP(File Transfer Protocol, 文件传输协议)使用

#### 套接字

套接字Socket=(IP地址:端口号)，Socket(套接字)是一种抽象层，应用程序通过它来发送和接收数据，就像应用程序打开一个文件句柄，将数据读写到稳定的存储器上一样。一个socket允许应用程序添加到网络中，并与处于同一个网络中的其他应用程序进行通信。一台计算机上的应用程序向socket写入的信息能够被另一台计算机上的另一个应用程序读取，反之亦然

不同类型的socket与不同类型的底层协议族以及同一协议族中的不同协议栈相关联，现在TCP/IP协议族中的主要socket类型为流套接字(stream sockets)和数据报套接字(datagram sockets)

流套接字将TCP作为其端对端协议(底层使用IP协议)，提供了一个可信赖的字节流服务。一个TCP/IP流套接字代表了TCP连接的一端。数据报套接字使用UDP协议(底层同样使用IP协议)，提供了一个"尽
力而为"(best-effort)的数据报服务，应用程序可以通过它发送最长65500字节的数据。一个TCP/IP套接字由一个互联网地址，一个端对端协议(TCP或UDP协议)以及一个端口号唯一确定

一个套接字抽象层可以被多个应用程序引用。每个使用了特定套接字的程序都可以通过那个套接字进行通信。每个端口都标识了一台主机上的一个应用程序。实际上，**一个端口确定了一台主机上的一个套接字**。主机中的多个程序可以同时访问同一个套接字。在实际应用中，访问相同套接字的不同程序通常都属于同一个应用(例如，Web服务程序的多个拷贝)，但从理论上讲，它们是可以属于不同应用的

### 基本套接字

#### 套接字地址

InetAddress类代表了一个网络目标地址，包括主机名和数字类型的地址信息。该类有两个子类，Inet4Address和Inet6Address,分别对应了目前IP地址的两个版本。InetAddress实例是不可变的，一旦创建，每个实例就始终指向同一个地址

```

import java.net.Inet4Address;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.Enumeration;

public class InetAddressExample {
    public static void main(String[] args) throws SocketException, UnknownHostException {
        /*
        NetworkInterface 用于表示一个网络接口，网络接口指的网络设备的各种接口，
        这可以是一个物理的网络接口，也可以是一个虚拟的网络接口
        而一个网络接口通常由一个 IP 地址来表示。既然 NetworkInterface 用来表示一个网络接口，
        那么如果可以获得当前机器所有的网络接口（包括物理的和虚拟的）
         */
        int interfacesNum = 0;
        int addressesNum = 0;
        Enumeration<NetworkInterface> interfaces = NetworkInterface.getNetworkInterfaces();
        if (interfaces == null) {
            System.out.println("this is no interface");
        } else {
            while (interfaces.hasMoreElements()) {
                NetworkInterface networkInterface = interfaces.nextElement();

                Enumeration<InetAddress> addresses = networkInterface.getInetAddresses();
                interfacesNum += 1;
                System.out.println("第" + interfacesNum + "个网络接口" + networkInterface.getName());
                if (!addresses.hasMoreElements()) {
                    System.out.println("there has not address");
                }
                while (addresses.hasMoreElements()) {
                    addressesNum += 1;
                    InetAddress address = addresses.nextElement();
                    System.out.println(
                            addressesNum + ":" +"IP" + (address instanceof Inet4Address ? "v4" : "v6") + "地址：" +
                                    address.getHostAddress());
                }
            }
        }

        System.out.println("\n\n");

        for (String host : args) {
            System.out.println(host+":");
            InetAddress[] inets=InetAddress.getAllByName(host);
            for(InetAddress inet:inets){
                System.out.println("域名：" + inet.getHostName()+":");
                System.out.println("IP：" + inet.getHostAddress());
                System.out.println("toString:"+inet.toString());
            }
            System.out.println("\n");
        }
    }
}
```

#### TCP套接字

Java为TCP协议提供了两个类:Socket类和ServerSocket类。一个Socket实例代表了TCP连接的一端。一个TCP连接(TCP connction)是一条抽象的双向信道，两端分别由IP地址和端口号确定。在开始通信之前，要建立一个TCP连接，这需要先由客户端TCP向服务器端TCP发送连接请求。ServerSocket实例则监听TCP连接请求，并为每个请求创建新的Socket实例。也就是说，服务器端要同时处理ServerSocket实例和Socket实例，而客户端只需要使用Socket实例

```
//客户端
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.util.concurrent.TimeUnit;

public class TcpEchoClient {
    public static void main(String[] args) throws IOException, InterruptedException {
        //IP地址
        String server = "47.103.7.129";
        //传输数据
        byte[] data = "hello tcp socket".getBytes();
        //端口号
        int serverPort = 8034;
        @SuppressWarnings("resource")
        Socket socket = new Socket(server, serverPort);
        InputStream in = socket.getInputStream();
        OutputStream out = socket.getOutputStream();
        out.write(data);

        byte[] result = new byte[5];

        //因为基于流，所以等待30秒，读取完整数据
        TimeUnit.SECONDS.sleep(10);

        int i = in.read(result);

        System.out.println("length:" + i);
        System.out.println("received:" + new String(result));
        socket.close();
    }
}
```

**TCP协议并不能确定在read()和write()方法中所发送信息的界限，数据可能被TCP协议分割成多个部分**

```
//服务器
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;

public class TcpEchoServer {

    public static void main(String[] args) throws NumberFormatException, IOException, InterruptedException {
        @SuppressWarnings("resource")
        ServerSocket serverSocket = new ServerSocket(8034);

        while (true) {
            Socket socket = serverSocket.accept();
            //SocketAddress socketAddress = socket.getRemoteSocketAddress();
            InputStream in = socket.getInputStream();
            OutputStream out = socket.getOutputStream();

            byte[] data = new byte[200];
            TimeUnit.SECONDS.sleep(10);

            int i = in.read(data);

            System.out.println(new String(data));

            out.write("hello".getBytes(StandardCharsets.UTF_8));

            socket.close();
        }
    }
}
```

**同一个端口只能创建一个ServerSocket实例，否则会报java.net.BindException: Address already in use (Bind failed)**

关闭套接字连接可以释放与连接相关联的系统资源，这对于服务器端来说也是必须的，因为每一个程序所能够打开的Socket实例数量要受到系统限制

#### 输入输出流

Java中TCP套接字的基本输入输出形式是流(stream)抽象。NIO(New I/O)工具提供了另一种替代的抽象形式，流只是一个简单有序的字节序列。Java的输入流(input streams)支持读取字节，而输出流(output streams)则支持写出字节。每个Socket实例都维护了一个InputStream实例和一个OutputStream实例。当向Socket的输出流写了数据后，这些字节最终将能从连接另一端的Socket的输入流中读取

#### UDP套接字

UDP协议提供了一种不同于TCP协议的端到端服务。实际上UDP协议只实现两个功能:1)在IP协议的基础上添加了另一层地址(端口)，2)对数据传输过程中可能产生的数据错误进行了检测，并抛弃已经损坏的数据。由于其简单性，UDP套接字具有一些与TCP套接字不同的特征。UDP套接字在使用前不需要进行连接，每条信息(即数据报文，datagram)负载了自己的地址信息，并与其他信息相互独立。**在接收信息时，UDP套接字扮演的角色就像是一个信箱，从不同地址发送来的信件和包裹都可以放到里面。一旦被创建，UDP套接字就可以用来连续地向不同的地址发送信息，或从任何地址接收信息**

UDP套接字与TCP套接字的另一个不同点在于他们对信息边界的处理方式不同:**UDP套接字将保留边界信息**。这个特性使应用程序在接受信息时，从某些方面来说比使用TCP套接字更简单。最后一个不同点是，UDP协议所提供的端到端传输服务是尽力而为(best-effort)的，即UDP套接字将尽可能地传送信息，但并不保证信息一定能成功到达目的地址，而且信息到达的顺序与其发送顺序不一定一致。因此，使用了UDP套接字的程序必须准备好处理信息的丢失和重排

既然UDP协议为程序带来了这个额外的负担，为什么还会使用它而不使用TCP协议呢?原因之一是效率:如果应用程序只交换非常少量的数据，例如从客户端到服务器端的简单请求消息，或一个反方向的响应消息，TCP连接的建立阶段就至少要传输其两倍的信息量(还有两倍的往返延迟时间)。另一个原因是灵活性:如果除可靠的字节流服务外，还有其他的需求，UDP协议则提供了一个最小开销的平台来满足任何需求的实现

Java通过DatagramPacket类和DatagramSocket类来使用UDP套接字。客户端和服务器端都使用DatagramSockets来发送数据，使用DatagramPackets来接收数据

**与TCP协议发送和接收字节流不同，UDP终端交换的是一种称为数据报文的自包含(self-contained)信息**。这种信息在Java中表示为DatagramPacket类的实例。除传输的信息本身外，每个DatagramPacket实例中还附加了地址和端口信息，其具体含义取决于该数据报文是被发送还是被接收。若是要发送的数据报文，DatagramPacket实例中的地址则指明了目的地址和端口号，若是接收到的数据报文，DatagramPacket实例中的地址则指明了所收信息的源地址

与Socket类不同，DatagramSocket实例在创建时并不需要指定目的地址。这也是TCP协议和UDP协议的最大不同点之一。在进行数据交换前，TCP套接字必须跟特定主机和另一个端口号上的TCP套接字建立连接，之后，在连接关闭前，该套接字就只能与相连接的那个套接字通信。而UDP套接字在进行通信前则不需要建立连接，每个数据报文都可以发送到或接收于不同的目的地址。(DatagramSocket类的connect()方法确实允许指定远程地址和端口，但该功能是可选的)

使用UDP协议的一个后果是数据报文可能丢失，数据报文丢失后，客户端就会永远阻塞在receive()方法上。为了避免这个问题，在客户端使用DatagramSocket类的setSoTimeout()方法来指定receive()方法的最长阻塞时间，因此，如果超过了指定时间仍未得到响应，客户端就会重发回馈请求

```
import java.io.IOException;
import java.io.InterruptedIOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.nio.charset.StandardCharsets;

public class UdpEchoClientTimeout {

    public static void main(String[] args) throws IOException {

        InetAddress address = InetAddress.getByName("47.103.7.129");

        System.out.println(address);

        byte[] data = "hello udp socket".getBytes(StandardCharsets.UTF_8);
        int port = 8034;
        DatagramPacket sendPacket = new DatagramPacket(data, data.length, address, port);
        DatagramSocket datagramSocket = new DatagramSocket();
        int timeOut = 3000;//阻塞时间3秒
        datagramSocket.setSoTimeout(timeOut);
        DatagramPacket recivePacket = new DatagramPacket(new byte[data.length], data.length);
        int tries = 0;
        boolean receivedResponse = false;
        int times = 5;
        do {
            datagramSocket.send(sendPacket);
            try {
                datagramSocket.receive(recivePacket);
                 /*
                 超时会抛出InterruptedIOException
                 */

                //检测收到的Packet是否来自于目标地址
                if (!recivePacket.getAddress().equals(address)) {
                    System.out.println("recive message from a unknow host!");
                }
                receivedResponse = true;
            } catch (InterruptedIOException e) {
                tries++;
                System.out.println("retry " + tries + " time");
            }
        } while (tries < times && !receivedResponse);

        if (receivedResponse) {
            System.out.println("Received:" + new String(recivePacket.getData()));
        } else {
            System.out.println("No response -- give up!");
        }
        datagramSocket.close();

    }
}
```

```
import java.io.IOException;
import java.net.DatagramPacket;
import java.net.DatagramSocket;

public class UdpEchoServer {

    public static void main(String[] args) throws IOException {
        int port = 8034;
        @SuppressWarnings("resource")
        DatagramSocket datagramSocket = new DatagramSocket(port);
        int maxLength = 255;
        DatagramPacket packet = new DatagramPacket(new byte[maxLength], maxLength);
        while (true) {
            datagramSocket.receive(packet);
            System.out.println(
                    "handle client at " + packet.getAddress().getHostAddress() + " on port " + packet.getPort());
            datagramSocket.send(packet);
            /*
            处理了接收到的消息后，数据包的内部长度将设置为刚处理过的消息的长度，
            而这可能比缓冲区的原始长度短。如果接收新消息前不对内部长度进行重置，
            后续的消息一旦长于之前消息，就会被截断（？没有复现出来）
             */
            System.out.println(packet.getLength());
            //packet.setLength(maxLength);
            System.out.println(new String(packet.getData()));
            System.out.println(packet.getData().length);
        }
    }
}
```

#### TCP与UDP的区别

**一个微小但重要的差别是UDP协议保留了消息的边界信息**。DatagramSocket的每一次receive()调用最多只能接收调用一次send()方法所发送的数据。而且，不同的receive()方法调用绝不会返回同一个send()方法调用所发送的数据

当在TCP套接字的输出流上调用的write()方法返回后，所有的调用者都知道数据已经被复制到一个传输缓存区中，实际上此时数据可能已经被传送，也可能还没有被传送。而UDP协议没有提供从网络错误中恢复的机制，因此，并不对可能需要重传的数据进行缓存。这就意味着，当send()方法调用返回时，消息已经被发送到了底层的传输信道中，并正处在(或即将处在)发送途中

消息从网络到达后，其所包含数据被read()方法或receive()方法返回前，数据存储在一个先进先出(first-in, first-out, FIFO)的接收数据队列中。对于已连接的TCP套接字来说，所有已接收但还未传送的字节都看作是一个连续的字节序列。然而，对于UDP套接字来说，接收到的数据可能来自于不同的发送者。一个UDP套接字所接收的数据存放在一个消息队列中，每个消息都关联了其源地址信息。每次receive()调用只返回一条消息

如果receive()方法在一个缓存区大小为n的DatagramPacket实例中调用，而接收队列中的第一条消息长度大于n,则receive()方法只返回这条消息的前n个字节。超出部分的其他字节都将自动被丢弃，而且对接收程序也没有任何消息丢失的提示，出于这个原因，接收者应该提供一个有足够大的缓存空间的DatagramPacket实例，以完整地存放调用receive()方法时应用程序协议所允许的最大长度的消息。这能够保证数据不会丢失。一个DatagramPacket实例中所运行传输的最大数据量为65507字节，即UDP数据报文所能负载的最多数据。因此，使用一个有65600字节左右缓存数组的数据包总是安全的

每一个DatagramPacket实例都包含一个内部消息长度值，而该实例接收到新消息，这个长度值都可能改变(以反映实际接收的消息的字节数)。如果一个应用程序使用同个DatagramPacket实例多次调用receive()方法，每次调用前就必须显式地将消息的内部长度重置为缓存区的实际长度。另一个潜在的问题根源是DatagramPacket类的getData()方法，该方法总是返回缓冲区的原始大小，忽略了实际数据的内部偏移量和长度信息。消息接收到DatagramPacket的缓存区时，只是修改了存放消息数据的地址

### TCP粘包/拆包

TCP是个“流”协议，所谓流，就是没有界限的一串数据。就像河里的流水，它们是连成一片的，其间并没有分界线。TCP底层并不了解上层业务数据的具体含义，它会根据TCP缓冲区的实际情况进行包的划分，所以在业务上认为，一个完整的包可能会被TCP拆分成多个包进行发送，也有可能把多个小的包封装成一个大的数据包发送，这就是所谓的TCP粘包和拆包问题

https://blog.csdn.net/wxy941011/article/details/80428470

#### 问题说明

假设客户端分别发送了两个数据包D1和D2给服务端，由于服务端一次读取到的字节数是不确定的，故可能存在以下5种情况

* 服务端分两次读取到了两个独立的数据包，分别是D1和D2，没有粘包和拆包
* 服务端一次接收到了两个数据包，D1和D2粘合在一起，被称为TCP粘包
* 服务端分两次读取到了两个数据包，第一次读取到了完整的DI包和D2包的部分内容，第二次读取到了D2包的剩余内容，这被称为TCP拆包
* 服务端分两次读取到了两个数据包，第一次读取到了 D1包的部分内容 D1_1，第二次读取到了D1包的剩余内容DI_2和D2包的整包
* 如果此时服务端TCP接收滑窗非常小，而数据包D1和D2比较大，很有可能会发生第5种可能，即服务端分多次才能将D1和D2包接收完全，期间发生多次拆包

#### TCP粘包/拆包发生的原因

* 应用程序write写入的字节大小大于套接口发送缓冲区大小
* 进行MSS大小的TCP分段
* 以太网帧的payload大于MTU进行IP分片

#### 粘包问题的解决策略

由于底层的TCP无法理解上层的业务数据，所以在底层是无法保证数据包不被拆分和重组的，这个问题只能通过上层的应用协议栈设计来解决，根据业界的主流协议的解决方案，可以归纳如下

* 消息定长，例如每个报文的大小为固定长度200字节，如果不够，空位补空格
* 在包尾增加回车换行符进行分割，例如FTP协议
* 将消息分为消息头和消息体，消息头中包含表示消息总长度(或者消息体长度)的字段，通常设计思路为消息头的第一个字段使用int32来表示消息的总长度
* 更复杂的应用层协议

### 多线程优化

#### 执行线程

```
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.Socket;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

public class EchoProtocol implements Runnable {
    private static final int BUFSIZE = 32;
    private final Socket clientSocket;
    private final Logger logger;

    public EchoProtocol(Socket clientSocket, Logger logger) {
        super();
        this.clientSocket = clientSocket;
        this.logger = logger;
    }

    public static void handleEchoClient(Socket clientSocket, Logger logger) {
        try {
            InputStream in = clientSocket.getInputStream();
            OutputStream out = clientSocket.getOutputStream();

            byte[] reciveBuff = new byte[BUFSIZE];

            int recive = in.read(reciveBuff);

            TimeUnit.SECONDS.sleep(3);

            out.write(reciveBuff, 0, recive);

        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            logger.log(Level.WARNING, "exception in echo protocol", e);
        } finally {
            try {
                clientSocket.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

    }

    @Override
    public void run() {
        handleEchoClient(clientSocket, logger);
    }

}
```

#### 一客户一线程(thread-per-client)

即为每一个客户端连接创建一个执行线程

```
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.logging.Logger;

public class TCPEchoServerThread {
    private final static int serverPort = 8034;

    public static void main(String[] args) throws IOException {
        @SuppressWarnings("resource")
        ServerSocket serverSocket = new ServerSocket(serverPort);

        Logger logger = Logger.getLogger("practical");
        while (true) {
            Socket socket = serverSocket.accept();
            Thread thread = new Thread(new EchoProtocol(socket, logger));
            thread.start();
            logger.info("Create and started Thread :" + thread.getName());
        }
    }
}
```

#### 线程池(thread pool)

```
//手工创建
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.logging.Level;
import java.util.logging.Logger;

public class TCPEchoServerPool {
        private static final int serverPort = 8034;

    public static void main(String[] args) throws IOException {
        Logger logger = Logger.getLogger("practical");
        @SuppressWarnings("resource")
        ServerSocket serverSocket = new ServerSocket(serverPort);
        for (int i = 0; i < 10; i++) {
            Thread thread = new Thread(new Runnable() {
                @Override
                public void run() {
                    while (true) {
                        try {
                            Socket clientSocket = serverSocket.accept();
                            System.out.println(Thread.currentThread().getName() + " handle clientSocket");
                            EchoProtocol.handleEchoClient(clientSocket, logger);
                        } catch (IOException e) {
                            logger.log(Level.WARNING, "handle clientSocket failed", e);
                        }
                    }
                }
            });
            thread.start();
        }
    }
}
```

```
//Executor
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.logging.Logger;

public class TCPEchoServerExecutor {
    private static final int serverPort = 8034;

    public static void main(String[] args) throws IOException {
        ExecutorService exec = Executors.newCachedThreadPool();
        @SuppressWarnings("resource")
        ServerSocket serverSocket = new ServerSocket(serverPort);
        Logger logger = Logger.getLogger("practical");
        while (true) {
            Socket clientSocket = serverSocket.accept();
            exec.execute(new EchoProtocol(clientSocket, logger));
            logger.info(" handle clientSocket!");
        }
    }
}
```

### I/O

在JDK 1.4推出Java NIO之前，基于Java的所有Socket通信都采用了同步阻塞模式(BIO)，这种一请求一应答的通信模型简化了上层的应用开发，但是在性能和可靠性方面却存在着巨大的瓶颈。因此，在很长一段时间里，大型的应用服务器都采用C或者C++语言开发，因为它们可以直接使用操作系统提供的异步I/O或者AIO能力。当并发访问量增大、响应时间延迟增大之后，采用JavaBIO开发的服务端软件只有通过硬件的不断扩容来满足高并发和低时延，它极大地增加了企业的成本，并且随着集群规模的不断膨胀，系统的可维护性也面临巨大的挑战，只能通过采购性能更高的硬件服务器来解决问题，这会导致恶性循环

最终，JDK1.4 版本提供了新的NIO类库，Java终于也可以支持非阻塞I/O了

#### 概念澄清

##### 异步非阻塞I/O

很多人喜欢将JDK1.4提供的NIO框架称为异步非阻塞I/O，但是，如果严格按照UNIX网络编程模型和JDK的实现进行区分，实际上它只能被称为非阻塞l/O，不能叫异步非阻塞I/O。在早期的JDK 1.4和1.5 update10版本之前，JDK的Selector基于select/poll模型实现，它是基于I/O复用技术的非阻塞I/O，不是异步I/O。在JDK 1.5 update10和Linux core2.6以上版本，Sun优化了Selctor的实现，它在底层使用epoll替换了select/poll，上层的API并没有变化，可以认为是JDK NIO的一次性能优化，但是它仍旧没有改变I/O的模型

由JDK1.7提供的NIO2.0新增了异步的套接字通道，它是真正的异步I/O，在异步I/O操作的时候可以传递信号变量，当操作完成之后会回调相关的方法，异步I/O也被称为AIO。NIO类库支持非阻塞读和写操作，相比于之前的同步阻塞读和写，它是异步的，因此很多人习惯于称NIO为异步非阻塞I/O，包括很多介绍NIO编程的书籍也沿用了这个说法。不要过分纠结在一些技术术语的咬文嚼字上

##### 多路复用器Selector
几乎所有的中文技术书籍都将Selector翻译为选择器，但是实际上这样的翻译并不恰当，选择器仅仅是字面上的意思，体现不出Selector的功能和特点。Java NIO的实现关键是多路复用I/O技术，多路复用的核心就是通过Selector来轮询注册在其上的Channel，当发现某个或者多个Channel处于就绪状态后，从阻塞状态返回就绪的Channel的选择键集合，进行I/O操作。由于多路复用器是NIO实现非阻塞I/O的关键，它又是主要通过Selector实现的，将Selector翻译为多路复用器，与其他技术书籍所说的选择器是同一个东西

### NIO

Java NIO(New IO)是一个可以替代标准Java IO API的IO API（从Java 1.4开始)，Java NIO提供了与标准IO不同的IO工作方式

* Channels and Buffers（通道和缓冲区）

标准的IO基于字节流和字符流进行操作的，而NIO是基于通道（Channel）和缓冲区（Buffer）进行操作，数据总是从通道读取到缓冲区中，或者从缓冲区写入到通道中

* Non-blocking IO（非阻塞IO）

Java NIO可以非阻塞的使用IO

* Selectors（选择器）

Java NIO引入了选择器的概念，选择器用于监听多个通道的事件（比如：连接打开，数据到达）。因此，单个的线程可以监听多个数据通道

#### 概述

Java NIO 由以下几个核心部分组成：

* Channels
* Buffers
* Selectors

Java NIO中除此之外还有很多类和组件，如Pipe和FileLock

#### Buffer

数据可以从Channel读到Buffer中，也可以从Buffer写到Channel中

Java NIO里关键的Buffer实现：

* ByteBuffer
* CharBuffer
* DoubleBuffer
* FloatBuffer
* IntBuffer
* LongBuffer
* ShortBuffer

这些Buffer覆盖了能通过IO发送的基本数据类型。Java NIO还有个MappedByteBuffer，用于表示内存映射文件

Java NIO中的Buffer用于和NIO通道进行交互。数据是从通道读入缓冲区，从缓冲区写入到通道中的。缓冲区本质上是一块可以写入数据，然后可以从中读取数据的内存。这块内存被包装成NIO Buffer对象，并提供了一组方法，用来方便的访问该块内存

作为数据的"容器"，缓冲区既可用来输入也可用来输出。这一点就与流不同，流只能向一个方向传递数据

##### Buffer的创建

```
//指定容量
ByteBuffer buf = ByteBuffer.allocate(48);
```
或者
```
//包装数组
byte[] data = "hello".getBytes();
ByteBuffer buf = ByteBuffer.wrap(data);
```

缓冲区都是定长的，因此无法扩展或缩减它们的容量。如果发现刚创建的缓冲区容量太小，惟一的选择就是重新创建一个大小合适的缓冲区

##### 向Buffer中写数据

写数据到Buffer有两种方式：

* 从Channel写到Buffer

```
int bytesRead = inChannel.read(buf); //read into buffer.

```

信道的read()方法隐式调用了给定缓冲区的put()方法

* 通过Buffer的put()方法写到Buffer里

```
buf.put(127);
```

##### 从Buffer中读取数据

从Buffer中读取数据有两种方式：

* 从Buffer读取数据到Channel

```
//read from buffer into channel.
int bytesWritten = inChannel.write(buf);
```

信道的write()方法隐式调用了给定缓冲区的get()方法

* 使用get()方法从Buffer中读取数据

```
byte aByte = buf.get();
byte[] bytes = buf.array();
```

##### 字符编码

字符是由字节序列进行编码的，而且在字节序列与字符集合之间有各种映射(称为字符集)方式。NIO缓冲区的另一个用途是在各种字符集之间进行转换。要使用这个功能，还需要了解java.nio.charset包中另外两个类: CharsetEncoder和CharsetDecoder类

##### Buffer原理

在读写数据时，Buffer有内部索引来跟踪缓冲区的当前位置，以及有效可读数据的结束位置等

| 索引 | 描述 |
| :----: | :----: |
| capacity | 缓冲区中的元素总数(不可修改) |
| position | 下一个要读/写的元素(从0开始) |
| limit | 第一个不可读/写元素 |
| mark | 用户选定的position的前一个位置，或0 |

position和limit的含义取决于Buffer处在读模式还是写模式。不管Buffer处在什么模式，capacity的含义总是一样的

在这些变量中，以下关系保持不变： 

0 <= mark <= position <= limit <=capacity

* capacity

作为一个内存块，Buffer有一个固定的大小值，也叫“capacity”（容量）。只能往里写capacity个byte、long，char等类型。一旦Buffer满了，需要将其清空（通过读数据或者清除数据）才能继续写数据往里写数据

* position

当写数据到Buffer中时，position表示当前的位置。初始的position值为0。当一个byte、long等数据写到Buffer后，position会向前移动到下一个可插入数据的Buffer单元。position最大可为capacity – 1  

当读取数据时，也是从某个特定位置读。当将Buffer从写模式切换到读模式，position会被重置为0。当从Buffer的position处读取数据时，position向前移动到下一个可读的位置

* limit

在写模式下，Buffer的limit表示最多能往Buffer里写多少数据。写模式下，limit等于Buffer的capacity  

当切换Buffer到读模式时，limit表示最多能读到多少数据。因此，当切换Buffer到读模式时，limit会被设置成写模式下的position值。换句话说，能读到之前写入的所有数据（limit被设置成已写数据的数量，这个值在写模式下就是position）

* mark

mark变量的值"记录"了一个将来可返回的位置，reset()方法则将position的值还原成上次调用mark()方法后的position值(除非这样做会违背上述的不变关系)

* flip()

flip方法将Buffer从写模式切换到读模式。调用flip()方法会将position设回0，并将limit设置成之前position的值

* clear()或compact()


一旦读完了所有的数据，就需要清空缓冲区，让它可以再次被写入。有两种方式能清空缓冲区：调用clear()或compact()方法。clear()方法会清空整个缓冲区，虽然名字是clear()，但它实际上不会改变缓冲区中的数据，而只是简单地重置了缓冲区的主要索引值。compact()方法只会清除已经读过的数据。任何未读的数据都被移到缓冲区的起始处，新写入的数据将放到缓冲区未读数据的后面

如果调用的是clear()方法，position将被设回0，limit被设置成capacity的值。换句话说，Buffer被清空了。Buffer中的数据并未清除，只是这些标记告诉我们可以从哪里开始往Buffer里写数据

compact()方法将所有未读的数据拷贝到Buffer起始处。然后将position设到最后一个未读元素正后面。limit属性依然像clear()方法一样，设置成capacity。现在Buffer准备好写数据了，但是不会覆盖未读的数据

* rewind()

Buffer.rewind()将position设回0，所以你可以重读Buffer中的所有数据。limit保持不变，仍然表示能从Buffer中读取多少个元素（byte、char等）

* mark()与reset()

通过调用Buffer.mark()方法，可以标记Buffer中的一个特定position。之后可以通过调用Buffer.reset()方法恢复到这个position

* equals()

可以使用equals()比较两个Buffer

equals()方法当满足下列条件时，表示两个Buffer相等：

1.有相同的元素类型（byte、char、int等）

2.Buffer中剩余元素的个数相等

3.Buffer中所有剩余的元素等都相同

* hasRemaining()&remaining()

position和limit之间的距离指示了可读取/存入的字节数，Java中提供以上两个方法来计算这个距离。当缓冲区至少还有一个元素时，hasRemaining()方法返回true，remaining()方法返回剩余元素的个数



#### Channel

基本上，所有的IO在NIO中都从一个Channel开始。Channel有点像流

JAVA NIO中的一些主要Channel的实现：

* FileChannel：从文件中读写数据
* DatagramChannel：能通过UDP读写网络中的数据
* SocketChannel：能通过TCP读写网络中的数据
* ServerSocketChannel：可以监听新进来的TCP连接，对每一个新进来的连接都会创建一个SocketChannel

这些通道涵盖了UDP和TCP网络IO，以及文件IO

Java NIO的通道类似流，但又有些不同：

* 既可以从通道中读取数据，又可以写数据到通道。但流的读写通常是单向的。
* 通道可以异步地读写。
* 通道中的数据总是要先读到一个Buffer，或者总是要从一个Buffer中写入

[FileChannel使用](http://ifeve.com/file-channel/)

[SocketChannel使用](http://ifeve.com/socket-channel/)

[ServerSocketChannel使用](http://ifeve.com/server-socket-channel/)

[DatagramChannel使用](http://ifeve.com/datagram-channel/)

#### Scatter/Gather

scatter/gather用于描述从Channel中读取或者写入到Channel的操作

分散（scatter）从Channel中读取是指在读操作时将读取的数据写入多个buffer中。因此，Channel将从Channel中读取的数据“分散（scatter）”到多个Buffer中

聚集（gather）写入Channel是指在写操作时将多个buffer的数据写入同一个Channel，因此，Channel 将多个Buffer中的数据“聚集（gather）”后发送到Channel

scatter/gather经常用于需要将传输的数据分开处理的场合，例如传输一个由消息头和消息体组成的消息，可以将消息体和消息头分散到不同的buffer中，这样可以方便的处理消息头和消息体

##### Scattering Reads

Scattering Reads是指数据从一个channel读取到多个buffer中

```
ByteBuffer header = ByteBuffer.allocate(128);
ByteBuffer body   = ByteBuffer.allocate(1024);

ByteBuffer[] bufferArray = { header, body };

channel.read(bufferArray);
```

**read()方法按照buffer在数组中的顺序将从channel中读取的数据写入到buffer，当一个buffer被写满后，channel紧接着向另一个buffer中写。Scattering Reads在移动下一个buffer前，必须填满当前的buffer，这也意味着它不适用于动态消息(即消息大小不固定)**

##### Gathering Writes

Gathering Writes是指数据从多个buffer写入到同一个channel

```
ByteBuffer header = ByteBuffer.allocate(128);
ByteBuffer body   = ByteBuffer.allocate(1024);
 
//write data into buffers
 
ByteBuffer[] bufferArray = { header, body };
 
channel.write(bufferArray);
```

**write()方法会按照buffer在数组中的顺序，将数据写入到channel，注意只有position和limit之间的数据才会被写入。因此，如果一个buffer的容量为128byte，但是仅仅包含58byte的数据，那么这58byte的数据将被写入到channel中。因此与Scattering Reads相反，Gathering Writes能较好的处理动态消息**

#### Channel间数据传输

Java NIO中，如果两个通道中有一个是FileChannel，那可以直接将数据从一个channel传输到另外一个channel

##### transferFrom()

FileChannel的transferFrom()方法可以将数据从源通道传输到FileChannel中

```
RandomAccessFile fromFile = new RandomAccessFile("fromFile.txt", "rw");
FileChannel      fromChannel = fromFile.getChannel();

RandomAccessFile toFile = new RandomAccessFile("toFile.txt", "rw");
FileChannel      toChannel = toFile.getChannel();

long position = 0;
long count = fromChannel.size();

toChannel.transferFrom(position, count, fromChannel);
```

此外要注意，在SoketChannel的实现中，SocketChannel只会传输此刻准备好的数据（可能不足count字节）。因此，SocketChannel可能不会将请求的所有数据(count个字节)全部传输到FileChannel中

##### transferTo()

transferTo()方法将数据从FileChannel传输到其他的channel中

```
RandomAccessFile fromFile = new RandomAccessFile("fromFile.txt", "rw");
FileChannel      fromChannel = fromFile.getChannel();

RandomAccessFile toFile = new RandomAccessFile("toFile.txt", "rw");
FileChannel      toChannel = toFile.getChannel();

long position = 0;
long count = fromChannel.size();

fromChannel.transferTo(position, count, toChannel);
```

#### Selector

Selector（选择器）是Java NIO中能够检测一到多个NIO通道，并能够知晓通道是否为诸如读写事件做好准备的组件

Selector允许单线程处理多个Channel。如果打开了多个通道，但每个通道的流量都很低，使用Selector就会很方便  

要使用Selector，得向Selector注册Channel，然后调用它的select()方法。这个方法会一直阻塞到某个注册的通道有事件就绪。一旦这个方法返回，线程就可以处理这些事件

```
//创建
Selector selector = Selector.open();
```

```
//注册
channel.configureBlocking(false);
SelectionKey key = channel.register(selector,Selectionkey.OP_READ);
```

**与Selector一起使用时，Channel必须处于非阻塞模式下。这意味着不能将FileChannel与Selector一起使用，因为FileChannel不能切换到非阻塞模式。而套接字通道都可以**

register()方法的第二个参数。这是一个“interest集合”，意思是在通过Selector监听Channel时对什么事件感兴趣。可以监听四种不同类型的事件：

* Connect
* Accept
* Read
* Write

这四种事件用SelectionKey的四个常量来表示：

* SelectionKey.OP_CONNECT
* SelectionKey.OP_ACCEPT
* SelectionKey.OP_READ
* SelectionKey.OP_WRITE

如果你对不止一种事件感兴趣，那么可以用“位或”操作符将常量连接起来：

```
int interestSet = SelectionKey.OP_READ | SelectionKey.OP_WRITE;
```

##### SelectionKey

Selector与Channel之间的关联由一个SelectionKey实例表示，一个信道可以注册多个Selector实例，因此可以有多个关联的SelectionKey实例

SelectionKey维护了一个信道上感兴趣的操作类型信息，并将这些信息存放在一个int型的位图(bitmap)中，该int型数据的每一位都有相应的含义

每个选择器都有一组与之关联的信道，选择器对这些信道上"感兴趣的"I/O操作进行监听

SelectionKey类中的常量定义了信道上可能感兴趣的操作类型，每个这种常量都是只有一位设置为1的位掩码(bitmask)

* OP_ACCEPT
* OP_CONNECT
* OP_READ
* OP_WRITE

通过对OP_ACCEPT，OP_CONNECT，OP_READ以及OP_WRITE中适当的常量进行按位OR，可以构造一个位向量来指定一组操作

interest集合是你所选择的感兴趣的事件集合。可以通过SelectionKey读写interest集合：

```
int interestSet = selectionKey.interestOps();

boolean isInterestedInAccept  = (interestSet & SelectionKey.OP_ACCEPT) == SelectionKey.OP_ACCEPT；
boolean isInterestedInConnect = interestSet & SelectionKey.OP_CONNECT;
boolean isInterestedInRead    = interestSet & SelectionKey.OP_READ;
boolean isInterestedInWrite   = interestSet & SelectionKey.OP_WRITE;
```

用“位与”操作interest集合和给定的SelectionKey常量，可以确定某个确定的事件是否在interest集合中

所选键集指示了哪些信道当前可以进行I/O操作。对于选中的每个信道，需要知道它们各自准备好的特定I/O操作。除了兴趣操作集外，每个键还维护了一个即将进行的I/O操作集，称为就绪操作集(ready set)

ready集合是通道已经准备就绪的操作的集合。在一次选择(Selection)之后，你会首先访问这个ready set

```
int readySet = selectionKey.readyOps();
```

对于给定的键，可以使用readyOps()方法或其他指示方法来确定兴趣集中的哪些I/O操作可以执行。readyOps()方法以位图的形式返回所有准备就绪的操作集。其他方法用于分别检查各种操作是否可用

```
(key.readyOps() & SelectionKey.OP_READ) != 0
```

或

```
selectionKey.isAcceptable();
selectionKey.isConnectable();
selectionKey.isReadable();
selectionKey.isWritable();
```

从SelectionKey访问Channel和Selector

```
Channel  channel  = selectionKey.channel();
Selector selector = selectionKey.selector();
```

可以将一个对象或者更多信息附着到SelectionKey上，这样就能方便的识别某个给定的通道

```
selectionKey.attach(theObject);
Object attachedObj = selectionKey.attachment();
```

还可以在用register()方法向Selector注册Channel的时候附加对象

```
SelectionKey key = channel.register(selector, SelectionKey.OP_READ, theObject)
```

##### 通过Selector选择通道

一旦向Selector注册了一或多个通道，就可以调用几个重载的select()方法。这些方法返回所感兴趣的事件已经准备就绪的那些通道

```
int select()
int select(long timeout)
int selectNow()
```

select()阻塞到至少有一个通道在你注册的事件上就绪了

select(long timeout)和select()一样，除了最长会阻塞timeout毫秒(参数)

selectNow()不会阻塞，不管什么通道就绪都立刻返回

select()方法返回的int值表示有多少通道已经就绪

一旦调用了select()方法，并且返回值表明有一个或更多个通道就绪了，然后可以通过调用selector的selectedKeys()方法，访问“已选择键集（selected key set）”中的就绪通道

```
Set selectedKeys = selector.selectedKeys();
```

当向Selector注册Channel时，Channel.register()方法会返回一个SelectionKey对象。这个对象代表了注册到该Selector的通道。可以通过SelectionKey的selectedKeySet()方法访问这些对象

可以遍历这个已选择的键集合来访问就绪的通道

```
Set selectedKeys = selector.selectedKeys();
Iterator keyIterator = selectedKeys.iterator();
while(keyIterator.hasNext()) {
    SelectionKey key = keyIterator.next();
    if(key.isAcceptable()) {
        // a connection was accepted by a ServerSocketChannel.
    } else if (key.isConnectable()) {
        // a connection was established with a remote server.
    } else if (key.isReadable()) {
        // a channel is ready for reading
    } else if (key.isWritable()) {
        // a channel is ready for writing
    }
    keyIterator.remove();
}
```


**注意每次迭代末尾的keyIterator.remove()调用。selectedKeys()方法返回的键集是可修改的，实际上在两次调用select()方法之间，都必须"手工"将其清空。换句话说，select方法只会在已有的所选键集上添加键，它们不会创建新的键集。Selector不会自己从已选择键集中移除SelectionKey实例。必须在处理完通道时自己移除。下次该通道变成就绪时，Selector会再次将其放入已选择键集中**

##### 信道附件

当一个信道准备好进行I/O操作时，通常还需要额外的信息来处理请求，SelectionKey通过使用附件使保存每个信道的状态变得容易。每个键可以有一个附件，数据类型只能是Obect类。附件可以在信道第一次调用register()方法时与之关联，或者后来再使用attach()方法直接添加到键上。通过SelectionKey的attachment()方法可以访问键的附件

```
Object attach(object ob)

Object attachment()
```

##### wakeUp()&close()

某个线程调用select()方法后阻塞了，即使没有通道已经就绪，也有办法让其从select()方法返回。只要让其它线程在第一个线程调用select()方法的那个对象上调用Selector.wakeup()方法即可。阻塞在select()方法上的线程会立马返回。如果有其它线程调用了wakeup()方法，但当前没有线程阻塞在select()方法上，下个调用select()方法的线程会立即“醒来（wake up）”

用完Selector后调用其close()方法会关闭该Selector，且使注册到该Selector上的所有SelectionKey实例无效。通道本身并不会关闭

#### Pipe

Java NIO管道是2个线程之间的单向数据连接。Pipe有一个source通道和一个sink通道。数据会被写到sink通道，从source通道读取

```
//创建管道
Pipe pipe = Pipe.open();
```

```
//向管道写数据，需要访问sink通道
Pipe.SinkChannel sinkChannel = pipe.sink();

String newData = "New String to write to file..." + System.currentTimeMillis();
ByteBuffer buf = ByteBuffer.allocate(48);
buf.clear();
buf.put(newData.getBytes());
 
buf.flip();
 
while(buf.hasRemaining()) {
    sinkChannel.write(buf);
}
```

```
//从读取管道的数据，需要访问source通道
Pipe.SourceChannel sourceChannel = pipe.source();

ByteBuffer buf = ByteBuffer.allocate(48);
 
int bytesRead = sourceChannel.read(buf);
```

#### [path](http://tutorials.jenkov.com/java-nio/path.html)

Java NIO中的路径

#### [Files](http://tutorials.jenkov.com/java-nio/files.html)

Java NIO中的文件

#### [AsynchronousFileChannel](http://tutorials.jenkov.com/java-nio/asynchronousfilechannel.html)

异步FileChannel

#### [MappedByteBuffer](https://blog.csdn.net/qq_41969879/article/details/81629469)

##### 后援数组

实际上，wrap()方法只是简单地创建了一个具有指向被包装数组的引用的缓冲区，该数组称为后援数组。对后援数组中的数据做的任何修改都将改变缓冲区中的数据，反之亦然

#####直接缓冲区(Linux内存映射实现)

通常，底层平台(操作系统)不能使用buffer进行I/O操作。操作系统必须使用自己的缓冲区来进行I/O，并将结果复制到buffer中。这些复制过程可能非常耗费系统资源，尤其是在有很多读写需求的时候。Java 的NIO提供了一种直接缓冲区(direct buffers)来解决这个问题。使用直接缓冲区，Java将从平台能够直接进行I/O操作的存储空间中为缓冲区分配后援存储空间，从而省略了数据的复制过程。这种低层的、本地的I/O通常在字节层进行操作，因此只能为ByteBuffer进行直接缓冲区分配，这就是MappedByteBuffer

```
ByteBuffer byteBufDirect = ByteBuffer.allocateDirect(BUFFERSIZE);
```

直接字节缓冲区还可以通过FileChannel的map()方法将文件区域直接映射到内存中来创建。该方法返回MappedByteBuffer 

DirectByteBuffer是MappedByteBuffer的一个子类，其实现了对内存的直接操作，MappedByteBuffer的get方法最终通过DirectByteBuffer.get()方法实现的

通过调用isDirect()方法可以查看一个缓冲区是否是直接缓冲区。由于直接缓冲区没有后援数组，在它上面调用array()或arrayOffset()方法都将抛出UnsupportedOperationException异常。在考虑是否使用直接缓冲区时需要牢记几点。首先，要知道调用allocateDirect()方法并不能保证能成功分配直接缓冲区：有的平台或JVM可能不支持这个操作，因此在尝试分配直接缓冲区后必须调用isDirect(方法进行检查。其次，要知道分配和销毁直接缓冲区通常比分配和销毁非直接缓冲区要消耗更多的系统资源，因为直接缓冲区的后援存储空间通常存在与JVM之外，对它的管理需要与操作系统进行交互。所以，只有当需要在很多I/O操作上长时间使用时，才分配直接缓冲区。实际上，在相对于非直接缓冲区能明显提高系统性能时，使用直接缓冲区是个不错的主意

#### Buffer透视

NIO提供了多种方法来创建一个与给定缓冲区共享内容的新缓冲区。基本上，这种新缓冲区有自己独立的状态变量(position, limit, capacity和mark)，但与原始缓冲区共享了同一个后援存储空间。任何对新缓冲区内容的修改都将反映到原始缓冲区上。可以将新缓冲区看作是从另一个角度对同一数据的透视，相关方法有duplicate()，slice()等

https://blog.csdn.net/qq_38386085/article/details/81501410
https://www.cnblogs.com/pony1223/p/8179804.html
https://www.jianshu.com/p/f90866dcbffc

https://ifeve.com/java-nio-all/