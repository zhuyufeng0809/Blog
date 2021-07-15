### 安装

```shell
curl https://mirror.bit.edu.cn/apache/kafka/2.7.0/kafka_2.12-2.7.0.tgz

tar -zxvf kafka_2.12-2.7.0.tgz -C /opt/

mv /opt/kafka_2.12-2.7.0 /opt/kafka

echo 'export PATH=$PATH:/opt/kafka/bin' >> /etc/profile
echo 'export PATH=$PATH:/opt/zookeeper/bin' >> /etc/profile
source /etc/profile

修改server.properties
去掉注释listeners=PLAINTEXT://:9092
去掉注释，替换IP：advertised.listeners=PLAINTEXT://host:9092

zookeeper-server-start.sh -daemon /opt/kafka/config/zookeeper.properties
kafka-server-start.sh -daemon /opt/kafka/config/server.properties

kafka-topics.sh --create --zookeeper localhost:2181 --topic partitionTest --partitions 4 --replication-factor 1

kafka-topics.sh --describe --zookeeper localhost:2181 --topic test

kafka-console-producer.sh --broker-list localhost:9092 --topic partitionTest 
Hello, Kafka 
This is my first Kafka message.

kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic partitionTest --from-beginning
```

### 消息系统

Messaging system，又称消息引擎、消息队列、消息中间件等，是用于在不同应用间传输消息的系统，这里的消息可以是任何形式的数据，比如电子邮件、传真、即时消息，甚至是其他服务等

设计一个消息引擎系统时需要考虑的两个重要因素：

* 消息设计：消息通常都采用结构化的方式进行设计，Kafka的消息是用二进制方式来保存的，但依然是结构化的消息
* 传输协议设计：消息传输协议指定了消息在不同系统之间传输的方式，Kafka自己设计了一套二进制的消息传输协议

#### 消息系统模型

最常见的两种消息引擎范型是消息队列模型和发布／订阅模型

消息队列(message queue)模型是基于队列提供消息传输服务的，多用于进程间通信(inter-process communication,IPC)以及线程间通信。该模型定义了消息队列（queue）、发送者（sender）和接收者(receiver)，提供了一种点对点（point-to-point，p2p）的消息传递方式，即发送者发送每条消息到队列的指定位置，接收者从指定位置获取消息。一旦消息被消费（consumed），就会从队列中移除该消息。每条消息由一个发送者生产出来，且只被一个消费者（consumer）处理，发送者和消费者之间是一对一的关系

而另一种模型就是发布/订阅模型(publish/subscribe,或简称为pub/sub)，与前一种模型不同，它有主题(topic)的概念:一个topic可以理解为逻辑语义相近的消息的容器。这种模型也定义了类似于生产者/消费者这样的角色，即发布者(publisher)和订阅者(subscriber)。发布者将消息生产出来发送到指定的topic中，所有订阅了该topic的订阅者都可以接收到该topic下的所有消息。通常具有相同订阅topic 的所有订阅者将接收到同样的消息

##### Java消息服务

Java消息服务，即Java Message Service (简称JMS)。严格来说，它只是一套API规范，提供了很多接口用于实现分布式系统间的消息传递。JMS同时支持上面两种消息引擎模型。实际上，当前很多主流的消息引擎系统都完全支持JMS规范，比如ActiveMQ、RabbitMQ、IBM WebSphere MQ和Kafka等。当然Kafka并没有完全遵照JMS规范，它另辟蹊径，探索出了一条独有的道路

### kafka简介

#### 概要设计

Kafka的设计初衷就是为了**解决互联网公司超大量级数据的实时传输**。为了实现这个目标，Kafka在设计之初就需要考虑以下4个方面的问题

##### 吞吐量／延时

对于任何一个消息引擎而言，吞吐量(throughput)都是至关重要的性能指标。通常来说，吞吐量是某种处理能力的最大值。而对于Kafka而言，它的吞吐量就是每秒能够处理的消息数或者每秒能够处理的字节数。消息引擎系统还有一个名为延时的性能指标。它衡量的是一段时间间隔，可能是发出某个操作与接收到操作响应(response)之间的时间，或者是在系统中导致某些物理变更的起始时刻与变更正式生效时刻之间的间隔。对于Kafka而言，延时可以表示客户端发起请求与服务器处理请求并发送响应给客户端之间的这一段时间。在实际使用场景中，这两个指标通常是对矛盾体，即调优其中一个指标通常会使另一个
指标变差。当然它们之间的关系也不是等比例地此消彼长的关系

Kafka的写入操作是很快的，这主要得益于它对磁盘的使用方法的不同。虽然Kafka会持久化所有数据到磁盘，但本质上每次写入操作其实都只是把数据写入到操作系统的页缓存(page cache)中，然后由操作系统自行决定什么时候把页缓存中的数据写回磁盘上。这样的设计有3个主要优势

* 操作系统页缓存是在内存中分配的，所以消息写入的速度非常快
* Kafka不必直接与底层的文件系统打交道。所有烦琐的I/O操作都交由操作系统来处理
* Kafka写入操作采用追加写入(append)的方式，避免了磁盘随机写操作

特别留意第3点。对于普通的物理磁盘(非固态硬盘)而言，总是认为磁盘的读/写操作是很慢的。事实上普通磁盘随机读/写的吞吐量的确是很慢的，但是磁盘的顺序读/写操作其实是非常快的，它的速度甚至可以匹敌内存的随机IO速度

鉴于这一事实，Kafka在设计时采用了追加写入消息的方式，即只能在日志文件末尾追加写入新的消息，且不允许修改已写入的消息，因此它属于典型的磁盘顺序访问型操作，所以Kafka消息发送的吞吐量是很高的。在实际使用过程中可以很轻松地做到每秒写入几万甚至几十万条消息

之前提到了Kafka是把消息写入操作系统的页缓存中的。那么同样地，Kafka在读取消息时会首先尝试从os的页缓存中读取，如果命中便把消息经页缓存直接发送到网络的Socket上。这个过程就是利用Linux 平台的sendfile系统调用做到的，而这种技术就是大名鼎鼎的零拷贝(Zero Copy)技术

传统的Linux操作系统中的IO接口是依托于数据拷贝来实现的，在零拷贝技术出现之前，一个IO操作会将同一份数据进行多次拷贝，数据传输过程中还涉及内核态与用户态的上下文切换，CPU的开销非常大，因此极大地限制了OS高效进行数据传输的能力。拷贝技术很好地改善了这个问题:首先在内核驱动程序处理I/O数据的时候，它不再需要进行上下文的切换，节省了内核缓冲区与用户态应用程序缓冲区之间的数据拷贝，同时它利用直接存储器访问技术(Direct Memory Access, DMA)执行I/O操作，因此也避免了OS内核缓冲区之间的数据拷贝，故而得名零拷贝

Linux提供的sendfile系统调用实现了这种零拷贝技术，而Kafka的消息消费机制使用的就是sendfile，严格来说是通过Java的FileChannel.transferTo方法实现的。除了零拷贝技术，Kafka由于大量使用页缓存，故读取消息时大部分消息很有可能依然保存在页缓存中，因此可以直接命中缓存，不用“穿透”到底层的物理磁盘上获取消息，从而极大地提升了消息读取的吞吐量。事实上，如果我们监控一个经过良好调优的Kafka生产集群便可以发现，即使是那些有负载的Kafka服务器，其磁盘的读操作也很少，这是因为大部分的消息读取操作会直接命中页缓存

总结一下，Kafka 就是依靠下列4点达到了高吞吐量、低延时的设计目标的

* 大量使用操作系统页缓存，内存操作速度快 且命中率高
* Kafka不直接参与物理I/O操作，而是交由最擅长此事的操作系统来完成
* 采用追加写入方式，摒弃了缓慢的磁盘随机读/写操作
* 使用以sendfile为代表的零拷贝技术加强网络间的数据传输效率

##### 消息持久化

Kafka是要持久化消息的，而且要把消息持久化到磁盘上。这样做的好处如下

* 解耦消息发送与消息消费:本质上来说，Kafka最核心的功能就是提供了生产者消费者模式的完整解决方案。通过将消息持久化使得生产者方不再需要直接和消费者方耦合，它只是简单地把消息生产出来并交由Kafka服务器保存即可，因此提升了整体的吞吐量
* 实现灵活的消息处理:很多Kafka的下游子系统(接收Kafka消息的系统)都有这样的需求，对于已经处理过的消息可能在未来的某个时间点重新处理一次，即所谓的消息重演(message replay)。消息持久化便可以很方便地实现这样的需求

Kafka实现持久化的设计也有新颖之处。普通的系统在实现持久化时可能会先尽量使用内存，当内存资源耗尽时，再一次性地把数据“刷盘”;而Kafka则反其道而行之，所有数据都会立即被写入文件系统的持久化日志中，之后Kafka服务器才会返回结果给客户端通知它们消息已被成功写入。这样做既实时保存了数据，又减少了Kafka程序对于内存的消耗，从而将节省出的内存留给页缓存使用，更进一步地提升了整体性能

##### 负载均衡和故障转移

一套完整的消息引擎解决方案中必然要提供负载均衡(load balancing)和故障转移(fail-over)功能

负载均衡顾名思义就是让系统的负载根据一定的规则均衡地分配在所有参与工作的服务器上，从而最大限度地提升系统整体的运行效率。具体到Kafka来说，默认情况下Kafka的每台服务器都有均等的机会为Kafka的客户提供服务，可以把负载分散到所有集群中的机器上，避免出现"耗尽某台服务器”的情况发生。Kafka实现负载均衡实际上是通过智能化的分区领导者选举(partition leader election)来实现的。Kafka默认提供了很智能的leader选举算法，可以在集群的所有机器上以均等机会分散各个partition的leader，从而整体上实现了负载均衡

所谓故障转移，是指当服务器意外中止时，整个集群可以快速地检测到该失效(failure)，并立即将该服务器上的应用或服务自动转移到其他服务器上。故障转移通常是以“心跳”或“会话”的机制来实现的，即只要主服务器与备份服务器之间的心跳无法维持或主服务器注册到服务中心的会话超时过期了，那么就认为主服务器已无法正常运行，集群会自动启动某个备份服务器来替代主服务器的工作。Kafka服务器支持故障转移的方式就是使用会话机制。每台Kafka服务器启动后会以会话的形式把自己注册到ZooKeeper服务器上。一旦该服务器运转出现问题，与ZooKeeper的会话便不能维持从而超时失效，此时Kafka集群会选举出另一台服务器来完全代替这台服务器继续提供服务

##### 伸缩性

有了消息的持久化，Kafka实现了高可靠性;有了负载均衡和使用文件系统的独特设计，Kafka实现了高吞吐量;有了故障转移，Kafka实现了高可用性。那么作为分布式系统中的高伸缩性，Kafka 又是如何做到的呢?所谓伸缩性，英文名是scalability。伸缩性表示向分布式系统中增加额外的计算资源(比如CPU、内存、存储或带宽)时吞吐量提升的能力。如果一个CPU的运算能力是U,我们自然希望两个CPU的运算能力是2U，即可以线性地扩容计算能力，这种线性伸缩性是最理想的状态，但在实际中几乎不可能达到，毕竞分布式系统中有很多隐藏的“单点”瓶颈制约了这种线性的计算能力扩容。阻碍线性扩容的一个很常见的因素就是状态的保存。不论是哪类分布式系统，集群中的每台服务器一定会维护很多内部状态。如果由服务器自己来保存这些状态信息，则必须要处理一致性的问题。相反，如果服务器是无状态的，状态的保存和管理交于专门的协调服务来做(比如ZooKeeper)，那么整个集群的服务器之间就无须繁重的状态共享，这极大地降低了维护复杂度。倘若要扩容集群节点，只需简单地启动新的节点机器进行自动负载均衡就可
以了

Kafka正是采用了这样的思想，每台Kafka服务器上的状态统一交由ZooKeeper保管。扩展Kafka集群也只需要一步:启动新的Kafka服务器即可。当然这里需要言明的是，在Kafka服务器上并不是所有状态都不保存，它只保存了很轻量级的内部状态，因此在整个集群间维护状态一致性的代价是很低的

#### 基本概念与术语

目前Kafka的标准定位是**分布式流式处理平台**。Kafka自推出伊始是以消息引擎的身份出现的，其强大的消息传输效率和完备的分布式解决方案，使它很快成为业界翘楚。随着Kafka的不断演进，Kafka开发团队日益发现经Kafka交由下游数据处理平台做的事情Kafka自己也可以做，因此在Kafka 0.10.0.0 版本正式推出了Kafka Streams,即流式处理组件。自此Kafka正式成为了一个流式处理框架，而不仅仅是消息引擎了

不论Kafka如何变迁，其核心架构总是类似的，无非是生产一些消息然后再消费一些消息。如果总结起来那就是三句话

* 生产者发送消息给Kafka服务器
* 消费者从Kafka服务器读取消息
* Kafka服务器依托ZooKeeper集群进行服务的协调管理

事实上，Kafka服务器有一个官方名字: broker

Kafka服务端由多个broker实例组成

##### 消息

Kafka中的消息格式由很多字段组成，其中的很多字段都是用于管理消息的元数据字段，对用户来说是完全透明的。Kafka消息格式共经历过3次变迁，它们被分别称为V0、V1和V2版本。目前大部分用户使用的应该还是VI版本的消息格式。V1版本消息的完整格式由消息头部、key和value组成。消息头部包括消息的CRC码、消息版本号、属性、时间戳、键长度和消息体长度等信息。其实，对于普通用户来说，掌握以下3
个字段的含义就足够般的使用了

* Key:消息键，对消息做partition时使用，即决定消息被保存在某topic下的哪个partition
* Value:消息体，保存实际的消息数据
* Timestamp: 消息发送时间戳，用于流式处理及其他依赖时间的处理语义。如果不指定则取当前时间

Kafka为消息的属性字段分配了1字节。目前只使用了最低的3位用于保存消息的压缩类型，其余5位尚未使用。当前只支持4种压缩类型:0(无压缩)、1(GZIP)、2(Snappy)和3(LZ4)，其次，Kafka 使用紧凑的二进制字节数组来保存上面这些字段，也就是说没有任何多余的比特位浪费

在Java内存模型(Java memory model, JMM)中，对象保存的开销其实相当大，对于小对象而言，通常要花费2倍的空间来保存数据(甚至更糟)。另外，随着堆上数据量越来越大，GC的性能会下降很多，从而整体上拖慢了系统的吞吐量

因此Kafka在消息设计时特意避开了繁重的Java堆上内存分配，直接使用紧凑二进制字节数组ByteBuffer而不是独立的对象，因此我们至少能够访问多一倍的可用内存。如果使用ByteBuffer来保存同样的消息，只需要24字节，比起纯Java堆的实现减少了40%的空间占用，好处不言而喻。这种设计的好处还包括加入了扩展的可能性。同时，大量使用页缓存而非堆内存还有一个好处，当出现Kafka broker进程崩溃时，堆内存上的数据也一并消失，但页缓存的数据依然存在。下次Kafka broker重启后可以继续提供服务，不需要再单独“热”缓存了

##### topic和partition

从概念上来说，topic只是一个逻辑概念，代表了一类消息，也可以认为是消息被发送到的地方。Kafka中的topic通常都会被多个消费者订阅，因此出于性能的考量，Kafka并不是topic-message的两级结构，而是采用了topic-partition-message的三级结构来分散负载。从本质上说，每个Kafka topic都由若干个partition组成

topic是由多个partition组成的，而Kafka的partition是不可修改的有序消息序列，也可以说是有序的消息日志。每个partition有自己专属的partition号，通常是从0开始的。用户对partition唯一能 做的操作就是在消息序列的尾部追加写入消息。partition上的每条消息都会被分配一个唯的序列号，按照Kafka的术语来讲，该序列号被称为位移(ofset)。该位移值是从0开始顺序递增的整数。位移信息可以唯定位到某partition下的一条消息

Kafa的partition实际上并没有太多的业务含义，它的引入就是单纯地为了提升系统的吞吐量

##### offset

topic partition下的每条消息都被分配一个位移值。实际上，Kafka消费者端也有位移(ofiset)的概念，但一定要注意这两个offset属于不同的概念，每条消息在某个partition位移是固定的，但消费该 partition 的消费者的位移会随着消费进度不断前移，但终究不可能超过该分区最新一条消息的位移

综合之前说的topic、partition和offset，可以断言Kafka中的一条消息其实就是一个<topic,partition,offset>三元组(tuple)，通过该元组值我们可以在Kafka集群中找到唯一对应的那条消息

##### replica

分布式系统必然要实现高可靠性，而目前实现的主要途径还是依靠冗余机制，简单地说，就是备份多份日志。这些备份日志在Kafka中被称为副本(replica)，它们存在的唯一目的就是防止数据丢失

副本分为两类:领导者副本(leader replica)和追随者副本(follower replica)。follower replica是不能提供服务给客户端的，也就是说不负责响应客户端发来的消息写入和消息消费请求。它只是被动地向领导者副本(leader replica)获取数据，而一旦leader replica所在的broker宕机，Kafka会从剩余的replica中选举出新的leader继续提供服务

##### leader和follower

Kafka的replica分为两个角色:领导者(leader)和追随者(follower)。如今这种角色设定几乎完全取代了过去的主备的提法(Master-Slave)。和传统主备系统不同的是，在这类leader-follower系统中通常只有leader对外提供服务，follower只是被动地追随leader的状态，保持与leader的同步。follower存在的唯一价值就是充当leader的候补，一旦leader挂掉立即就会有一个追随者被选举成为新的leader接替它的工作

Kafka保证同一个partition的多个replica一定不会分配在同一台broker上。毕竟如果同一个broker上有同一个partition的多个replica,那么将无法实现备份冗余的效果

##### ISR

ISR的全称是in-sync replica，翻译过来就是与leader replica保持同步的replica集合

Kafka为partition**动态**维护一个replica集合。该集合中的所有replica保存的消息日志都与leader replica保持同步状态。只有这个集合中的replica才能被选举为leader，也只有该集合中所有replica都接收到了同一条消息，Kafka才会将该消息置于“已提交”状态，即认为这条消息发送成功。回到刚才的问题，Kafka承诺只要这个集合中至少存在一个replica，那些“已提交”状态的消息就不会丢失，这句话的两个关键点:①ISR中至少存在一个“活着的”replica;②“已提交”消息。有些Kafka用户经常抱怨:我向Kafka发送消息失败，然后造成数据丢失。其实这是混淆了Kafka的消息交付承诺(message delivery semantic):Kafka对于没有提交成功的消息不做任何交付保证，它只保证在ISR存活的情况下“已提交”的消息不会丢失

正常情况下，partition的所有replica(含leader replica)都应该与leader replica保持同步，即所有replica都在ISR中。因为各种各样的原因，一小部分replica开始落后于leader replica的进度。当滞后到一定程度时，Kafka会将这些replica“踢”出ISR。相反地，当这些replica重新“追上”了leader的进度时，那么Kafka会将它们加回到ISR中。这一切都是自动维护的，不需要用户进行人工干预，因而在保证了消息交付语义的同时还简化了用户的操作成本

### Producer开发

简单来说，Kafka producer就是负责向Kafka写入数据的应用程序。自0.9.0.0 版本起， Apache Kafka 发布了 Java 版本的 producer 供用户使用，但作为一个比较完善的生态系统，Kafka 必然要支持多种语言的 producer，这些第三方库基本上都是由非 Apache Kafka 社区的人维护的，如果用户下载的是 Apache Kafka，默认是不包含这些库的，需要额外单独下载对应的库

Apache Kafka封装了一套二进制通信协议，用于对外提供各种各样的服务 对于producer，用户几乎可以直接使用任意编程语言按照该协议的格式进行编程，从而实现向Kafka发送消息。实际上内置Java 版本producer和所有第三方库在底层都是相同的实现原理，只是在易用性和性能方面有所差别而已，这组协议本质上为不同的协议类型分别定义了专属的紧凑二进制宇节数组格式，然后通过Socket发送给合适的broker ，之后等待broker处理完成后返还响应（ response ）给 producer。这样设计的好处在于具有良好的统一性，即所有的协议类型都是统一格式的，并且由于是自定义的进制格式，这套协议并不依赖任何外部序列化框架，从而显得非常轻量级，而且也有很好的扩展性

Kafka producer在设计上要比consumer简单一些，因为它不涉及复杂的组管理操作，即每个producer都是独立进行工作的，与其他producer实例之间没有关联，因此它受到的牵绊自然也要少得多，实现起来也要简单得多

目前producer的首要功能就是向某个topic的某个分区发送一条消息，所以它首先需要确认到底要向topic的哪个分区写入消息，这就是分区器(partitioner)要做的事情。Kafka producer提供了一个默认的分区器。对于每条待发送的消息而言，如果该消息指定了key，那么该partitioner会根据key的哈希值来选择目标分区;若这条消息没有指定key, 则partitioner使用轮询的方式确认目标分区，那么所有消息会被均匀地发送到所有分区，这样可以最大限度地确保消息在所有分区上的均匀性。当然producer的API赋予了用户自行指定目标分区的权力，即用户可以在消息发送时跳过partitioner直接指定要发送到的分区

另外， producer也允许用户实现自定义的分区策略而非使用默认的partitioner，这样用户可以很灵活地根据自身的业务需求确定不同的分区策略

在确认了目标分区后，producer要做的第二件事情就是要寻找这个分区对应的leader也就是该分区leader副本所在的Kafka broker。每个topic分区都由若干个副本组成，其中的一个副本充当leader 的角色，也只有leader才能够响应clients发送过来的请求，而剩下的副本中有一部分副本会与leader副本保持同步，即所谓的ISR。因此在发送消息时，producer也就有了多种选择来实现消息发送。比如不等待任何副本的响应便返回成功，或者只是等待leader副本响应写入操作之后再返回成功等。不同的选择也有着不同的优缺点

#### Java版本producer的工作原理

**producer首先使用一个线程(用户主线程，也就是用户启动producer的线程，持有producer实例的线程)将待发送的消息封装进一个ProducerRecord类实例，然后将其序列化之后发送给partitioner，再由后者确定了目标分区后一同发送到位于producer程序中的一块内存缓冲区中。而producer的另一个工作线程(I/O发送线程，也称Sender线程)则负责实时地从该缓冲区中提取出准备就绪的消息封装进一个批次(batch)，统一发送给对应的broker**。整个producer的工作流程大概就是这样的

#### 构造producer流程

```
public static void main(String[] args) {
    Properties properties= new Properties();
    properties.put("bootstrap.servers", "47.103.7.129:9092");//必须指定
    properties.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");//必须指定
    properties.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");//必须指定

    Serializer<String> keySerializer = new StringSerializer();
    Serializer<String> valueSerializer = new StringSerializer();
    Producer<String, String> producer= new KafkaProducer<>(properties,keySerializer,valueSerializer);

	producer.send(new ProducerRecord<> ("test", Integer.toString(100), Integer.toString(100)));

    producer.close();
}
```

##### 构造Properties对象

构造一个java.util.Properties对象，然后至少指定bootstrap.servers，key.serializer，value.serializer个属性

```
Properties properties= new Properties();
properties.put("bootstrap.servers", "47.103.7.129:9092");//必须指定
//或者properties.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "47.103.7.129:9092");
properties.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");//必须指定
//或者properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
properties.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");//必须指定
//或者properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
```

##### 构造Kafka Producer对象

KafkaProducer是producer的主入口，所有的功能基本上都是由KafkaProducer来提供的

```
Producer<String, String> producer= new KafkaProducer<>(properties);
```

创建producer时也可以同时指定key和value的序列化类，如果采用这样的方式创建producer，那么就不需要显式地在Properties中指定key和value序列化类

```
Serializer<String> keySerializer =new StringSerializer();
Serializer<String> valueSerializer =new StringSerializer();
Producer<String, String> producer= new KafkaProducer<>(properties,keySerializer,valueSerializer);
```

##### 构造ProducerRecord对象

Java版本producer使用ProducerRecord类来表示每条消息

```
new ProducerRecord<> ("test", Integer.toString(100), Integer.toString(100))
```

ProducerRecord还支持指定更多的构造函数

##### 发送消息

Kafka producer发送消息的主方法是send方法。虽然send方法只有两个简单的方法签名，但其实producer在底层完全地实现了异步化发送，并且通过Java提供的Future同时实现了同步发送和异步发送＋回调（ Callback ）两种发送方式。第三种发送方式：fire and forget，即发送之后便不再理会发送结果 这种方式在实际中是不被推荐使用的，因为对于发送结果producer程序完全不知，所以在真实使用场景中，同步和异步的发送方式还是最常见的两种方式

*异步发送*

实际上所有的写入操作默认都是异步的。Java版本producer的send方法会返回Java Future对象供用户稍后获取发送结果，这就是所谓的回调机制。send方法提供了回调类参数来实现异步发送以及对发送结果的响应

```
producer.send(new ProducerRecord<>("test", Integer.toString(100), Integer.toString(100)),
        new Callback() {
            @Override
            public void onCompletion(RecordMetadata metadata, Exception exception) {
                
            }
        });
```

该方法的两个输入参数metadata和exception不会同时非空，也就是说至少有一个是null。当消息发送成功时，exception为null；反之，若消息发送失败，metadata就是null。因此在开发producer时，最好写if语句进行判断。另外，Callback实际上是一个Java接口，用户可以创建自定义的Callback实现类来处理消息发送后的逻辑，只要该具体类实现org.apache.kafka.clients.producer.Callback 接口即可

*同步发送*

同步发送和异步发送其实就是通过Java Future的使用来区分的，调用Future.get()无限等待结果返回，即实现同步发送的效果

```java
producer.send(record).get();
```

使用Future.get会一直等待下去直至Kafka broker发送结果返回给producer程序。当结果从broker处返回时，get方法要么返回发送结果要么抛出异常交由producer自行处理。如果没有错误，get方法将返回对应的RecordMetadata实例（包含了己发送消息的所有元数据信息），包括消息发送的topic 、分区以及该消息在对应分区的位移信息

*发送结果处理*

不管是同步发送还是异步发送，发送都有可能失败，导致返回异常错误。当前Kafka的错误类型包含了两类：可重试异常和不可重试异常。常见的可重试异常如下

LeaderNotAvailableException：分区的leader副本不可用，这通常出现在leader换届选举期间，因此通常是瞬时的异常，重试之后可以自行恢复  
NotControllerException：controller当前不可用，这通常表明controller在经历新一轮的选举，这也是可以通过重试机制自行恢复的  
NetworkException：网络瞬时故障导致的异常，可重试  

对于这种可重试的异常，如果在producer程序中配置了重试次数，那么只要在规定的重试次数内自行恢复了，便不会出现在onCompletion的exception中。*不过若超过了重试次数仍没有成功，则仍然会被封装进exception中。此时就需要producer程序自行处理这种异常*

所有可重试异常都继承自org.apache.kafka.cornmon.errors.RetriableException抽象类。理论上讲所有未继承自RetriableException类的其他异常都属于不可重试异常，这类异常通常都表明了 些非常严重或Kafka无法处理的问题，不可重试异常如下

RecordTooLargeException：发送的消息尺寸过大，超过了规定的大小上限，显然这种异常无论如何重试都是无法成功的
SerializationException：序列化失败异常，这也是无法恢复的
KafkaException：其他类型的异常

*所有这些不可重试异常一旦被捕获都会被封装进Future的计算结果井返回给producer程序，用户需要自行处理这些异常*，*由于不可重试异常和可重试异常在 producer 程序端可能有不同的处理逻辑，因此可以使用下面的代码进行区分：*

```java
producer.send(new ProducerRecord<>("test", Integer.toString(100), Integer.toString(100)),
        new Callback() {
            @Override
            public void onCompletion(RecordMetadata metadata, Exception exception) {
                if (exception == null) {
                    System.out.println("消息发送成功");
                } else {
                    if (exception instanceof RetriableException) {
                        System.out.println("处理可重试异常");
                    } else {
                        System.out.println("处理不可重试异常");
                    }
                }
            }
        });
```

##### 关闭Producer

*producer进程结束时一定要关闭producer*

```
producer.close();
```

如果是调用普通的无参数close方法，producer会被允许先处理完之前的发送请求后再关闭，即所谓的“优雅”关闭退出（graceful shutdown)；同时，KafkaProducer还提供了一个带超时参数的close方法

```
void close(long timeout, TimeUnit unit);
```

如果调用此方法，producer会等待timeout时间来完成所有处理中的请求，然后强行退出。这就是说，若timeout超时，则producer会强制结束，并立即丢弃所有未发送以及未应答的发送请求。在某种程度上，这会给用户一种错觉：仿佛 producer端的程序丢失了要发送的消息。因此在实际场景中一定要谨慎使用带超时的close方法

#### producer主要参数

*详细的参数列表以及含义和默认值可以访问https://kafka.apache.org/documentation/#producer-configs*

```java
public static void main(String[] args) {
    Properties properties= new Properties();
    properties.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "47.103.7.129:9092");//必须指定
    properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");//必须指定
    properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");//必须指定
    properties.put(ProducerConfig.ACKS_CONFIG, "1");
    properties.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);
    properties.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "lz4");
    properties.put(ProducerConfig.RETRIES_CONFIG, 3);
    properties.put(ProducerConfig.RETRY_BACKOFF_MS_CONFIG, 1000);
    properties.put(ProducerConfig.BATCH_SIZE_CONFIG, 1048576);
    properties.put(ProducerConfig.LINGER_MS_CONFIG, 100);
    properties.put(ProducerConfig.MAX_REQUEST_SIZE_CONFIG, 10485760);
    properties.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 3000);

    Producer<String, String> producer= new KafkaProducer<>(properties);

    System.out.println("开始发送");
    producer.send(new ProducerRecord<>("yfzhuTest", Integer.toString(100), Integer.toString(100)),
            new Callback() {
                @Override
                public void onCompletion(RecordMetadata metadata, Exception exception) {
                    if (exception == null) {
                        System.out.println("消息发送成功");
                    } else {
                        if (exception instanceof RetriableException) {
                            System.out.println("处理可重试异常");
                            System.out.println(exception.getClass());
                        } else {
                            System.out.println("处理不可重试异常");
                        }
                    }
                }
            });

    producer.close();
}
```

##### bootstrap.servers

该参数指定了一组host:port对，用于创建向Kafka broker服务器的连接，比如host1:9092,host2:9092，不同的broker地址之间用逗号隔开。producer使用时需要替换成实际的broker列表。*如果Kafka集群中机器数很多，那么只需要指定部分broker即可，不需要列出所有的机器。因为不管指定几台机器，producer都会通过该参数找到并发现集群中所有的broker：KafkaProducer向bootstrap.servers所配置的地址指向的Server发送MetadataRequest请求，bootstrap.servers所配置的地址指向的Server返回MetadataResponse给KafkaProducer，MetadataResponse中包含了Kafka集群的所有元数据信息*。为该参数指定多台机器只是为了故障转移使用。这样即使某台broker挂掉了，producer重启后依然可以通过该参数指定的其他broker连入Kafka集群

```
properties.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "47.103.7.129:9092");
```

##### key.serializer

被发送到broker端的任何消息的格式都必须是字节数组，因此消息的各个组件必须首先做序列化，然后才能发送到broker。该参数就是为消息的key做序列化之用的。这个参数指定的是实现了org.apache.kafka.common.serialization包下接口的类的全限定名称。Kafka为大部分的初始类型(primitive type)默认提供了现成的序列化器。这个参数用户可以自定义序列化器，只要实现Serializer接口即可。需要注意的是，即使producer程序在发送消息时不指定key，*这个参数也是必须要设置的*，否则程序会抛出ConfigException异常，提示“key srializer,"参数无默认值，必须要配置

```
properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
```

##### value.serializer

该参数被用来对消息体（即消息value）部分做序列化，将消息value部分转换成宇节数组。**一定要注意的是，如果在Properties对象中指定这两个参数，那么这两个参数都必须是全限定类名。只使用单独的类名是不行的，比如必须是orgapache kafka como.srilaiationoSerializer这样的形式。这规定对于自定义序列化也是适用的**

```
properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");
```

##### acks(影响持久性和吞吐量)

acks参数用于控制producer生产消息的**持久性(durability)**。对于producer而言，Kafka在乎的是“已提交”消息的持久性。一旦消息被成功提交，那么只要有任何一个保存了该消息的副本"存活”，这条消息就会被视为“不会丢失的”。经常碰到有用户抱怨Kafka的producer会丢消息，其实这里混淆了一个概念，即那些所谓的“已丢失”的消息其实并没有被成功写入Kafka。换句话说，它们并没有被成功提交，**因此Kafka对这些未被成功提交消息的持久性不做任何保障**

具体来说，当producer发送一条消息给Kafka集群时，这条消息会被发送到指定topic分区leader所在的broker上，producer等待从该leader broker返回消息的写入结果(当然并不是无限等待，是有超时时间的)以确定消息被成功提交。这一切完成后，producer可以继续发送新的消息。Kafka能够保证的是consumer永远不会读取到尚未提交完成的消息这和关系型数据库很类似，即在大部分情况下，某个事务的SQL查询都不会看到另一个事务中尚未提交的数据

显然，leader broker何时发送写入结果返还给producer就是一个需要仔细考虑的问题了，**它也会直接影响消息的持久性甚至是producer端的吞吐量:producer端越快地接收到leader broker响应，它就能越快地发送下一条消息，即吞吐量也就越大**

producer端的acks参数就是用来控制做这件事情的。acks指定了在给producer发送响应前，leader broker必须要确保已成功写入该消息的副本数。当前acks有3个取值: 0、1和all

* acks = 0：设置成0表示producer完全不理睬leader broker端的处理结果。此时，producer发送消息后立即开启下一条消息的发送，根本不等待leader broker端返回结果。由于不接收发送结果，**因此在这种情况下producer.send的回调也就完全失去了作用**，即用户无法通过回调机制感知任何发送过程中的失败，所以acks=0时producer并不保证消息会被成功发送。但凡事有利就有弊，由于不需要等待响应结果，通常这种设置下producer的吞吐量是最高的

* acks = all或者-1：表示当发送消息时，leader broker不仅会将消息写入本地日志，同时还会**等待ISR中所有其他副本都成功写入它们各自的本地日志**后，才发送响应结果给producer。显然当设置acks=all时，只要ISR中至少有一个副本是处于“存活”状态的，那么这条消息就肯定不会丢失，因而可以达到最高的消息持久性，但通常这种设置下producer的吞吐量也是最低的

* acks = 1：是0和all折中的方案，也是默认的参数值。producer发送消息后leader broker仅将该消息写入本地日志，然后便发送响应结果给producer，而无须等待ISR中其他副本写入该消息。那么此时只要该leader broker一直存活， Kafka就能够保证这条消息不丢失。这实际上是一种折中方案，既可以达到**适当的**消息持久性，同时也保证了producer端的吞吐量

总结一下，acks参数**控制producer实现不同程度的消息持久性**，它有3个取值，对应的优缺点以使用场景下

|   acks    | producer吞吐量 | 消息持久性 |                  使用场景                   |
| :-------: | :------------: | :--------: | :-----------------------------------------: |
|     0     |      最高      |    最差    | 1.完全不关心消息是否发送成功 2.允许消息丢失 |
|     1     |      适中      |    适中    |                一般场景即可                 |
| all或者-1 |      最差      |    最高    |              不能容忍消息丢失               |

在producer程序中设置acks非常简单，只需要在构造KafkaProducer的Properties对象中增加“acks"属性即可，值得注意的是，**该参数的类型是字符串**，因此必须要写成"1"而不是1，否则程序会报错，提示你没有指定正确的参数类型

```
properties.put("acks", "1");
//或者
properties.put(ProducerConfig.ACKS_CONFIG, "1");
```

##### buffer.memory(影响吞吐量)

该参数指定了producer端用于缓存消息的缓冲区大小，单位是字节，默认值是3554432，即32MB。由于采用了异步发送消息的设计架构，Java版本producer启动时会首先创建一块内存缓冲区用于保存待发送的消息，然后由另一个专属线程负责从缓冲区中读取消息执行真正的发送。这部分内存空间的大小即是由buffer memory参数指定的。若producer向缓冲区写消息的速度超过了专属IO线程发送消息的速度，那么必然造成该缓冲区空间的不断增大。此时producer会停止手头的工作等待IO线程追上来，若一段时间之后IO线程还是无法追上producer的进度，那么producer就会抛出异常并期望用户介入进行处理

虽说producer在工作过程中会用到很多部分的内存，**但几乎可以认为该参数指定的内存大小就是producer程序使用的内存大小**。**若producer程序要给很多分区发送消息，那么就需要仔细地设置这个参数以防止过小的内存缓冲区降低了producer程序整体的吞吐量**

```
properties.put("buffer.memory", 33554432);
//或者
properties.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);
```

##### compression.type(影响吞吐量)

compression.type参数设置producer端是否压缩消息，默认值是none，即不压缩消息。和任何系统相同的是，**Kafka的producer端引入压缩后可以显著地降低网络I/O传输开销从而提升整体吞吐量，但也会增加producer端机器的CPU开销**。另外，**如果broker端的压缩参数设置得与producer不同，broker端在写入消息时也会额外使用CPU资源对消息进行对应的解压缩-重压缩操作**

目前Kafka支持3种压缩算法:GZIP、Snappy和LZ4。根据实际使用经验来看producer结合LZ4的性能是最好的。由于Kafka源代码中某个关键设置的硬编码使得Snappy的表现远不如LZ4,因此至少对于当前最新版本的Kafka(1.0.0 版本)而言，若要使用压缩，compresson.type最好设置为LZ4

```
properties.put("compression.type", "lz4");
//或者
properties.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "lz4");
```

##### retries(影响可靠性)

Kafka broker在处理写入请求时可能因为瞬时的故障(比如瞬时的leader选举或者网络抖动)导致消息发送失败。这种故障通常都是可以自行恢复的，如果把这些错误封装进回调函数的异常中返还给producer，producer程序也并没有太多可以做的，只能简单地在回调函数中重新尝试发送消息。与其这样，还不如producer内部自动实现重试。因此Java版本producer在内部自动实现了重试，当然前提就是要设置retries参数

该参数表示进行重试的次数，默认值是0,表示不进行重试。在实际使用过程中，设置重试可以很好地应对那些瞬时错误，因此推荐用户设置该参数为一个大于0的值。只不过在考虑
retries的设置时，有两点需要着重注意

* 重试可能造成消息的重复发送中比如由于瞬时的网络抖动使得broker端已成功写入消息但没有成功发送响应给producer,因此producer会认为消息发送失败，从而开启重试机制。为了应对这一风险，Kafka 要求用户在consumer端必须执行去重处理。社区已于0.11.0.0版本开始支持“精确一次”处理语义，从设计上避免了类似的问题

* 重试可能造成消息的乱序，当前producer会将多个消息发送请求(默认是5个)缓存在内存中，如果由于某种原因发生了消息发送的重试，就可能造成消息流的乱序。为了避免乱序发生，Java版本producer 提供了max.n.flight.requets.per.connection参数。一旦用户将此参数设置成1，producer将确保某一时刻只能发送一个请求

另外，producer两次重试之间会停顿一段时间，以防止频繁地重试对系统带来冲击。这段时间是可以配置的，由参数retry.backff.ms指定，默认是100毫秒。由于leader“换届选举”是最常见的瞬时错误，推荐用户通过测试来计算平均leader选举时间并根据该时间来设定retries和retry.backff.ms的值

```
properties.put("retries", 100);
//或者
properties.put(ProducerConfig.RETRIES_CONFIG, 100);
```

##### batch.size(影响吞吐量和时延)

batch.size是producer最重要的参数之一!它对于调优producer吞吐量和延时性能指标都有着非常重要的作用。producer会将发往同一分区的多条消息封装进一个batch中。当batch满了的时候，producer会发送batch中的所有消息。不过，producer并不总是等待batch满了才发送消息，很有可能当batch还有很多空闲空间时producer就发送该batch

显然，batch的大小就显得非常重要。通常来说，一个小的batch中包含的消息数很少，因而一次发送请求能够写入的消息数也很少，所以producer的吞吐量会很低，但时延会比较低;但若一个batch非常之巨大，那么会给内存使用带来极大的压力，因为不管是否能够填满，producer都会为该batch分配固定大小的内存。因此batch.size参数的设置其实是一种时间与空间权衡的体现

batch.size参数默认值是16384，即16KB。这其实是一个非常保守的数字。在实际使用过程中合理地增加该参数值，通常都会发现producer的吞吐量得到了相应的增加

```
properties.put("batch.size", 1048576);
//或者
properties.put(ProducerConfig.BATCH_SIZE_CONFIG, 1048576);
```

##### linger.ms(影响吞吐量和时延)

linger.ms参数就是控制消息发送延时行为的。该参数默认值是0，表示消息需要被立即发送，无须关心batch是否已被填满，大多数情况下这是合理的，毕竟总是希望消息被尽可能快地发送。不过这样做会拉低producer吞吐量，毕竞producer发送的每次请求中包含的消息数越多，producer就越能将发送请求的开销摊薄到更多的消息上，从而提升吞吐量

```
properties.put("linger.ms", 100);
//或者
properties.put(ProducerConfig.LINGER_MS_CONFIG, 100);
```

##### max.request.size(影响吞吐量)

该参数用于控制producer发送请求的大小。实际上该参数控制的是producer端能够发送的最大消息大小。由于请求有一些头部数据结构，因此包含一条消息的请求的大小要比消息本身大。不过姑且把它当作请求的最大尺寸是安全的。如果producer要发送尺寸很大的消息，那么这个参数就是要被设置的。默认的10485760字节

```
properties.put("max.request.size", 10485160);
//或者
properties.put(ProducerConfig.MAX_REQUEST_SIZE_CONFIG, 10485760);
```

##### request.timeout.ms(影响吞吐量)

当producer发送请求给broker后，broker需要在规定的时间范围内将处理结果返还给producer。这段时间便是由该参数控制的，默认是30秒。这就是说，如果broker在30秒内都没有给producer发送响应，那么producer就会认为该请求超时了，并在回调函数中显式地抛出TimeoutException异常交由用户处理

默认的30秒对于一般的情况而言是足够的，但如果producer发送的负载很大，超时的情况就很容易碰到，此时就应该适当调整该参数值

```
properties.put("request.timeout.ms", 6000);
//或者
properties.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 6000);
```

#### 消息分区机制

Kafka producer发送过程中一个很重要的步骤就是要确定将消息发送到指定的topic的哪个分区中。producer提供了分区策略以及对应的分区器(paritioner)供用户使用。Kafka默认的partitioner会尽力确保具有相同key的所有消息都会被发送到相同的分区上;若没有为消息指定key,则该partitioner会选择轮询的方式来确保消息在topic的所有分区上均匀分配

##### 自定义分区机制

对于有key的消息而言，**Java版本producer自带的partitioner会根据murmur2算法计算消息key的哈希值，然后对总分区数求模得到消息要被发送到的目标分区号**。但是有的时候用户可能想实现自己的分区策略，而这又是默认partitioner无法提供的，那么此时用户就可以使用producer提供的自定义分区策略

要使用自定义分区机制，用户需要完成两件事情：*1.实现org.apache.kafka.clients.producer.Partitioner接口，实现Partitioner.partition方法 2.Properties对象中设置 partitioner.class参数*

partitioner接口的主要方法是partition方法，该方法接收消息所属的topic、key和value，还有集群的元数据信息，-起来确定目标分区;而close方法是用于关闭partitioner的，主要
是为了关闭那些创建partitioner时初始化的系统资源等

```
@Override
public int partition(String topic, Object key, byte[] keyBytes, Object value, byte[] valueBytes, Cluster cluster) {
    System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " 开始分区");
    return ((Integer) key) % cluster.partitionCountForTopic("serializerTest");
}

@Override
public void close() {
    System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " PartitionTest关闭");
}

@Override
public void configure(Map<String, ?> configs) {

}
```

```
properties.put(ProducerConfig.PARTITIONER_CLASS_CONFIG, "char04.PartitionTest");
```

#### 消息序列化

在网络中发送数据都是以字节的方式，Kafka也不例外。序列化器(serializer)负责在producer发送前将消息转换成字节数组；而与之相反，解序列化器(deserializer)则用于将consumer 接收到的字节数组转换成相应的对象

producer已经初步建立了序列化机制来应对简单的消息类型，但若涉及复杂的类型(比如Avro或其他序列化框架)，那么就需要用户自行定义serializer

##### 自定义序列化

若要编写一个自定义的serializer，需要完成3件事情：1.定义数据对象格式 2.创建自定义序列化类，实现org.apache.kafka.common.serialization.Serializer接口，在serializer方法中实现序列化逻辑 3.Properties对象中设置参数

```java
@Override
public void configure(Map configs, boolean isKey) {

}

@Override
public byte[] serialize(String topic, User user) {
    System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " 开始序列化");

    Kryo kryo = new Kryo();
    kryo.register(User.class);

    Output output = new Output(500);
    kryo.writeObject(output, user);

    byte[] bytes = output.getBuffer();
    output.close();
    return bytes;
}

@Override
public void close() {
    System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " SerializerTest关闭");
}
```

```
properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "char04.SerializerTest");
```

#### producer拦截器

主要用于实现clients端的定制化控制逻辑，对于producer而言，interceptor使得用户在消息发送前以及producer回调逻辑前有机会对消息做-些定制化需求，比如修改消息等。同时，producer允许用户指定多个interceptor按序作用于同一条消息从而形成一个拦截链(interceptor chain)。interceptor的实现接口是org.apache.kafka.clients.producer.ProducerInterceptor，其定义了如下方法

* onSend(ProducerRecord)：该方法封装进KafkaProducer.send方法中，即它运行在用户主线程中。**producer确保在消息被序列化以计算分区前调用该方法**。用户可以在该方
  法中对消息做任何操作，但最好保证不要修改消息所属的topic和分区，否则会影响目标分区的计算

* onAcknowledgement(RecordMetadata, Exception)：**该方法会在消息被应答之前或消息发送失败时调用，并且通常都是在producer回调逻辑触发之前**。**onAcknowledgement运行在producer 的IO线程中，因此不要在该方法中放入很“重"的逻辑，否则会拖慢producer的消息发送效率**

* close：关闭interceptor，主要用于执行些资源清理工作

iterceptor可能运行在多个线程中，因此在具体实现时用户需要**自行确保线程安全**。另外，若指定了多个interceptor，则producer将按照指定顺序调用它们，同时把每个interceptor中**捕获的异常记录到错误日志中而不是向上传递**。这在使用过程中要特别留意

```
@Override
public ProducerRecord<Integer, User> onSend(ProducerRecord<Integer, User> record) {
    System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " 执行过滤操作");
    return record;
}

@Override
public void onAcknowledgement(RecordMetadata metadata, Exception exception) {

}

@Override
public void close() {
    System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " InterceptorTest关闭");
}

@Override
public void configure(Map<String, ?> configs) {

}
```

```
private int errorCounter = 0;
private int successCounter = 0;

@Override
public ProducerRecord<Integer, User> onSend(ProducerRecord<Integer, User> record) {
    return record;
}

@Override
public void onAcknowledgement(RecordMetadata metadata, Exception exception) {
    if (exception == null) {
        successCounter++;
        System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " 成功数量：" + successCounter);
    } else {
        errorCounter++;
        System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " 失败数量：" + errorCounter);
    }
}

@Override
public void close() {
    System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " CounterInterceptor关闭");
}

@Override
public void configure(Map<String, ?> configs) {

}
```

```
List<String> interceptors = new ArrayList<>();
interceptors.add("char04.InterceptorTest");
interceptors.add("char04.CounterInterceptor");

properties.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, interceptors);
```

#### 消息压缩

数据压缩显著地降低了磁盘占用或带宽占用，从而有效地提升了IO密集型应用的性能。不过引入压缩同时会消耗额外的CPU时钟周期，因此压缩是I/O性能和CPU资源的平衡(trade-off)。Kafka自0.7.x版本便开始支持压缩特性，producer端能够将一批消息压缩成一条消息发送，而broker端将这条压缩消息写入本地日志文件。当consumer获取到这条压缩消息时，它会自动地对消息进行解压缩，还原成初始的消息集合返还给用户。如果使用一句话来总结Kafka压缩特性的话，那么就是producer端压缩，broker端保持，consumer端解压缩。所谓的broker端保持是指broker端在通常情况下不会进行解压缩操作，它只是原样保存消息而已。这里的“通常情况下”表示要满足一定的条件。如果有些前置条件不满足(比如需要进行消息格式的转换等)，那么broker端就需要对消息进行解压缩然后再重新压缩

当前Kafka支持3种压缩算法:GZIP、Snappy和LZ4。虽然默认情况下Kafka是不压缩消息的，但用户可以通过设定producer端参数compression.type来开启消息压缩

```
properties.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "lz4");
```

##### 算法性能比较与调优

**KafkaProducer.send方法逻辑的主要耗时都在消息压缩操作上，因此妥善地调优压缩算法至关重要**。目前Kafka对LZ4压缩算法的支持是最好的。启用LZ4进行消息压缩的producer的吞吐量是最高的

首先判断是否启用压缩的依据是IO资源消耗与CPU资源消耗的对比。如果生产环境中的IO资源非常紧张，比如producer程序消耗了大量的网络带宽或broker端的磁盘占用率非常高，而producer端的CPU资源非常富裕，那么就可以考虑为producer开启消息压缩。反之则不需要设置消息压缩以节省宝贵的CPU时钟周期。

其次，**压缩的性能与producer端的batch大小息息相关。通常情况下可以认为batch越大需要压缩的时间就越长**

batch大小越大，压缩时间就越长，不过时间的增长不是线性的，而是越来越平缓的。**如果发现压缩很慢，说明系统的瓶颈在用户主线程而不是IO发送线程，因此可以考虑增加多个用户线程同时发送消息，这样通常能显著地提升producer吞吐量**

#### 多线程处理

实际环境中 只使用一个用户主线程通常无法满足所需的吞吐量目标，因此需要构造多个线程或多个进程来同时给Kafka集群发送消息。这样在使用过程中就存在着两种基本的使用方法

* 多线程单KafkaProducer实例
* 多线程多KatkaProducer实例

*多线程单KafkaProducer实例*

顾名思义，这种方法就是在全局构造一个KafkaProducer实例，然后在多个线程中共享使用。由于**KafkaProducer是线程安全的**，所以这种使用方式也是线程安全的

*多线程多KatkaProducer实例*

在每个producer主线程中都构造一个KafkaProducer实例，并且保证此实例在该线程中封闭(thread confinement，线程封闭是实现线程安全的重要手段之一)

|                           |                  说明                   |                             优势                             |                             劣势                             |
| :-----------------------: | :-------------------------------------: | :----------------------------------------------------------: | :----------------------------------------------------------: |
| 多线程单KafkaProducer实例 |    所有线程共享一个KafkaProducer实例    |                       实现简单，性能好                       | 1.所有线程共享一个内存缓冲区，可能需要较多内存 2.一旦producer某个线程崩溃导致KafkaProducer实例被“破坏”，则所有用户线程都无法工作 |
| 多线程多KatkaProducer实例 | 每个线程维护自己专属的KafkaProducer实例 | 1.每个用户线程拥有专属的KafkaProducer实例、缓冲区空间及一组对应的配置参数，可以进行细粒度的调优 2.单个KafkaProducer崩溃不会影响其他producer线程工作 |                    需要较大的内存分配开销                    |

**如果是对分区数不多的Kafka集群而言，比较推荐使用第一种方法，即在多个producer用户线程中共享一个KafkaProducer实例。若是对那些拥有超多分区的集群而言，采用第二种方法具有较高的可控性**

#### 无消息丢失配置

Java版本producer用户采用异步发送机制。**KafkaProducer.send方法仅仅把消息放入缓冲区中，由一个专属I/O线程负责从缓冲区中提取消息并封装进消息batch中，然后发送出去**。显然，这个过程中存在着数据丢失的窗口：**若I/O线程发送之前producer崩溃，则存储缓冲区中的消息全部丢失了**。这是producer需要处理的很重要的问题

producer的另一个问题就是消息的乱序。假设客户端依次执行下面的语句发送两条消息到相同的分区：

```
producer.send(record1);
producer.send(record2);
```

若此时由于某些原因(比如瞬时的网络抖动)导致record1未发送成功，同时Kafka又配置了重试机制以及max.in.flight.requests.per.connection大于1(默认值是5)，那么producer重试record1成功后，record1在日志中的位置反而位于record2之后，这样造成了消息的乱序，实际使用场景中都有事件强顺序保证的要求

具体配置参数列表如下：

* block.on.buffer.full = true

实际上这个参数在Kafka 0.9.0.0 版本已经被标记为“deprecated"，并使用max.block.ms参数替代，但这里还是推荐用户显式地设置它为true，使得内存缓冲区被填满时producer处于阻塞状态并停止接收新的消息而不是抛出异常；否则producer生产速度过快会耗尽缓冲区。新版本Kafka(0.10.0.0之后)可以不用理会这个参数，转而设置max.block.ms即可

* acks = all or -1

即必须要等到所有follower都响应了发送消息才能认为提交成功，这是producer端最强程度的持久化保证

* retries = Integer.MAX_VALUE

设置成MAX_VALUE纵然有些极端，但其实想表达的是producer要开启无限重试。用户不必担心producer会重试那些肯定无法恢复的错误，当前producer只会重试那些可恢复的异常
情况，所以放心地设置一个比较大的值通常能很好地保证消息不丢失

* max.in.flight.requests.per.connection = 1

设置该参数为1主要是为了防止topic同分区下的消息乱序问题。这个参数的实际效果其实限制了producer在单个broker连接上能够发送的未响应请求的数量。因此，如果设置成1，则producer在某个broker发送响应之前将无法再给该broker发送PRODUCE请求

* 使用带回调机制的send发送消息，即KafkaProducer.send(record, callback)

**不要使用KafkaProducer中单参数的send方法，因为该send调用仅仅是把消息发出而不会理会消息发送的结果。如果消息发送失败，该方法不会得到任何通知，故可能造成数据的丢失。实际环境中一定要使用带回调机制的send版本，即KafkaProducer.send(record, callback)**

* Callback逻辑中显式地立即关闭producer，使用close(0)

在Callback的失败处理逻辑中显式调用KafkaProducer.close(0)。这样做的目的是为了处理消息的乱序问题。若不使用close(0)，默认情况下producer会被允许将未完成的消息发送出去，这样就有可能造成消息乱序

* unclean.leader.election.enable = false

关闭unclean leader选举，即不允许非ISR中的副本被选举为leader，从而避免broker端因日志水位截断而造成的消息丢失

* replication.factor >= 3

设置成3主要是参考了Hadoop及业界通用的三备份原则，其实这里想强调的是一定要使用多个副本来保存分区的消息

* min.insync.replicas >= 1

用于控制某条消息至少被写入到ISR中的多少个副本才算成功，设置成大于1是为了提升producer端发送语义的持久性。**记住只有在producer端acks被设置成all或-1时，这个参数才有意义。在实际使用时，不要使用默认值**

* replication.factor > min.insync.replicas

若两者相等，那么只要有一个副本挂掉，分区就无法正常工作，虽然有很高的持久性但可用性被极大地降低了。推荐配置成replication.factor = min.insyn.replicas + 1

* enable.auto.commit = false

https://blog.csdn.net/chaiyu2002/article/details/89472416

#### 示例程序

```java
public static void main(String[] args) {
    Properties properties= new Properties();
    properties.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "47.103.7.129:9092");//必须指定
    properties.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.IntegerSerializer");//必须指定
    //properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringSerializer");//必须指定
    properties.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "char04.SerializerTest");//必须指定
    properties.put(ProducerConfig.ACKS_CONFIG, "1");
    properties.put(ProducerConfig.BUFFER_MEMORY_CONFIG, 33554432);
    properties.put(ProducerConfig.COMPRESSION_TYPE_CONFIG, "lz4");
    properties.put(ProducerConfig.RETRIES_CONFIG, 3);
    properties.put(ProducerConfig.RETRY_BACKOFF_MS_CONFIG, 1000);
    properties.put(ProducerConfig.BATCH_SIZE_CONFIG, 1048576);
    properties.put(ProducerConfig.LINGER_MS_CONFIG, 3000);
    properties.put(ProducerConfig.MAX_REQUEST_SIZE_CONFIG, 10485760);
    properties.put(ProducerConfig.REQUEST_TIMEOUT_MS_CONFIG, 3000);
    properties.put(ProducerConfig.PARTITIONER_CLASS_CONFIG, "char04.PartitionTest");

    List<String> interceptors = new ArrayList<>();
    interceptors.add("char04.InterceptorTest");
    interceptors.add("char04.CounterInterceptor");

    properties.put(ProducerConfig.INTERCEPTOR_CLASSES_CONFIG, interceptors);

    //Producer<Integer, String> producer= new KafkaProducer<>(properties);
    Producer<Integer, User> producer= new KafkaProducer<>(properties);

    System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " 开始发送");

    for (int i = 0;i < 10;i++) {
        producer.send(new ProducerRecord<>("serializerTest", 100, new User("fname",
                        "lname",
                        2,
                        "ad")),
                new Callback() {
                    @Override
                    public void onCompletion(RecordMetadata metadata, Exception exception) {
                        if (exception == null) {
                            System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " 消息发送成功");
                        } else {
                            if (exception instanceof RetriableException) {
                                System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + " 处理可重试异常");
                                System.out.println(exception.getClass());
                            } else {
                                System.out.println(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss:SSS")) + Thread.currentThread().getName() + "处理不可重试异常");
                            }
                        }
                    }
                });
    }

    producer.close();
}
```

### Consumer 开发

#### consumer 概览

##### 消费者（consumer)

consumer是读取Kafka集群中某些topic消息的应用程序，在当前Kafka生态中， consumer可以由多种编程语言实现，比如常见的 Java、C++、Go等。Kafka最初开源时自带由Scala语言编写的consumer客户端，称之为Scala consumer或Old consumer，即旧版本consumer。社区在0.9.0.0版本正式推出了新版本的consumer客户端。由于是用Java语言编写的，因此称之为Java consumer或new consumer ，即新版本consumer

consumer 分为如下两类：

* 消费者组（consumer group)
* 独立消费者（standalone consumer)

consumer group是由多个消费者实例（consumer instance）构成一个整体进行消费的，而standalone consumer则单独执行消费操作

##### 消费者组（consumer group)

官网关于consumer group的定义：*Consumers label themselves with a consumer group name, and each record published to a topic is* 

*delivered to one consumer instance within each subscribing consumer group.*

翻译一下就是：消费者使用一个消费者组名（即group.id）来标记自己，topic的每条消息都只会被发送到每个订阅它的消费者组的一个消费者实例上

这句话给出了三个非常重要的信息

* 一个consumer group可能有若干个consumer实例（group只有一个实例也是允许的）
* **对于同一个group而言，topic的每条消息只能被发送到group下的一个consumer实例上**
* topic消息可以被发送到多个group中

Kafka同时支持基于队列和基于发布/订阅的两种消息引擎模型，事实上Kafka就是通过consumer group实现的对这两种模型的支持

* 所有consumer实例都属于相同group：实现基于队列的模型。每条消息只会被consumer实例处理
* consumer实例都属于不同 group：实现基于发布/订阅的模型。极端的情况是每个consumer实例都设置完全不同的group，这样Kafka消息就会被广播到所有consumer实例上

实际上，consumer group是用于实现**高伸缩性、高容错性**的consumer机制。组内多个consumer实例可以同时读取Kafka消息，而且一旦有某个consumer“挂”了，consumer group会立即将已崩溃consumer负责的分区转交给其他consumer来负责，从而保证整个group可以继续工作，不会丢失数据。这个过程被称为重平衡(rebalance)

**由于Kafka目前只提供单个分区内的消息顺序，而不会维护全局的消息顺序，因此如果用户要实现topic全局的消息读取顺序，就只能通过让每个consumer group下只包含一个consumer实例的方式来间接实现**

consumer group的特点：

* consumer group下可以有一个或多个consumer实例 。**一个consumer实例可以是一个线程，也可以是运行在其他机器上的进程**
* group.id唯一标识一个consumer group
* 对某个group而言，订阅topic的每个分区只能分配给该group下的consumer实例，(当然该分区还可以被分配给其他订阅该topic的消费者组)

##### 位移（offset)

这里的offset指代的是consumer端的offset，与分区日志中的offset是不同的含义。每个consumer实例都会为它消费的分区维护属于自己的位置信息来记录当前消费了多少条消息，这就是位移(offset)。很多消息引擎都把消费者端的offset保存在服务器端broker，这样做的好处是实现简单，但会有以下三个方面的问题：

* broker从此变成了有状态的，增加了同步成本，响伸缩性
* 需要引入应答机制(acknowledgement)来确认消费成功
* **由于要保存许多consumer的offset，故必然引入复杂的数据结构，从而造成不必要的资源浪费**

**Kafka选择了让consumer group保存offset，只需要简单地保存长整型数据就可以了**，同时Kafka consumer还引入了检查点机制（checkpointing）定期对offset进行持久化，从而简化了应答机制的实现

**Kafka consumer在内部使用map来保存其订阅topic所属分区的offset**

##### 位移提交

consumer客户端需要定期地向Kafka集群汇报自己消费数据的进度，这一过程被称为**位移提交（offset commit）**。位移提交对于consumer非常重要，它不仅代表了consumer端的消费进度，同时也直接决定了consumer端的消费语义保证

**新版本的consumer把位移提交到Kafka的一个内部topic(__consumer_offsets)上。注意，这个topic名字前面有两个下划线**

对于普通用户来说，通常不能直接操作该topic，**特别注意不要擅自删除或挪动topic的日志文件**。由于新版本consumer提交位移到这个topic，因此consumer不再依赖ZooKeeper，这就是为什么开发新版本consumer应用时不再需要连接ZooKeeper的原因

##### __consumer_offsets

这个内部topic就是为新版本consumer保存位移使用的。**__consumer_offsets是Kafka自行创建的，因此用户不可擅自删除该topic的所有信息**

__consumer_offsets的消息是KV格式的，key就是元组group.id + topic ＋分区号，而value就是offset的值，每当更新同一个key的最新offset值时，该topic就会写入一条含有最新offset的消息，同时Kafka会定期地对该topic进行压实操作（compact），即为每个消息的key只保存含有最新offset消息，这样既避免了对分区日志消息的修改，也控制住了consumer_offsets总体的日志容量，同时还能实时反映最新的消费进度

考虑到Kafka生产环境中可能有很多consumer consumer group，如果这些consumer同时提交位移，则必将加重__consumer_offsets的负载，因此社区特意为该topic建了50个分区，对应的文件夹有50个，编号从0到 49，并且对每个group.id做哈希求模运算，从而将负载分散到不同的＿consumer_offsets分区上，这就说，每个consumer group存的offset有极大的概率分别出现在该topic的不同分区上

##### 消费者组重平衡（consumer group rebalance）

如果用户使用的是standalone consumer，则没有rebalance的概念，**即rebalance只对consumer group有效**

rebalance本质上是一种协议，规定了consumer group下所有consumer如何达成一致来分配订阅topic的所有分区。假设有一个consumer group，有20个consumer实例。该group订阅了一个具有100个分区的topic，那么正常情况下，consumer group平均会为每个consumer分配5个分区，即每个consumer负责读取5个分区的数据。这个分配过程就被称作rebalance

#### 构建consumer

```java
    /*
Topic: partitionTest	PartitionCount: 4	ReplicationFactor: 1	Configs:
	Topic: partitionTest	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
	Topic: partitionTest	Partition: 1	Leader: 0	Replicas: 0	Isr: 0
	Topic: partitionTest	Partition: 2	Leader: 0	Replicas: 0	Isr: 0
	Topic: partitionTest	Partition: 3	Leader: 0	Replicas: 0	Isr: 0
Topic: serializerTest	PartitionCount: 1	ReplicationFactor: 1	Configs:
	Topic: serializerTest	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
Topic: test	PartitionCount: 1	ReplicationFactor: 1	Configs:
	Topic: test	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
Topic: test2	PartitionCount: 4	ReplicationFactor: 1	Configs:
	Topic: test2	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
	Topic: test2	Partition: 1	Leader: 0	Replicas: 0	Isr: 0
	Topic: test2	Partition: 2	Leader: 0	Replicas: 0	Isr: 0
	Topic: test2	Partition: 3	Leader: 0	Replicas: 0	Isr: 0
Topic: yfzhuTest	PartitionCount: 1	ReplicationFactor: 1	Configs:
	Topic: yfzhuTest	Partition: 0	Leader: 0	Replicas: 0	Isr: 0
     */
    public static void main(String[] args) {
        String topicName = "partitionTest";
        String groupId = "test-group";

        Properties properties= new Properties();
        properties.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "47.103.7.129:9092");//必须指定
        properties.put(ConsumerConfig.GROUP_ID_CONFIG, groupId);//必须指定
        properties.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "true");
        properties.put(ConsumerConfig.AUTO_COMMIT_INTERVAL_MS_CONFIG, "1000");
        properties.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.IntegerDeserializer");//必须指定
        properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");//必须指定

        KafkaConsumer<Integer, String> consumer= new KafkaConsumer<>(properties);
        consumer.subscribe(Arrays.asList(topicName));

        try {
            while (true) {
                ConsumerRecords<Integer, String> records = consumer.poll(1000);
                for (ConsumerRecord<Integer, String> record : records) {
                    System.out.println(record.offset() + record.key() + record.value());
                }
            }
        } finally {
            consumer.close();
        }
    }
```

##### 构造Properties对象

与构造producer流程类似，BOOTSTRAP_SERVERS_CONFIG、GROUP_ID_CONFIG、KEY_DESERIALIZER_CLASS_CONFIG、VALUE_DESERIALIZER_CLASS_CONFIG为必须配置的参数

##### 构造KafkaConsumer对象

KafkaConsumer是consumer的主入口，所有的功能基本上都是由KafkaConsumer类提供的

```java
KafkaConsumer<Integer, String> consumer= new KafkaConsumer<>(properties);
```

##### 订阅topic列表

使用KafkaConsumer.subscribe方法订阅consumer group要消费的topic列表，KafkaConsumer可以订阅多个topic

```java
consumer.subscribe(Arrays.asList(topicName));
```

该方法还支持正则表达式

```java
consumer.subscribe(Pattern.compile("kafka.*"), new NoOpConsumerRebalanceListener());
```

**需要特别注意的是，subscribe方法不是增量式的，这意味着后续的subscribe调用会完全覆盖之前的订阅语句**

```java
consumer.subscribe(Arrays.asList ("topic1","topic2","topic3"));
consumer.subscribe(Arrays.asList ("topic4","topic5","topic6"));
```

##### 获取消息

这是consumer的关键方法。consumer使用KafkaConsumer.poll方法从订阅topic中**井行地**获取多个分区的消息。为了实现这一点，新版本consumer的poll方法使用了类似于Linux的select机制：所有相关的事件（包括rebalance、获取消息等）都发生在一个事件循环(event loop)中，这样consumer端只使用一个线程就能够完成所有类型的I/O操作

```java
        try {
            while (true) {
                ConsumerRecords<Integer, String> records = consumer.poll(1000);
                for (ConsumerRecord<Integer, String> record : records) {
                    System.out.println(record.offset() + record.key() + record.value());
                }
            }
        } finally {
            consumer.close();
        }
```

最关键的调用方法当属consumer.poll(1000)。这里的1000是一个超时设定(timeout)。**通常情况下如果consumer拿到了足够多的可用数据，那么它可以立即从该方法返回;但若当前没有足够多的数据可供返回，consumer会处于阻塞状态。这个超时参数即控制阻塞的最大时间**。这里的1000 表示即使没有那么多数据，consumer最多也不要等待超过1秒的时间

**这个超时设定给予了用户能够在consumer消费间隔之余做一些其他事情的能力**。若用户有定时方面的需求，那么根据需求设定timeout是一个不错的选择

##### 处理ConsumerRecord对象

ConsumerRecord类封装的poll返回的消息，拿到这些消息后consumer通常都包含处理这些消息的逻辑

**从Kafka consumer的角度而言，poll方法返回即认为consumer成功消费了消息。如果发现poll返回消息的速度过慢，那么可以调节相应的参数来提升poll方法的效率;若消息的业务级处理逻辑过慢，则应该考虑简化处理逻辑或者把处理逻辑放入单独的线程执行**

##### 关闭consumer

consumer程序结束后一定要显式关闭consumer以释放KafkaConsumer运行过程中占用的各种系统资源(比如线程资源、内存、Socket连接等)。关闭方法有两种，通常来说使用任意一种方法都是可行的

* KafkaConsumer.close()：关闭consumer并最多等待30秒
* KafkaConsumer.close(timeout)：关闭consumer并最多等待给定的timeout秒

#### consumer主要参数

构建consumer必需的4个参数bootstrap.servers、 group.id、key.deserializer和value.deserializer。完整的参数列表及其含义和默认值可以参见htps://afka.apache.org/documentation/#newconsumerconfigs

##### bootstrap.servers

和Java版本的producer相同，这是必须要指定的参数。该参数指定了一组host:port对，用于创建与Kafka broker服务器的Socket连接。可以指定多组，使用逗号分隔

```
kafka1:9092,kafka2:9092,kafka3:9092
```

若Kafka集群中broker机器数很多，只需要指定部分broker即可，不需要列出完整的broker列表。这是因为不管指定了几台机器，consumer启动后都能通过这些机器找到完整的broker列表，因此为该参数指定多台机器通常只是为了常规的fail over使用。这样即使某一台broker挂掉了，consumer重启后依然能够通过该参数指定的其他broker连接Kafka集群

##### group.id 

该参数指定的是consumer group的名字。它能够唯一标识一个consumer group。该参数是有默认值的，即一个空字符串。但在开发consumer程序时依然要显式指定group.id,否则consumer端会抛出InvalidGroupIdException异常。通常为group.id设置一个有业务意义的名字就可以了

##### key.deserializer

consumer代码从broker端获取的任何消息都是字节数组的格式，因此消息的每个组件都要执行相应的解序列化操作才能“还原”成原来的对象格式。这个参数就是为消息的key做解序列化的。**该参数值必须是实现org.apache .kafka.common.serialization.Deserializer接口的Java类的全限定名称**。Kafka默认为绝大部分的初始类型(primitive type)提供了现成的解序列化器。consumer 支持用户自定义deserializer, 这通常都与producer 端自定义serializer “遥相呼应”

##### value.deserializer

与value.deserializer类似，该参数被用来对消息体(即消息value)进行解序列化，从而把消息“还原”回原来的对象类型。**在使用过程中，一定要谨记key.deserializer 和value.deserializer指定的是类的全限定名，单独指定类名是行不通的。这一规定对自定义deserializer也适用**

##### session.timeout.ms

非常重要的参数之一。简单来说，**session.timeout.ms是consumer group检测组内成员发送崩溃的时间**。假设设置该参数为5分钟，那么当某个group成员突然崩溃了(比如被kill -9或宕机)，管理group的Kafka组件(即消费者组协调者，也称group coordinator)有可能需要5分钟才能感知到这个崩溃。显然我们想要缩短这个时间，让coordinator能够更快地检测到consumer失败。遗憾的是，这个参数还有另外一重含义：consumer消息处理逻辑的最大时间。倘若consumer两次poll之间的间隔超过了该参数所设置的阈值，那么coordinator就会认为这个consumer已经追不上组内其他成员的消费进度了，因此会将该consumer实例“踢出”组，该Consumer负责的分区也会被分配给其他consumer。这会导致不必要的rebalance，因为consumer需要重新加入group。更糟的是，对于那些在被踢出group后处理的消息，consumer都无法提交位移，这就意味着这些消息在rebalance之后会被重新消费一遍。如果一条消息或一组消息总是需要花费很长的时间处理，那么consumer甚至无法执行任何消费，除非用户重新调整参数

**Kafka社区于0.10.1.0版本对该参数的含义进行了拆分。在该版本及以后的版本中，session.timeout.ms参数被明确为“coordinator检测失败的时间”。因此在实际使用中，用户可以为该参数设置一个比较小的值让coordinator能够更快地检测consumer崩溃的情况，从而更快地开启rebalance, 避免造成更大的消费滞后(consumer lag)。目前该参数的默认值是10秒**

##### max.poll.interval.ms

session.timeout.ms中**“consumer处理逻辑最大时间”**的含义被剥离出来了，Kafka为这部分含义单独开放了一个参数max.poll.interval.ms。对于消息的处理可能需要花费很长时间。这个参数就是用于设置消息处理逻辑的最大时间的。通过将该参数设置成实际的逻辑处理时间再结合较低的session.timeout.ms参数值，consumer group既实现了快速的consumer崩溃检测，也保证了复杂的事件处理逻辑不会造成不必要的rebalance

##### auto.offset.reset

指定了无位移信息或位移越界(即consumer要消费的消息的位移不在当前消息日志的合理区间范围)时Kafka的应对策略。**特别要注意这里的无位移信息或位移越界，只有满足这两个条件中的任何一个时该参数才有效果**。假设首次运行一个consumer group并且指定从头消费。显然该group会从头消费所有数据，因为此时该group还没有任何位移信息。一旦该group成功提交位移后，重启了group，依然指定从头消费。此时就会发现该group并不会真的从头消费，因为Kafka已经保存了该group的位移信息，因此它会无视auto.offset.reset的设置

目前该参数有如下3个可能的取值：

* earliest:指定从最早的位移开始消费。注意这里最早的位移不一定就是0
* latest:指定从最新处位移开始消费
* none:指定如果未发现位移信息或位移越界，则抛出异常。该值在真实业务场景中使用甚少

##### enable.auto.commit

该参数指定consumer是否自动提交位移。若设置为true，则consumer在后台自动提交位移；否则，用户需要手动提交位移。对于有较强“精确处理一次"语义需求的用户来说，最好将该参数设置为false，由用户自行处理位移提交问题

##### fetch.max.bytes

它指定了consumer端单次获取数据的最大字节数。若实际业务消息很大，则必须要设置该参数为一个较大的值，否则consumer将无法消费这些消息

##### max.poll.records

该参数控制单次poll调用返回的最大消息数。比较极端的做法是设置该参数为1，那么每次poll只会返回1条消息。如果用户发现consumer端的瓶颈在poll速度太慢，可以适当地增加该参数的值。如果用户的消息处理逻辑很轻量，默认的500条消息通常不能满足实际的消息处理速度

##### heartbeat.interval.ms

从表面上看，该参数似乎是心跳的间隔时间，但既然已经有session.timeout.ms用于设置超时，为何还要引入这个参数呢?这里的关键在于要搞清楚consumer group的其他成员如何得知要开启新一轮rebalance。当coordinator决定开启新一轮rebalance时，它会将这个决定以REBALANCE_IN_PROGRESS异常的形式“塞进”consumer心跳请求的response中，这样其他成员拿到response后才能知道它需要重新加入group。显然这个过程越快越好，而heartbeat.interval.ms就是用来做这件事情的

比较推荐的做法是设置一个比较低的值，让group下的其他consumer成员能够更快地感知新一轮rebalance开启了。**注意，该值必须小于session.timeout.ms!**，毕竟如果consumer在session.timeout.ms这段时间内都不发送心跳，coordinator就会认为它已经dead，因此也就没有必要让它知晓coordinator的决定了

##### connections.max.idle.ms

经常有用户抱怨在生产环境下周期性地观测到请求平均处理时间在飙升，这很有可能是因为Kafka会定期地关闭空闲Socket连接导致下次consumer处理请求时需要重新创建连向broker的Socket连接。当前默认值是9分钟，如果用户实际环境中不在乎这些Socket资源开销，比较推荐设置该参数值为-1，即不要关闭这些空闲连接

#### 订阅topic

##### 订阅topic列表

新版本consumer中consumer group订阅topic列表非常简单，使用下面的语句即可实现

```java
consumer.subscribe(Arrays.asList("topicl", "topic2", "topic3"));
```

如果是使用独立(consumer standalone consumer)，则可以使用下面的语句实现手动订阅:

```java
TopicPartition tp1 = new TopicPartition("topic-name", 0);
TopicPartition tp2 = new TopicPartition("topic-name", 1);
consumer.assign(Arrays.asList(tpl, tp2));
```

**不管是哪种方法，consumer订阅是延迟生效的，即订阅信息只有在下次poll调用时才会正式生效。如果在poll之前打印订阅信息，用户会发现它的订阅信息是空的，表明尚未生效**

##### 基于正则表达式订阅topic

除了topic列表订阅方式，新版本consumer还支持基于正则表达式的订阅方式。利用正则表达式可以达到某种程度上的动态订阅效果

```java
consumer.subscribe(Pattern.compile("kafka-.*"), new ConsumerRebalanceListener(){
  ///
});
```

使用基于正则表达式的订阅就必须指定ConsumerRebalanceListener。该类是一个回调接口，用户需要通过实现这个接口来实现consumer分区分配方案发生变更时的逻辑。如果用户使用的是自动提交(即设置enable.auto.commit=true) ，则通常不用理会这个类，使用下面的实现类就可以了:

```java
consumer.subscribe(Pattern.compile("kafka-.*"), new NoOpConsumerRebalanceListener());
```

**如果用户是手动提交位移的，则至少要在ConsumerRebalanceListener实现类的onPartitionsRevoked方法中处理分区分配方案变更时的位移提交**

#### 消息轮询

##### poll内部原理

归根结底，Kafka的consumer是用来读取消息的，而且要能够同时读取多个topic的多个分区的消息。若要实现并行的消息读取，一种方法是使用多线程的方式，为每个要读取的分区都创建一个专有的线程去消费(这其实就是旧版本consumer采用的方式)；另一种方法是**采用类似于Linux I/O模型的poll或select等，使用一个线程来同时管理多个Socket连接，即同时与多个broker通信实现消息的并行读取，这就是新版本consumer最重要的设计改变**

**一旦consumer订阅了topic，所有的消费逻辑包括coordinator的协调、消费者组的rebalance以及数据的获取都会在主逻辑poll方法的一次调用中被执行**。这样用户很容易使用一个线程来管理所有的consumer IO操作

**对Kafka(1.0.0)而言，新版本Java consumer是一个多线程或者说是一个双线程的Java进程。创建KafkaConsumer的线程被称为用户主线程，同时consumer在后台会创建一个心跳线程，该线程被称为后台心跳线程。KafkaConsumer的poll方法在用户主线程中运行。这也同时表明:消费者组执行rebalance、消息获取、coordinator管理、异步任务结果的处理甚至位移提交等操作都是运行在用户主线程中的。因此仔细调优这个poll方法相关的各种处理超时时间参数至关重要**

##### poll使用方法

consumer订阅topic之后通常以事件循环的方式来获取订阅方案并开启消息读取。用户要做的仅仅是写一个循环，然后重复性地调用poll方法。剩下所有的工作都交给poll方法帮用户完成。每次poll方法返回的都是订阅分区上的一组消息。**当然如果某些分区没有准备好，某次poll返回的就是空的消息集合**

```java
        try {
            while (true) {
                ConsumerRecords<Integer, String> records = consumer.poll(1000);
                for (ConsumerRecord<Integer, String> record : records) {
                    System.out.println(record.offset() + record.key() + record.value());
                }
            }
        } finally {
            consumer.close();
        }
```

**poll方法根据当前consumer的消费位移返回消息集合**。**当poll首次被调用时，新的消费者组会被创建并根据对应的位移重设策略(auto.offset.reset)来设定消费者组的位移**。**一旦consumer开始提交位移，每个后续的rebalance完成后都会将位置设置为上次已提交的位移**

**传递给poll方法的超时设定参数用于控制consumer等待消息的最大阻塞时间**。由于某些原因，broker端有时候无法立即满足consumer端的获取请求(比如consumer要求至少一次获取 1MB的数据，但broker端无法立即全部给出)，那么此时consumer端将会阻塞以等待数据不断累积并最终满足consumer需求。如果用户不想让consumer一直处于阻塞状态，则需要给定一个超时时间。因此poll方法返回满足以下任意一个条件即可返回

* 要么获取了足够多的可用数据
* 要么等待时间超过了指定的超时设置

consumer是单线程的设计理念(这里暂不考虑后台心跳线程，因为它只是一个辅助线程，并没有承担过重的消费逻辑)，因此consumer就应该运行在它专属的线程
中。**新版本Java consumer不是线程安全的!如果没有显式地同步锁保护机制，Kafka会抛出KafkaConsumer is not safe for multi-threaded access异常**。如果用户在调用poll方法时看到了这样的报错，通常说明用户将同一个KafkaConsumer实例用在了多个线程中。至少对于目前的Kafka设计而言，这是不被允许的，用户最好不要这样使用

**在while 的条件语句中指定了一个布尔变量来标识是否要退出consumer消费循环并结束consumer应用。具体的做法是，将布尔变量标识为volatile型，然后在其他线程中设置isRunning = false来控制consumer的结束**。**最后千万不要忘记关闭consumer。这不仅会清除consumer创建的各种Socket资源，还会通知消费者组coordinator主动离组从而更快地开启新一轮rebalance。 比较推荐的做法是，在finally代码块中显式调用consumer.close()，从而保证consumer总是能够被关闭的**

**Kafka社区为poll方法引入这个超时参数的目的其实是想让consumer程序有机会定期“醒来”去做一些其他的事情**。假设用户的consumer程序除了消费之外还需要定期地执行其他的常规任务(比如每隔10秒需要将消费情况记录到日志中)，那么用户就可以使用consumer.poll(10000)来让consumer有机会在等待Kafka消息的同时还能够定期执行其他任务。这就是使用超时设定的最大意义

若consumer除了消费消息之外没有其他的定时任务需要执行，即consumer程序唯的目的就是从Kafka获取消息然后进行处理，那么用户可采用完全不同的poll调用方法

```java
        try {
            while (true) {
                ConsumerRecords<Integer, String> records = consumer.poll(Long.MAX_VALUE);
                for (ConsumerRecord<Integer, String> record : records) {
                    System.out.println(record.offset() + record.key() + record.value());
                }
            }
        } catch (WakeupException e) {
            //
        } finally {
            consumer.close();
        }
```

让consumer程序在未获取到足够多数据时无限等待，然后通过捕获WakupException异常来判断consumer是否结束。显然，这是与第一种调用方法完全不同的使用思想。如果使用这种方式调用poll, 那么需要在另一个线程中调用consumer.wakeup()方法来触发consumer的关闭。**KafkaConsumer不是线程安全的，但是有个例外，用户可以安全地在另一个线程中调用consumer.wakeup()。注意，只有wakeup方法是特例，其他KafkaConsumer方法都不能同时在多线程中使用**

**WakeupException异常是在poll方法中被抛出的，因此如果当前事件循环代码正在执行poll之后的消息处理逻辑，则它并不会马上响应wakeup, 只会等待下次poll调用时才进行响应。所以程序表现为不能立即退出，会有一段延迟时间。这也是为什么不推荐用户将很繁重的消息处理逻辑放入poll主线程执行的原因**

简单总结一下poll的使用方法

* consumer需要定期执行其他子任务:推荐poll(较小超时时间) +运行标识布尔变量的方式
* consumer不需要定期执行子任务:推荐poll(MAX_VALUE) +捕获WakeupException的方式

#### 位移管理

##### consumer位移

**consumer端需要为每个它要读取的分区保存消费进度，即分区中当前最新消费消息的位置。该位置就被称为位移(offset)。consumer需要定期地向Kafka提交自己的位置信息，实际上，这里的位移值通常是下一条待消费的消息的位置**。**假设consumer已经读取了某个分区中的第N条消息，那么它应该提交位移值为N，因为位移是从0开始的，位移为N的消息是第N+1条消息。这样下次consumer重启时会从第N+1条消息开始消费。总而言之，offset就是consumer端维护的位置信息**

**offset对于consumer非常重要，因为它是实现消息交付语义保证( mesage delivery semantic)的基石**。常见的3种消息交付语义保证如下

* 最多一次(at most once)处理语义:消息可能丢失，但不会被重复处理
* 最少一次(at least once)处理语义:消息不会丢失，但可能被处理多次
* 精确一次(exactly once)处理语义:消息一定会被处理且只会被处理一次

**若consumer在消息消费之前就提交位移，那么便可以实现at most once，因为若consumer在提交位移与消息消费之间崩溃，则consumer重启后会从新的offset位置开始消费，前面的那条消息就丢失了。相反地，若提交位移在消息消费之后，则可实现at least once语义**。由于Kafka没有办法保证这两步操作可以在同一个事务中完成，因此Kafka默认提供的就是at least once的处理语义。好消息是**Kafka社区已于0.11.0.0版本正式支持事务以及精确一次处理语义**

offset本质上就是一个位置信息，与consumer相关的多个位置信息

* 上次提交位移(last committed offset)：consumer最近一次提交的offset值
* 当前位置(current position)：consumer已读取但尚未提交时的位置
* 水位(watermark)也被称为高水位(high watermark)，严格来说它不属于consumer管理的范围，而是属于分区日志的概念。**对于处于水位之下的所有消息，consumer都是可以读取的，consumer无法读取水位以上的消息**
* 日志终端位移(Log End Offset，LEO)：也被称为日志最新位移。同样不属于consumer范畴，而是属于分区日志管辖。它表示了某个分区副本当前保存消息对应的最大的位移值。值得注意的是，正常情况下LEO不会比水位值小。事实上，**只有分区所有副本都保存了某条消息，该分区的leader副本才会向上移动水位值**

**consumer最多只能读取到水位值标记的消息，而不能读取尚未完全被“写入成功”的消息，即位于水位值之上的消息**

##### 新版本consumer位移管理

consumer会在Kafka集群的所有broker中选择一个broker作为consumer group的coordinator，用于实现组成员管理、消费分配方案制定以及提交位移等。为每个组选择对应coordinator的依据就是内部topic(__consumer_offsets)。和普通的Kafka topic相同，该topic配置有多个分区，每个分区有多个副本。它存在的唯一目的就是保存consumer提交的位移

**当消费者组首次启动时，由于没有初始的位移信息，coordinator必须为其确定初始位移值，这就是consumer参数auto.offset.reset的作用**。通常情况下，consumer要么从最早的位移开始读取，要么从最新的位移开始读取。当consumer运行了一段时间之后，它必须要提交自己的位移值。**如果consumer崩溃或被关闭，它负责的分区就会被分配给其他consumer，因此一定要在其他consumer读取这些分区前就做好位移提交工作，否则会出现消息的重复消费**

consumer提交位移的主要机制是通过向所属的coordinator发送位移提交请求来实现的。**每个位移提交请求都会往__consumer_offsets对应分区上追加写入一条消息。消息的key是group.id、topic和分区的元组，而value就是位移值。如果consumer为同一个group的同一个topic分区提交了多次位移，那么__consumer_offsets对应的分区上就会有若干条key相同但value不同的消息，但显然只关心最新一次提交的那条消息。从某种程度来说，只有最新提交的位移值是有效的，其他消息包含的位移值其实都已经过期了。Kafka通过压实(compact)策略来处理这种消息使用模式**

##### 自动提交与手动提交

位移提交策略对于提供消息交付语义至关重要。默认情况下，consumer是自动提交位移的，自动提交间隔是5秒。**这就是说若不做特定的设置，consumer程序在后台自动提交位移。通过设置auto.commit.interval.ms参数可以控制自动提交的间隔**

自动位移提交的优势是降低了用户的开发成本使得用户不必亲自处理位移提交；劣势是用户不能细粒度地处理位移的提交，特别是在有较强的精确一次处理语义时。在这种情况下，用户可以使用手动位移提交

|          | 使用方法                                                     | 优势                   | 劣势                                     | 交付语义保证                                                 | 使用场景 |
| -------- | ------------------------------------------------------------ | ---------------------- | ---------------------------------------- | ------------------------------------------------------------ | -------- |
| 自动提交 | 默认不用配置或显式设置enable.auto.commit=ture                | 开发成本低，简单易用   | 无法实现精确控制，位移提交失败后不易处理 | 可能造成消息丢失，最多实现"最少一次"处理语义                 |          |
| 手动提交 | 设置enable.auto.commit=false;手动调用commitSync()或commitAsync()提交位移 | 可精确控制位移提交行为 | 额外的开发成本，须自行处理位移提交       | 易实现"最少一次"处理语义，依赖外部状态可实现"精确一次"处理语义 |          |

所谓的手动位移提交就是用户自行确定消息何时被真正处理完并可以提交位移。在一个典型的consumer应用场景中，用户需要对poll方法返回的消息集合中的消息执行业务级的处理。用户想要确保只有消息被真正处理完成后再提交位移。如果使用自动位移提交则无法保证这种时序性，因此在这种情况下必须使用手动提交位移。**设置使用手动提交位移非常简单，仅仅需要在构建KafkaConsumer时设置enable.auto.commit=false，然后调用commitSync或commitAsync方法即可**

```
consumer.commitSync()
//或
consumer.commitAsync()
```

手动提交位移API进一步细分为同步手动提交和异步手动提交，即commitSync和commitAsync方法。如果调用的是commitSync，用户程序会等待位移提交结束才执行下一条语句命令。相反地，若是调用commitAsync，则是一个异步非阻塞调用。consumer在后续poll调用时轮询该位移提交的结果。特别注意的是，**这里的异步提交位移不是指consumer使用单独的线程进行位移提交。实际上consumer依然会在用户主线程的poll方法中不断轮询这次异步提交的结果。只是该提交发起时此方法是不会阻塞的，因而被称为异步提交**

**当用户调用consumer.commit.Sync()或consumer.commitAsync()时，consumer会为所有它订阅的分区提交位移**。commitSync和commitAsync方法还有另外带参数的重载方法。**用户调用这个版本的方法时需要指定一个Map显式地告诉Kafka为哪些分区提交位移。实际使用过程中更加推荐这个版本，因为consumer只对它所拥有的分区做提交是更合理的行为，而且consumer通常都有更加细粒度化的位移提交策略**

```java
try {
  while (true) {
    ConsumerRecords<Integer, String> records = consumer.poll(5000);
    for (TopicPartition topicPartition : records.partitions()) {
      List<ConsumerRecord<Integer, String>> partitionRecords = records.records(topicPartition);
      for (ConsumerRecord<Integer, String> record : partitionRecords) {
        System.out.println(record.offset() + record.key() + record.value());
      }
      long lastOffset = partitionRecords.get(partitionRecords.size() - 1).offset();
      consumer.commitSync(Collections.singletonMap(topicPartition, new OffsetAndMetadata(lastOffset + 1)));
      //单例map
    }
  }
} finally {
  consumer.close();
}
```

**这里需要特别注意的是，提交的位移一定是consumer下一条待读取消息的位移**

#### 重平衡(rebalance)

**consumer group的rebalance本质上是一组协议，它规定了一个consumer group是如何达成一致来分配订阅topic的所有分区的**。假设某个组下有20个consumer实例，该组订阅了一个有着100个分区的topic。正常情况下，Kafka会为每个consumer平均分配5个分区。**这个分配过程就被称为rebalance**。 当consumer成功地执行rebalance后，组订阅topic的每个分区只会分配给组内的一个consumer实例。**新版本consumer使用了Kafka内置的一个全新的组协调协议( group coordination protocol)。对于每个组而言，Kafka的某个broker会被选举为组协调者(group coordinator) 。coordinator负责对组的状态进行管理，它的主要职责就是当新成员到达时促成组内所有成员达成新的分区分配方案，即coordinator负责对组执行rebalance操作**

##### rebalance触发条件

组rebalance触发的条件有以下3个

* 组成员发生变更，比如**新consumer加入组，或已有consumer主动离开组，再或是已有consumer崩溃时则触发rebalance**
* 组订阅topic数发生变更，比如使用基于正则表达式的订阅，当匹配正则表达式的新topic被创建时则会触发rebalance
* 组订阅topic的分区数发生变更，比如使用命令行脚本增加了订阅topic的分区数

真实应用场景中引发rebalance最常见的原因就是违背了第一个条件，特别是consumer崩溃的情况。这里的崩溃不一定就是指consumer进程“挂掉”或consumer进程所在的机器宕机。当consumer无法在指定的时间内完成消息的处理，那么coordinator就认为该consumer已经崩溃，从而引发新一轮rebalance。举一个真实的案例，一个Kafka线上环境，发现该环境中的consumer group频繁地进行rebalance，但组内所有consumer程序都未出现崩溃的情况，另外消费者组的订阅情况也从未发生过变更。最后定位了原因：该group下的consumer处理消息的逻辑过重，而且事件处理时间波动很大，非常不稳定，从而导致coordinator会经常性地认为某个consumer已经挂掉，引发rebalance。 而consumer程序中包含了错误重试的代码，使得落后过多的consumer会不断地申请重新加入组，最后表现coordinator 不停地对group执行rebalance，极大地降低了consumer端的吞吐量。鉴于目前一次rebalance操作的开销很大，生产环境中用户一定要结合自身业务特点仔细调优
consumer参数request.timeout.ms、max.poll.records 和max.pollinterval.ms，以避免不必要的rebalance出现

##### rebalance分区分配

**rebalance时group下所有的consumer都会协调在一起共同参与分区分配。Kafka新版本consumer默认提供了3种分配策略，分别是range策略、round-robin策略和sticky策略**

所谓的分配策略决定了订阅topic的每个分区会被分配给哪个consumer

* range策略主要是基于范围的思想。它将单个topic的所有分区**按照顺序排列**，然后把这些分区划分成固定大小的分区段并依次分配给每个consumer
* round-robin策略则会把所有topic的所有分区顺序摆开，然后轮询式地分配给各个consumer
* 最新发布的sticky策略有效地避免了上述两种策略完全无视历史分配方案的缺陷，采用了“有黏性”的策略对所有consumer实例进行分配，可以规避
  极端情况下的数据倾斜并且在两次rebalance间最大限度地维持了之前的分配方案

https://blog.csdn.net/qq_39907763/article/details/82697211
https://www.pianshen.com/article/8614298322/
https://blog.csdn.net/u013256816/article/details/81123625

**通常意义上认为，如果group下所有consumer实例的订阅是相同，那么使用round-robin会带来更公平的分配方案，否则使用range策略的效果更好**。此外，sticky策略在0.11.0.0版本才被引入，故目前使用的用户并不多。新版本consumer默认的分配策略是range。 用户根据consumer参数partition.assignment.strategy来进行设置。另外Kafka支持自定义的分配策略，用户可以创建自己的consumer分配器(assignor)

##### rebalance generation

某个consumer group可以执行任意次rebalance。为了更好地隔离每次rebalance上的数据，**新版本consumer设计了rebalance generation用于标识某次rebalance**。 generation这个词类似于JVM分代垃圾收集器中“分代”(严格来说，JVM GC使用的是generational)的概念。胡夕大佬把它翻译成“届”，表示rebalance之后的一届成员，**在consumer中它是一个整数，通常从0开始**。**Kafka引入consumer generation主要是为了保护consumer group的，特别是防止无效offset提交**。比如上届的consumer成员由于某些原因延迟提交了offset，但rebalance之后该group产生了新一届的group成员，而这次延迟的offset提交携带的是旧的generation信息，因此这次提交会被consumer group拒绝

很多Kafka用户在使用consumer时经常碰到的ILLEGAL GENERATION异常就是这个原因导致的。事实上，每个group进行rebalance之后，generation号都会加1，表示group进入了一个新的版本

##### rebalance协议

rebalance本质上是一组协议。 group与coordinator共同使用这组协议完成group的rebalance。最新版本Kafka中提供了下面5个协议来处理|rebalance相关事宜

* JoinGroup请求：consumer请求加入组
* SyncGroup请求：group leader把分配方案同步更新到组内所有成员中
* Heartbeat请求：consumer定期向coordinator汇报心跳表明自己依然存活
* LeaveGroup请求：consumer主动通知coordinator该consumer即将离组
* DescribeGroup请求：查看组的所有信息，包括成员信息、协议信息、分配方案以及订阅信息等。该请求类型主要供管理员使用。coordinator不使用该请求执行rebalance

**在rebalance过程中，coordinator主要处理consumer发过来的JoinGroup和SyncGroup请求。当consumer主动离组时会发送LeaveGroup请求给coordinator**

**在成功rebalance之后，组内所有consumer都需要定期地向coordinator发送Heartbeat请求。而每个consumer也是根据Heartbeat请求的响应中是否包含REBALANCE IN PROGRESS来判断当前group是否开启了新一轮rebalance**

##### rebalance流程

consumer group在执行rebalance之前必须首先确定coordinator所在的broker，并创建与该broker相互通信的Socket连接。确定coordinator的算法与确定offset被提交到__consumer_offsets目标分区的算法是相同的

* 计算Math.abs(groupID.hashCode) % offset.topic.num.partitions参数值(默认是50)，假设结果是10
* 寻找__consumer_offsets分区10的leader副本所在的broker，该broker即为这个group的coordinator

成功连接coordinator之后便可以执行rebalance操作。目前rebalance主要分为两步:加入组和同步更新分配方案

* 加入组：这一步中组内所有consumer(即group.id相同的所有consumer实例)向coordinator发送JoinGroup请求。当收集全JoinGroup请求后，coordinator从中选择一个consumer担任group的leader，并把所有成员信息以及它们的订阅信息发送给leader。特别需要注意的是，group的leader和coordinator不是一个概念。leader是某个consumer实例，coordinator通常是Kafka集群中的一个broker。 另外**leader而非coordinator负责为整个group的所有成员制定分配方案**
* 同步更新分配方案：**这步中leader开始制定分配方案，即根据前面提到的分配策略决定每个consumer都负责哪些topic的哪些分区。一旦分配完成，leader会把这个分配方案封装进SyncGroup请求并发送给coordinator。比较有意思的是，组内所有成员都会发送SyncGroup请求，不过只有leader发送的SyncGroup请求中包含了分配方案。coordinator接收到分配方案后把属于每个consumer的方案单独抽取出来作为SyncGroup请求的response返还给各自的consumer**

**consumer group分配方案是在consumer端执行的**。Kafka将这个权力下放给客户端主要是因为这样做可以有更好的灵活性。比如在这种机制下用户可以自行实现类似于Hadoop那样的机架感知(rack-aware)分配方案。同一个机架上的分区数据被分配给相同机架上的consumer，减少网络传输的开销。而且，即使以后分区策略发生了变更，也只需要重启consumer应用即可，不必重启Kafka服务器

##### rebalance监昕器

新版本consumer默认把位移提交到__consumer_offsets中。其实，Kafka也支持用户把位移提交到外部存储中，比如数据库中。若要实现这个功能，用户就
必须使用rebalance监听器。**使用rebalance监听器的前提是用户使用consumer group。如果使用的是独立consumer或是直接手动分配分区，那么rebalance监听器是无效的**



#### 解序列化

解序列化(deserializer)或称反序列化与序列化(serializer) 是互逆的操作。Kafka consumer从broker端获取消息的格式是字节数组，consumer需要把它还原回指定的对象类型，而这个对象类型通常都是与序列化对象类型一致的。Kafka默认提供了多达十几种的deserializer。但若涉及复杂的类型(比如Avro或其他序列化框架)，那么就需要用户自行定义deserializer

##### 默认解序列化器

consumer的序列化机制使用起来非常简单，只需要在构造consumer时同时指定参数key.deserializer和value.deserializer的值即可

```java
properties.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.IntegerDeserializer");
properties.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, "org.apache.kafka.common.serialization.StringDeserializer");
```

##### 自定义解序列化器

Kafka支持用户自定义消息的deserializer。 成功编写一个自定义的deserializer需要完成3件事情

* 定义或复用serializer的数据对象格式
* 创建自定义deserializer类，令其实现org.apache.kafka.common.serialization.Deserializer接口。在deserializer方法中实现deserialize逻辑
* 在构造KafkaConsumer的Properties对象中设置key.deserializer和(或)value.deserializer为上一步的实现类

```java
public class SerializerTest implements Deserializer<User> {

    @Override
    public void configure(Map<String, ?> configs, boolean isKey) {
        
    }

    @Override
    public User deserialize(String topic, byte[] data) {
        return null;
    }

    @Override
    public void close() {

    }
}
```

#### 多线程消费

**KafkaConsumer是非线程安全的。和KafkaProducer不同，后者是线程安全的，因此用户可以在多个线程中放心地使用同一个KafkaProducer实例，事实上这也是社区推荐的producer使用方法，因为通常它比每个线程维护一个KafkaProducer实例效率要高**

##### 每个线程维护一个KafkaConsumer

在这个方法中，创建多个线程来消费topic数据。每个线程都会创建专属于该线程的KafkaConsumer实例

##### 单KafkaConsumer实例+多worker线程

此方法与第一种方法的区别在于，将消息的获取与消息的处理解耦，把后者放入单独的工作者线程中，即所谓的worker线程中。同时在全局维护一个或若干个consumer实例执行消息获取任务

比如可以使用全局的KafkaConsumer实例执行消息获取，然后把获取到的消息集合交给线程池中的worker线程执行工作。之后worker线程完成处理后上报位移状态，由全局consumer提交位移

##### 两种方法对比

|                                       | 优点                                                         | 缺点                                                         |
| ------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 方法1 (每个线程维护专属KafkaConsumer) | 实现简单;速度较快，因为无线程间交互开销:方便位移管理;易于维护分区间的消息消费顺序 | Socket连接开销大: consumer 数受限于topic 分区数，扩展性差: broker端处理负载高(因为发往broker的请求数多);rebalance可能性增大 |
| 方法2 (全局consumert多worker线程)     | 消息获取与处理解耦:可独立扩展consumer数和worker数，伸缩性好  | 实现负载;难于维护分区内的消息顺序:处理链路变长，导致位移管理困难: worker线程异常可能导致消费数据丢失 |

#### 独立consumer

consumer group自动帮用户执行分区分配和rebalance。对于需要有多个consumer共同读取某个topic的需求来说，使用group是非常方便的。但有的时候用户依然有精确控制消费的需求，比如严格控制某个consumer固定地消费哪些分区

* 如果进程自己维护分区的状态，那么它就可以固定消费某些分区而不用担心消费状态丢失的问题
* 如果进程本身已经是高可用且能够自动重启恢复错误(比如使用YARN和Mesos等容器调度框架)，那么它就不需要让Kafka来帮它完成错误检测和状态恢复

以上两种情况中consumer group都是无用武之地的，取而代之的是被称为独立consumer(standalone consumer)的角色。standalone consumer间彼此独立工作互不干扰。任何一个consumer崩溃都不影响其他standalone consumer的工作

**使用standalone consumer的方法就是调用KafkaConsumer.assign方法**。assign方法接收一个分区列表，直接赋予该consumer访问这些分区的权力

```java
KafkaConsumer<Integer, String> consumer= new KafkaConsumer<>(properties);
consumer.subscribe(Arrays.asList(topicName));

List<TopicPartition> partitions = new ArrayList<>();
List<PartitionInfo> partitionInfos = consumer.partitionsFor("partitionTest");

for (PartitionInfo partitionInfo : partitionInfos) {
	partitions.add(new TopicPartition(partitionInfo.topic(), partitionInfo.partition()));
}

consumer.assign(partitions);
```

**如果发生多次assign调用，最后一次assign调用的分配生效，之前的都会被覆盖掉。还有一个值得注意的是，assign和subscribe一定不要混用，即不能在一个consumer应用中同时使用consumer group和独立consumer**

### 集群管理

#### broker管理

##### 启动broker

在生产环境中强烈推荐使用nohup ... &或加-daemon参数的方式启动Kafka集群

```shell
bin/kafka-server-start.sh -daemon <path>/server.properties
```

或

```shell
nohup bin/kafka-server-start.sh <path>/server.properties &
```

如果查阅Kafka启动脚本源码，会发现-daemon的作用就是以nohup...&的方式启动broker，因此两者的效果是一样的

启动broker之后，建议用户查看启动日志以确保broker启动成功。服务器日志通常保存在kafka安装目录的logs子目录下，名字是server.log。用户可查询该日志文件，如果发现诸如"[Kafka Server **],started(kafka.server.KafkaServer)"之类的输出项，则表示broker进程启动成功

##### 关闭broker

正确关闭broker的方式就是使用Kafka自带的kafka-server-stop.sh脚本。该脚本位于Kafka安装目录的bin子目录下

```shell
bin/kafka-server-stop.sh
```

**一定要注意，该脚本会搜寻当前机器中所有的Kafka broker进程，然后关闭它们。这就意味着，如果用户的机器上存在多个broker进程，该脚本会全部关闭它们。这个脚本当前并不支持以给定参数的方式单独关闭某个broker**

**不推荐用户直接使用kill -9方式“杀死”broker进程，因为这通常会造成些broker状态的不一致**

kafka-server-stop脚本有可能无法关闭broker，主要的原因在于该脚本是依靠操作系统命令(如ps ax和grep)来获取Kafka broker的进程号(PID)的，一旦用户的Kafka安装目录的路径过长，则有可能令该脚本失效从而无法正确获取broker的PID。如若碰到这种情况，可以采用下面的办法来关闭broker

* 如果机器上安装了JDK，可运行jps命令直接获取Kafka的PID，否则转到下一步
* 运行ps ax | grep -i 'kafka\\.Kafka' I grep java I grep -v grep I awk '{print $1}'命令自行寻找Kafka的PID
* 运行kill -s TERM $PID 关闭broker

实际上，以上3步就是kafka-server-stop脚本执行的逻辑

##### 设置JMX端口

Kafka提供了丰富的JMX指标用于实时监控集群运行的健康程度。不过若要使用它们，用户必须在**启动broker前**就首先设置JMX端口

```shell
export JMX_PORT=9997
bin/kafka-server-start.sh -daemon <path>/server.properties
```

##### 增加broker

由于Kafka集群的服务发现交由ZooKeeper来处理，因此向Kafka集群增加新的broker服务器非常容易。用户只需要**为新增broker设置一个唯一的broker.id，然后启动即可。Kafka集群能自动地发现新启动的broker并同步所有的元数据信息**，主要包括当前集群有哪些主题(topic)以及topic都有哪些分区等

唯一有缺憾的是，**新增的broker不会自动被分配任何已有的topic分区，因此用户必须手动执行分区重分配操作才能使它们为已有topic服务。当然，在
这些broker启动之后新创建的topic分区还是可能分配给这些broker的。用户需要仔细地对各个broker上的负载进行规划，避免出现负载极度不均匀的情况**

#### topic管理

![topic脚本](/Users/zhuyufeng/乐其/工作/leqee/笔记/Kafka/topic脚本.png)

##### 创建topic

严格来说，Kafka创建topic的途径当前总共有如下5种

* 通过执行kafkd-topics.sh命令行工具创建
* 通过显式发送CreateTopicsRequest请求创建topic
* 通过发送MetadataRequest请求且broker端设置了auto.create.topics.enable为true
* 通过向ZooKeeper的/brokers/topics路径下写入以topic名称命名的子节点
* 写Java/Scala程序直接调用TopicCommand的createTopic方法或调用AdminUtils的createTopic方法

第五种方法并没有显式地记录在官方文档上，并不推荐用户使用。第四种方法实际上也是不推荐的

官方社区推荐用户使用前两种方式来创建topic

```shell
bin/kafka-topics.sh --create --zookeeper localhost:2181 --partitions 6 --replication-factor 3 --topic test-topic --config delete.retention.ms=259200000
```

```shell
bin/kafka-topics.sh --create --zookeeper localhost:2181 --topic test-topic2 --replica-assignment 0:1,1:2,0:2,1:2
```

##### 删除topic

删除topic当前有如下3种方式

* 使用kafka-topics脚本
* 构造DeleteTopicsRequest请求：这种方式需要手动编写程序实现
* 直接向ZooKeeper的/admin/delete_topics下写入子节点：不推荐的方式。在实际场景中谨慎使用

经常有一些用户采用“暴力删除法”来移除topic数据，即手动删除topic底层的日志文件以及ZooKeeper中与topic相关的所有znode。事实上，并不推荐这种删除方式，除非上面的3种方式全部失效。毕竟这种方式只能保证物理文件被删除干净，但在集群broker机器的内存中(特别是controller所在的broker上)依然保存有已删除topic的信息

**kafka-topics脚本执行之后通常是立即返回，因此往往给用户一个错觉，仿佛topic已经被删除。但其实它只是在后台开启一个异步删除的任务，所以用户需要多等待一段时间才能观察到topic数据被完全删除**

**无论用户采用上面的哪种方法，一定要首先确保broker端参数delete.topic.enable被设置为true，否则Kafka是不会删除topic的。截止到1.0.0 版本之前，该参数的默认值依然是false，表明默认情况下Kafka集群是不允许删除topic的。因此如果使用1.0.0 之前的版本，一定不要忘记将其设置为true。社区于1.0.0 版本将该参数默认值调整为true，表明了topic删除功能已经相对完善，应该始终坚持使用kafka-topics命令来删除topic**

```shell
bin/kafka-topics.sh --delete --zookeeper localhost:2181 --topic test-topic
Topic test-topic is marked for deletion.
Note: This will have no impact if delete.topic.enable is not set to true.
```

该命令执行返回之后test-topic仅仅被标记为“待删除”状态，而且它还会“好心”地提醒用户不要忘记设置delete.topic.enable =true,否则该命令不会有任何效果

当前Kafka删除topic的逻辑是由controller在后台默默地完成的，用户无法感知进度也不能知晓删除是否成功。唯一的确认方法就是使用kafka-topics.sh --list命令去查询topic列表。若被删除topic不在列表中则表明删除成功

##### 查询topic列表

kafka topics脚本运行用户查询当前集群的topic列表

```shell
bin/kafka-topics.sh --zookeeper localhost:2181 --list
```

##### 查询topic详情

kafka-topics脚本还可以查询单个或所有topic的详情

```shell
bin/kafka-topics.sh --zookeeper localhost:2181 --describe --topic test-topic2
```

如果用户没有指定命令结尾处的指定topic，则表明查询集群上所有topic的详情

```shell
bin/kafka-topics.sh --zookeeper localhost:2181 --describe
```

##### 修改topic

topic被创建后，Kafka依然允许用户对topic的某些参数和设置进行修改

```shell
bin/kafka-topics.sh --alters --zookeeper localhost:2181 --partitions 10 --topic test-topic2
```

**当前Kafka不支持减少分区数**

用户可以使用kafka-configs脚本为已有topic设置topic级别的参数。kafka-topics.sh --alter虽然也可以实现这样的目的，但Kafka社区已经不推荐用户使用
--alter来设置

![config脚本1](/Users/zhuyufeng/乐其/工作/leqee/笔记/Kafka/config脚本1.png)

![config脚本2](/Users/zhuyufeng/乐其/工作/leqee/笔记/Kafka/config脚本2.png)

```shell
bin/kafka-configs.sh --zookeeper localhost:2181 --alter --entity-type topics --entity-name test-topic2 --add-config cleanup.policy-compact
```

```shell
bin/kafka-configs.sh --zookeeper localhost:2181 --describe --entity-type topics --entity-name test-topic2
```

##### 增加topic配置

截止到1.0.0版本，Kafka支持的topic级别的参数共有24个，完整的参数列表及其含义请参见官网http://kafka.apache.org/documentation/#topicconfigs中的说明

与broker端参数不同的是，**topic级别的参数可以动态修改而无须重启broker**

```shell
bin/kafka-configs.sh --zookeeper localhost:2181 --alter --entity-type topics --entity-name test --add-config preallocate = true,segment.bytes = 104857600
```

##### 查看topic配置

当前有两种方式可以查看topic配置，一种是使用kafka-topics脚本，另一种是使用kafka-configs脚本

```shell
bin/kafka-topics.sh --describe --zookeeper localhost:2181 --topic test
```

```shell
bin/kafka-configs.sh --describe --zookeeper localhost:2181 --entity-type topics --entity-name test
```

##### 删除topic配置

使用kafka-configs脚本删除topic配置

```shell
bin/kafka-configs.sh --zookeeper localhost:2181 --alter --entity-type topics --entity-name test --delete-config preallocate
```

#### consumer管理

##### 查询消费者组

生产环境对于消费者组(consumer group)的运行情况有着很强的监控需求。大多数用户选择使用第三方的监控框架来监控消费者组

Kafka Eagle

Kafka提供的用于查询消费者组的脚本是kafka-consumer-groups.sh

![group脚本](/Users/zhuyufeng/乐其/工作/leqee/笔记/Kafka/group脚本.png)

**--bootstrap-server和--zookeeper，两者不可同时指定**

```shell
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 -list
```

```shell
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --group test-group
```

##### 重设消费者组位移

0.11.0.0 版本丰富了kafka-consumer-groups脚本的功能，用户可以直接使用该脚本很方便地为已有的consumer-group重新设置位移，但前提是consumer-group不能处于运行状态，也就是说它必须是inactive的

总体来说，重设位移的流程由3步组成

第一步是确定消费者组下topic的作用域，当前支持3种作用域

* --all-topics：为消费者组下所有topic的所有分区调整位移
* --topc t1, --topic t2：为指定的若干个topic的所有分区调整位移
* --topc t1:0,1,2：为topic的指定分区调整位移

确定了topic作用域之后，第二步就是确定位移重设策略。当前支持如下8种设置规则

* --to-earliest：把位移调整到分区当前最早位移处
* --to-latest：把位移调整到分区当前最新位移处
* --to-current：把位移调整到分区当前位移处
* --to-offet <offset>：把位移调整到指定位移处
* --shift-by N:把位移调整到当前位移+N处。N可以是负值
* --to-datetime <datetime>：把位移调整到大于给定时间的最早位移处。datatime格式是yyy-MM-ddTHmms.xxx，比如2017-08-04T00:00:00.000
* --by-duration <duration>：把位移调整到距离当前时间指定间隔的位移处。duration格式是PnDTnHnMnS，比如PT0H5M0S
* --from-file <file>：从CSV文件中读取位移调整策略

最后一步是确定执行方案，当前支持如下3种方案

* 不加任何参数：只是打印位移调整方案，不实际执行
* --execute：执行真正的位移调整
* --export：把位移调整方案保存成CSV格式并输出到控制台，方便用户保存成CSV文件，供后续结--from file参数使用

```shell
# --to-earliest
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group test-group --reset-offsets --all-topics --to-earliest --execute
```

```shell
# --to-latest
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group test-group --reset-offsets --all-topics --to-latest --execute
```

```shell
# --to-offet <offset>
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group test-group --reset-offsets --all-topics --to-offet 500000 --execute
```

```shell
# --to-current
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group test-group --reset-offsets --all-topics --to-current --execute
```

```shell
# --shift-by N
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group test-group --reset-offsets --all-topics --shift-by 100000 --execute
```

```shell
# --to-datetime <datetime>
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group test-group --reset-offsets --all-topics --to-datetime 2017-08-04T14:30:00.000
```

```shell
# --by-duration <duration>
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --group test-group --reset-offsets --all-topics --by-duration PTOH3OM0S
```

##### 删除消费者组

Kafka自带的kafka-consumer-groups脚本便提供了这样的功能，帮助用户删除处于inactive状态的老版本消费者组信息。切记，**该命令只能删除老版本消费者组的元数据信息**

```shell
bin/kafka-consumer-groups.sh --zookeeper localhost:2181 --delete --group test-group3
```

事实上，新版本消费者组过期数据的移除完全不需要用户操作，Kafka会定期地移除过期消费者组的数据，而这对用户是完全透明的。如果用户查询Kafka官网上的broker端参数列表，就会发现一个名为offsets.retention.minutes的参数，默认值是1440分钟，即1天。该参数控制Kafka何时移除inactive消费者组位移的信息。**默认情况下，对于一个新版本的消费者组而言，即使它所有的成员都已经退出组，它的位移信息也不会马上被移除，Kafka会在最后一个成员退出组的1天之后删除该组的所有信息，因此不需要用户显式地手动删除。不过用户的确可以设置该参数来间接影响这个过程**

#### 分区管理

##### preferred leader选举

在一个Kafka集群中，broker服务器宕机或崩溃是不可避免的。一旦发生这种情况，该broker上的那些leader副本将变为不可用，因此就必然要求Kafka把这些分区的leader转移到其他的broker上。**即使崩溃broker重启回来，其上的副本也只能作为follower副本加入ISR中，不能再对外提供服务**

随着集群的不断运行，这种leader的不均衡现象开始出现，即集群中的一小部分broker上承载了大量的分区leader副本。为了校正这种情况，Kafka引入了首选副本preferred replica的概念

假设为一个分区分配了3个副本，它们分别是0、1、2。那么节点0就是该分区的preferred replica，并且通常情况下是不会发生变更的。选择节点0的原因仅仅是它是副本列表中的第一个副本

Kafka提供了两种方式帮助用户把指定分区的leader调整回它们的preferred replica。这个过程被称为preferred leader选举。第一种方式是使用Kafka自带的kafka-preferred-replica-election.sh脚本

首先构造json文件：

```shell
echo  '{"partitions" : [{"topic":"test-topic","partition": 0}, {"topic":"test-topic","partition": 1}]}' > preferred-leader-plan.json
```

```shell
bin/kafka-preferred-replica-election.sh --zookeeper localhost:2181 --path-to-json-file <path>/preferred-leader-plan.json
```

当然，可以不指定--path-to-json-file参数直接运行kafka-preferred-replica-election.sh脚本。这样做的效果就是Kafka对集群上所有topic的所有分区都执行了preferred leader选举。这种用法在实际的线上环境中一定要慎用，因为对所有分区进行leader的转移是一项成本很高的工作，对clients端程序必然有一定的影响

Kafka还提供了一个broker端参数auto.leader.rebalance.enable来帮助用户自动地执行此项操作。该参数默认值是true，表明每台broker启动后都会在后台自动地定期执行preferred leader选举。与之关联的还有两个broker端参数leader.imbalance.check.interval.seconds和leader.imbalance.per.broker.percentage。前者控制阶段性操作的时间间隔，当前默认值是300秒，即Kafka每5分钟就会尝试在后台运行一个preferred leader选举；后者用于确定需要执行preferred leader选举的目标分区，当前默认值是10，表示若broker上leader不均衡程度超过了10%，则Kafka需要为该broker上的分区执行preferred leader选举。**Kafka计算不均衡程度的逻辑实际上非常简单：该broker上的leader不是preferred replica的分区数/ broker上总的分区数**

##### 分区重分配

新增的broker是不会自动地分担已有topic的负载的，它只会对增加broker后新创建的topic生效。如果要让新增broker为已有的topic 服务，用户必须手动地调整已有topic的分区分布，将一部分分区搬移到新增broker上。这就是所谓的分区重分配操作(partition reassignment)。Kafka提供了分区重分配脚本工具kafka-reassign-partitions.sh

用户使用该工具时需要提供一组需要执行分区重分配的topic列表以及对应的一组broker。该脚本接到用户这些信息后会尝试制作一个重分配方案，它会力求保证均匀地分配给定topic的所有分区到目标broker上

首先要构造一个json文件，表明要执行分区重分配的topic列表

```shell
 cat topics-to-move.json 
{"topics":[{"topic":"fool"},{"topic":"foo2"}],"version":1}
```

现在执行kafka-reassign-partitions.sh脚本先产生一个分配方案

```shell
bin/kafka-reassign-partitions.sh --zookeeper localhost:2181 --topics-to-move-json-file topics-to-move.json --broker-list "5,6" --generate
```

此时分区重分配并没有真正执行，它仅告诉用户一个可能的方案而已。用户最好把当前的分布情况保存下来以备后续的rollback，同时把新的候选方案保存成另一个新的json文件expand-cluster-reassignment.json

```shell
bin/kafka-reassign-partitions.sh --zookeeper localhost:2181 --reassignment-json-file expand-cluster-reassignment.json --execute
```

执行真正的分区重分配

**用户也可以自行编写重分配方案**

**在实际生产环境中，用户一定要谨慎地发起分区重分配操作，因为分区在不同broker间进行数据迁移会极大地占用broker机器的带宽资源，从而显著地影响clients 端业务应用的性能。如果可能的话，尽量在非高峰业务时段执行重分配操作**

##### 增加副本因子

Kafka支持为已有topic的分区增加副本因子(replication factor)，具体的方法就是使用kafka-reassign-partitions.sh并且为topic分区增加额外的副本

首先创建json文件

```shell
echo '{"version":1, "partitions":[{"topic":"test","partition":0 ,"replicas":[0,1,2]}]}' > increase-replication-factor.json
```

然后执行重分配

```shell
bin/kafka-reassign-partitions.sh --zookeeper localhost:2181 --reassignment-json-file increase-replication-factor.json --execute
```

#### Kafka常见脚本工具

##### kafka-console-producer脚本

kafka-console-producer脚本从控制台读取标准输入，然后将其发送到指定的Kafka topic上

![kafka-console-producer](/Users/zhuyufeng/乐其/工作/leqee/笔记/Kafka/kafka-console-producer.png)

用户可以运行不加参数的kafka-console-producer脚本以获取完整的用法

```shell
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test --compression-codec lz4 --request-required-acks all --timeout 3000 --message-send-max-retries 10
```

需要特别注意的是，至少截止到1.0.0 版本的kafka-console-producer脚本不支持用户指定自定义序列化类，而是硬编码使用了ByteArraySerializer，因此用户不需要手工指定serializer，反正指定了也不会使用

如果用户要修改其他的定制属性，则需要使用--prducer-property或--producer.config来指定

```shell
bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test --producer-property connections.max.idle.ms=300000
```

用户也可以创建一个文本文件，写入cnnections.max.idle.ms=3000000，然后在调用脚本时指定--producer.config <文件路径>来设定。不过需要注意的是，--prducer-property的优先级要高于--producer.config

##### kafka-console-consumer脚本

kafka-console-consumer脚本运行在控制台上，主要从Kafka topic中读取消息并写入标准输出

![kafka-console-consumer](/Users/zhuyufeng/乐其/工作/leqee/笔记/Kafka/kafka-console-consumer.png)

用户可以运行不加参数的kafka-console-consumer脚本以获取完整的用法

```shell
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
```

kafka-console-consumer脚本会帮助用户自动生成一个group ID，因此Kafka认为运行kafka-console-consumer脚本的用户通常只是为了测试集群，已创建的consumer group也不会再被使用了，因此它会“好心”地替用户合成一个group ID

```shell
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning --consumer-property group.id=test-group
```

##### kafka-run-class脚本

所有Kafka脚本工具虽然实现了各自不同的功能，但底层都是使用kafka-run-class脚本来实现的。比如kafka-console-consumer.sh就是使用kafka-run-class.sh
kafka.tools.ConsoleConsumer <参数列表>实现的，而kafka-console-producer.sh则使用的是kafka-run-class.sh kafka.tools.ConsoleProducer <参数列表>

kafka-run-class.sh是一个通用的脚本，它允许用户直接指定一个可执行的Java类和一组可选的参数列表，从而调用该类实现的逻辑。之前谈到的所有脚本，仅仅是Kafka社区开发人员帮助用户做了一层封装。事实上，**还有很多其他有用的功能并没有被封装成单独的Shell脚本提供给用户，因此用户在使用这些功能时就需要显式地调用kafka-run-class脚本自行实现**

有些遗憾的是，目前Kafka官网文档对于这个现状并没有太多的说明。只有读过Kafka源码的人才可能清楚地说出目前到底有多少个这样的工具

##### 查看消息元数据

很多用户都有这样的需求，即查询特定topic的消息元数据。所谓的元数据信息包括消息的位移、创建时间戳、压缩类型、字节数等。Kafka确实提供了这样的功能，只是没有记录在官方文档上，这个工具就是kafka.tools.DumpLogSegments

```shell
bin/kafka-run-class.sh kafka.tools.DumpLogSegments --files ../datalogs/kafka_1/t1-0/00000000000000000000.log
```

如果topic启动了消息压缩，使得多条消息可能被封装进一条外层消息(wrapper message)中，而DumpLogSegments默认只显示wrapper message。DumpLogSegments工具为开启消息压缩的日志提供了--deep-iteration参数来深度遍历被压缩消息

```shell
bin/kafka-run-class.sh kafka.tools.DumpLogSegments --files ../datalogs/kafka_1/t2-0/00000000000000000000.log --deep-iteration
```

DumpLogSegments不只能够查询日志段文件，它还能够查询Kafka支持的索引文件类型

```shell
bin/kafka-run-class.sh kafka.tools.DumpLogSegments --files ../datalogs/kafka_1/t1-0/00000000000000000000.index
```

##### 获取topic当前消息数

Kafka提供了GetShellOffset类帮助用户实时计算特定topic总的消息数

```shell
bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic test --time -1
```

```shell
bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic test --time -2
```

--time-1命令表示要获取指定topic所有分区当前的最大位移；而--time-2表示获取当前最早位移。将两个命令的输出结果相减便可得到所有分区当前的消息总数。随着集群的不断运行，topic的数据可能会被移除一部分，因此--time-1的结果其实表示的是历史上该topic生产的最大消息数。如果用户要统计当前的消息总数就必须减去-time-2的结果。如果未发生任何消息删除操作，--time-2的结果全是0，表示最早位移都是0

##### 查询__consumer_offsets

Kafka提供kafka-simple-consumer-shell.sh脚本来查询__consumer_offsets

```shell
bin/kafka-simple-consumer-shell.sh --topic __consumer_offsets --partition 12 --broker-list localhost:9092 --formatter  "kafka.coordinator.group.GroupMetadataManager\$OffsetsMessageFormatter"
```

### Kafka Connect与Kafka Streams

Apache Kafka 0.9.0.0和0.10.0.0版本分别引入了两个全新的组件Kafka Connect和Kafka Streams。随着Apache Kafka被越来越多的用户使用，Kafka社区开发团队逐渐意识到大部分用户趋向于将Kafka作为消息队列来使用。事实上，这在当时就是最正确的用法。如果翻开Kafka0.9.0.0版本的官方文档，发现官网对Kafka的定位是分布式的、分区化的、带备份机制的的提交日志服务，从本质上说它就是一个分布式消息队列

既然是消息队列，必然存在上下游的处理子系统来处理消息。这就需要有一套系统负责处理消息在Kafka与其他系统间的搬进搬出，同时还额外需要一套系统来实现消息的业务处理逻辑。这两套系统就是常说的数据连接器(connector)和数据处理系统。在这两个领域内分别有很多著名的开源框架

在实际生产环境中，Kafka多与这些框架配合使用共同完成对业务数据的处理，因此Kafka社区开发人员开始思考：虽然Kafka本身承担着“消息中转站”的角色，但既然它已经保存了待处理的数据，为何不自已提供一套connector接口以及数据处理组件呢?这样用户便可只需要部署和维护一套系统就轻松实现上面三套系统才能实现的功能。这便是社区引入Kafka Connect和Kafka Streams的初衷。由此可以看出Kafka社区不仅要为用户提供一站式的业务消息处理能力，同时还有在消息处理特别是流式处理上一统江湖的“野心”。在这套解决方案中，Kafka Connect负责Kafka与外部系统的数据集成，Kafka Streams则是轻量级的流式处理组件

#### Kafka Connect

Kafka Connect是一个高伸缩性、高可靠性的数据集成工具，用于在Apache Kafka与其他系统间进行数据搬运以及执行ETL操作，比如Kafka Connect能够将文件系统中某些文件的内容全部灌入Kafka topic中或者是把KafKa topic中的消息导出到外部的数据库系统

Kafka Connect主要由source connector和sink connector组成。source connector负责把输入数据从外部系统中导入到Kafka中，而sink connector则负贵把输出数据导出到其他外部系统

目前其主要的设计特点如下

* 通用性：依托底层的Kafka核心系统封装了connector接口，方便开发、部署和管理
* 兼具分布式(distributed) 和单体式(standalone)两种模式：既可以以standalone单进程的方式运行，也可以扩展到多台机器成为分布式ETL系统
* REST接口：提供常见的REST API方便管理和操作，只适用于分布式模式
* 自动位移管理：connector自动管理位移，无须开发人员干预，降低开发成本
* 集成性：方便与流/批处理系统对接

一个connector系统是否好用的主要标志之一就是看source connector和sink connector的种类是否丰富。默认提供的connector越多，就能集成越多的外部系统，免去了用户自行开发的成本。不过令人遗憾的是，目前社区版本的Kafka只提供了与文件系统中文件的数据集成connector，即FileStreamSourceConnector和FileStreamSinkConnector，大部分与其他系统交互的connector在GitHub上都由是个人维护的，而非官方认证的

由于Kafka Connect还在不断地演进中，故需要时刻关注官网给出的最新动态http://kafka.apache.org/documentation/#connect

##### standalone Connect

在standalone模式下所有的操作都是在一个进程中完成的。这种模式非常适合运行在测试或功能验证环境，抑或是必须是单线程才能完成的场景(比如收集日志文件)。由于是单进程，standalone模式无法充分利用Kafka天然提供的负载均衡和高容错等特性

Kafka Connect standalone模式下通常有3类配置文件：connect配置文件，若干source connector配置文件和若干sink connector配置文件

Kafka己经在config目录下提供了3个文件的模板，直接使用模板井修改对应的宇段即可

```properties
#connect-standalone.properties
bootstrap.servers=localhost:9092 
key.converter=org.apache.kafka.connect.json.JsonConverter 
value.converter=org.apache.kafka.connect.json.JsonConverter 
key.converter.schemas.enable=true
value.converter.schemas.enable=true 
offset.storage.file.filename=/tmp/connect.offsets
```

```properties
#connect-file-source.properties
name=test-file-source 
connector.class=FileStreamSource 
tasks.max=1
file=foo.txt
topic=connect-file-test
```

```properties
#connect-file-sink.properties
name=test-file-sink 
connector.class=FileStreamSink 
tasks.max=l 
file=bar.txt 
topics=connect-file-test
```

```shell
bin/connect-standalone.sh config/connect-standalone.properties config/connect-file-source.properties config/connect-file-sink.properties
```

##### distributed Connect

distributed Connect天然地结合了Kafka提供的负载均衡和故障转移功能，能够自动地在多节点机器上平衡负载。用户可以增减机器来实现整体系统的高伸缩性。用户需要执行下列命令来启动distributed模式的Connect

```shell
bin/connect-distributed.sh config/connect-distributed.properties
```

**在distributed模式中不需要指定source和sink的配置文件**。**distributed模式中的connector只能通过REST API来创建和管理**

REST API可参考https://kafka.apache.org/documentation/#connect_rest

##### 开发connector

#### Kafka Streams

### Kafka 设计原理

