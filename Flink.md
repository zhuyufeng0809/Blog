### Flink分层API

* SQL
* Table API
* DataStream/DataSet API
* Stateful Stream Processing

### Flink架构

C/S架构

flink集群由两种类型进程组成

* JobManager
* TaskManager

Flink Client

客户端负责将一个Flink作业提交到Flink集群的JobManager中，具体将提交的Flink作业转换为JobGraph，并将其发送到Flink集群的JobManager中

* Flink命令行
* Scala Shell
* SQL Client
* Restful API
* Web UI

### Flink分布式执行模型

Flink程序本质是并行和分布式的

#### 并行数据流

在执行过程中，**一个流会有一个或者多个流分区**，**算子被称为一个任务（task），每个算子都有一个或者多个子任务（sub task），算子子任务彼此独立，在不同的线程中执行，并且可能在不同的机器或者容器中执行**

* 一个算子子任务的个数被称为该算子的并行度
* 一个流的并行度总是等于生成该流的算子的并行度
* 同一个Flink程序中不同算子可能具有不同的并行度

**数据流在两个算子质检可以以一对一的模式传输数据，也可以以重新分配的模式传输数据，具体是哪一种传输模式取决于算子的种类**

* 一对一模式：数据流维护着元素的分区和排序，意味着上游算子子任务看到的元素个数和顺序和下游算子子任务看到的元素个数和顺序相同
* 重新分配模式：重新分配模式的数据流将改变数据流的分区，每个算子的子任务根据选择的转换方式将数据发送给不同的下游算子子任务（比如KeyBy通过hash）

#### 任务和任务链

分布式计算环境中，**Flink会将具有依赖关系的多个算子的子任务链接成一个任务链，每个任务链由一个线程执行**。将多个算子的子任务链接为一个任务是Flink的一个优化：**这减少了线程与线程上下文切换的开销和缓冲的开销，并在减少延迟的同时提高了吞吐量（减少了序列化和反序列化，减少数据在缓冲区的交换）**

在默认情况下，Flink会**尽可能**链接多个算子的子任务形成一个任务链。同时，Flink在API层面允许开发者手动配置算子子任务的链接策略。Flink允许开发者再DataStream中调用任务链函数以此对任务链进行细粒度的控制，Flink提供了三种方式对任务链进行细粒度控制

```java
dataStream.startNewChain
dataStream.disableChaining
dataStream.slotSharingGroup("XXXX-name")
```

需要注意的是，**这些任务链函数只能在转换算子（数据源算子不算转换算子）之后使用，因为这些函数引用了前一个转换**

##### 默认链接

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        DataStream<Tuple2<String, Integer>> inputStream = env.addSource(new RichSourceFunction<Tuple2<String, Integer>>() {
            final int sleep = 30000;

            @Override
            public void run(SourceContext<Tuple2<String, Integer>> ctx) throws Exception {
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                String info = "source操作所属子任务名称:";
                Tuple2<String, Integer> tuple2 = new Tuple2<>("185XXX", 899);
                ctx.collect(tuple2);
                System.out.println(info + subtaskName + ",元素:" + tuple2);
                Thread.sleep(sleep);

                tuple2 = new Tuple2<>("155XXX", 1199);
                ctx.collect(tuple2);
                System.out.println(info + subtaskName + ",元素:" + tuple2);
                Thread.sleep(sleep);

                tuple2 = new Tuple2<>("138XXX", 19);
                ctx.collect(tuple2);
                System.out.println(info + subtaskName + ",元素:" + tuple2);
                Thread.sleep(sleep);
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel");
            }
        });

        DataStream<Tuple2<String, Integer>> filter = inputStream.filter(
                new RichFilterFunction<Tuple2<String, Integer>>() {
                    @Override
                    public boolean filter(Tuple2<String, Integer> value) {
                        System.out.println("filter操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                        return true;
                    }
                });

        DataStream<Tuple2<String, Integer>> mapOne = filter.map(new RichMapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>() {
            @Override
            public Tuple2<String, Integer> map(Tuple2<String, Integer> value) {
                System.out.println("map-one操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                return value;
            }
        });

        DataStream<Tuple2<String, Integer>> mapTwo = mapOne.map(new RichMapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>() {
            @Override
            public Tuple2<String, Integer> map(Tuple2<String, Integer> value) {
                System.out.println("map-two操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                return value;
            }
        });
        mapTwo.print();

        env.execute("chain");
    }
```

从打印信息可以看出，算子的子任务根据依赖关系相互链接为一个"Filter -> Map -> Map -> Sink: Print to Std. Out"的任务链，该任务链一共有3个子任务，同一个任务链中的子任务由同一个线程处理。数据源算子单独作为一个任务链"Custom Source"，该任务链只有一个子任务

打包部署到集群上运行，可以看到该作业有4个子任务，运行在3个任务槽上

##### 开启新链接

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        DataStream<Tuple2<String, Integer>> inputStream = env.addSource(new RichSourceFunction<Tuple2<String, Integer>>() {
            final int sleep = 6000;

            @Override
            public void run(SourceContext<Tuple2<String, Integer>> ctx) throws Exception {
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                String info = "source操作所属子任务名称:";
                while (true) {
                    Tuple2<String, Integer> tuple2 = new Tuple2<>("185XXX", 899);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);

                    tuple2 = new Tuple2<>("155XXX", 1199);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);

                    tuple2 = new Tuple2<>("138XXX", 19);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);
                }
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel");
            }
        });

        DataStream<Tuple2<String, Integer>> filter = inputStream.filter(
                new RichFilterFunction<Tuple2<String, Integer>>() {
                    @Override
                    public boolean filter(Tuple2<String, Integer> value) {
                        System.out.println("filter操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                        return true;
                    }
                });

        DataStream<Tuple2<String, Integer>> mapOne = filter.map(new RichMapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>() {
            @Override
            public Tuple2<String, Integer> map(Tuple2<String, Integer> value) {
                System.out.println("map-one操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                return value;
            }
        }).startNewChain();

        DataStream<Tuple2<String, Integer>> mapTwo = mapOne.map(new RichMapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>() {
            @Override
            public Tuple2<String, Integer> map(Tuple2<String, Integer> value) {
                System.out.println("map-two操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                return value;
            }
        });
        mapTwo.print();

        env.execute("chain");
    }
```

调用startNewChain()的算子，会启动一个新的任务链。该算子不会链接到前面的算子，但后面的算子可以链接到该算子

从打印信息可以看出，整个程序共有3个独立的任务链。数据源算子单独作为一个任务链"Custom Source"，该任务链只有一个子任务。Filter算子单独作为一个任务链，该任务链有3个子任务。两个Map算子和print算子链接为一个任务链，该任务链有3个子任务。任务链的分界以调用startNewChain()的算子为界

打包部署到集群上运行，可以看到该作业有7个子任务，运行在3个任务槽上

##### 禁用链接

###### 在算子上禁用链接

在算子上禁用链接，该算子不会被之前或之后的算子链接上

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        DataStream<Tuple2<String, Integer>> inputStream = env.addSource(new RichSourceFunction<Tuple2<String, Integer>>() {
            final int sleep = 6000;

            @Override
            public void run(SourceContext<Tuple2<String, Integer>> ctx) throws Exception {
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                String info = "source操作所属子任务名称:";
                while (true) {
                    Tuple2<String, Integer> tuple2 = new Tuple2<>("185XXX", 899);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);

                    tuple2 = new Tuple2<>("155XXX", 1199);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);

                    tuple2 = new Tuple2<>("138XXX", 19);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);
                }
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel");
            }
        });

        DataStream<Tuple2<String, Integer>> filter = inputStream.filter(
                new RichFilterFunction<Tuple2<String, Integer>>() {
                    @Override
                    public boolean filter(Tuple2<String, Integer> value) {
                        System.out.println("filter操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                        return true;
                    }
                });

        DataStream<Tuple2<String, Integer>> mapOne = filter.map(new RichMapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>() {
            @Override
            public Tuple2<String, Integer> map(Tuple2<String, Integer> value) {
                System.out.println("map-one操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                return value;
            }
        }).disableChaining();

        DataStream<Tuple2<String, Integer>> mapTwo = mapOne.map(new RichMapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>() {
            @Override
            public Tuple2<String, Integer> map(Tuple2<String, Integer> value) {
                System.out.println("map-two操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                return value;
            }
        });
        mapTwo.print();

        env.execute("disableChaining");
    }
```

从打印信息可以看出，整个程序共有4个独立的任务链。数据源算子单独作为一个任务链"Custom Source"，该任务链只有一个子任务。Filter算子单独作为一个任务链，该任务链有3个子任务。第一个Map算子单独作为一个任务链，该任务链有3个子任务。第二个Map算子和print算子链接为一个任务链，该任务链有3个子任务。任务链的分界以调用disableChaining()的算子为界

打包部署到集群上运行，可以看到该作业有10个子任务，运行在3个任务槽上

###### 全局禁用链接

调用StreamExecutionEnvironment的disableOperatorChaining()方法可以为整个程序关闭算子链接，出于性能考虑，一般不建议使用整个方法

```java
...
StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
env.disableOperatorChaining();
...
```

从打印信息可以看出，每个算子都单独作为一个任务链，相邻算子的子任务不会进行任何链接操作去形成任务链

打包部署到集群上运行，可以看到该作业有13个子任务，运行在3个任务槽上

#### 任务槽和资源

**Flink集群中每一个TaskManager都是一个独立JVM进程**，每个进程都有一定量的资源（内存、CPU、网络、磁盘）。**Flink程序的每个算子子任务就运行在其中的独立线程中**。为了控制一个TaskManager能够处理的子任务数量，在TaskManager中引入了任务槽的概念

每个任务槽都表示TaskManager的一个固定的资源子集，Flink将TaskManager的内存划分到多个任务槽中（每个子任务运行在一个任务槽中）。划分内存意味着在任务槽中运行的子任务不会相互竞争内存。任务槽并没有隔离CPU，目前只能隔离内存

任务槽是静态的概念，指的是TaskManager最多能同时并发执行的任务数量，可以在$FLINK_HOME/conf/flink-conf.xml文件中修改taskmanager.numberOfTaskSlots参数进行配置。算子的并行度是动态的概念，指的是在TaskManager中运行一个算子实际使用的任务槽数，可以在$FLINK_HOME/conf/flink-conf.xml文件中修改parallelism.default参数去配置Flink程序默认的并行度

#### 共享任务槽

**默认情况下，Flink允许子任务共享同一个任务槽，即使它们是不同算子的子任务，只要它们来自同一个Flink程序即可**

有了共享任务槽机制，开发者可以将程序的基本并行度提高，这大大提高了任务槽资源的利用率，同时确保繁重的子任务在TaskManager之间公平分配

共享任务槽主要有两个优点

* 开发者不需要计算提交到Flink集群的程序共有多少子任务，只需要知道该程序中算子最大并行度是多少即可，**最大并行度就是该程序需要Flink集群提供的可用任务槽数量**
* 共享任务槽可以提高资源利用率

一个好的默认任务槽数量是服务器CPU核心的数量，对于有超线程的服务器，则是两倍CPU核心的数量。Flink默认开启共享任务槽机制

除了Flink的默认任务槽共享组，Flink也允许开发者手动设置算子的任务槽共享组，**指定将具有相同任务槽共享组的算子放入到相同的任务槽，同时将没有任务槽共享组的算子保留在其他任务槽中。Flink默认的任务槽共享组的名称为"default"，在没有设置任务槽共享组的情况下，所有的算子都在该共享组下**

可以调用算子的slotSharingGroup()方法显示将算子放入指定的任务槽共享组

**在对算子指定任务槽共享组后，该算子后面的算子都位于该任务槽共享组下**

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        DataStream<Tuple2<String, Integer>> inputStream = env.addSource(new RichSourceFunction<Tuple2<String, Integer>>() {
            final int sleep = 6000;

            @Override
            public void run(SourceContext<Tuple2<String, Integer>> ctx) throws Exception {
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                String info = "source操作所属子任务名称:";
                while (true) {
                    Tuple2<String, Integer> tuple2 = new Tuple2<>("185XXX", 899);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);

                    tuple2 = new Tuple2<>("155XXX", 1199);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);

                    tuple2 = new Tuple2<>("138XXX", 19);
                    ctx.collect(tuple2);
                    System.out.println(info + subtaskName + ",元素:" + tuple2);
                    Thread.sleep(sleep);
                }
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel");
            }
        });

        DataStream<Tuple2<String, Integer>> filter = inputStream.filter(
                new RichFilterFunction<Tuple2<String, Integer>>() {
                    @Override
                    public boolean filter(Tuple2<String, Integer> value) {
                        System.out.println("filter操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                        return true;
                    }
                });

        DataStream<Tuple2<String, Integer>> mapOne = filter.map(new RichMapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>() {
            @Override
            public Tuple2<String, Integer> map(Tuple2<String, Integer> value) {
                System.out.println("map-one操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                return value;
            }
        }).slotSharingGroup("custom-name");

        DataStream<Tuple2<String, Integer>> mapTwo = mapOne.map(new RichMapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>() {
            @Override
            public Tuple2<String, Integer> map(Tuple2<String, Integer> value) {
                System.out.println("map-two操作所属子任务名称:" + getRuntimeContext().getTaskNameWithSubtasks() + ",元素:" + value);
                return value;
            }
        });
        mapTwo.print();

        env.execute("slotSharingGroup");
    }
```

要观察设置任务槽共享组的效果，必须将程序部署到Flink集群上。可以看到该作业有7个子任务，运行在6个任务槽上

### Flink on Yarn

#### 打包

通过maven-shade-plugin插件打包，点击Idea的maven侧边栏的package按钮，生成两个jar包，使用不带original前缀的jar包

#### Yarn集群中启动长期运行的Flink集群

##### 启动

1. 将hadoop的jar包copy至flink/lib目录下

```shell
cp /opt/hadoop/share/hadoop/common/*.jar /opt/flink/lib
cp /opt/hadoop/share/hadoop/common/lib/*.jar /opt/flink/lib
cp /opt/hadoop/share/hadoop/yarn/*.jar /opt/flink/lib
cp /opt/hadoop/share/hadoop/common/lib/*.jar /opt/flink/lib
```

2. 删除flink/lib目录下commons-cli-1.*.jar包和slf4j-log4j12-1.7.15.jar包

原因见https://blog.csdn.net/appleyuchi/article/details/106730381

3. 启动yarn-session.sh脚本

```shell
yarn-session.sh -d
```

##### 停止

通过yarn命令关闭Flink集群

```shell
yarn application -kill application_1622360195950_0001
```

##### 提交作业

```shell
flink run *****.jar
```

#### 在Yarn集群中运行Flink作业

这种方式每次提交Flink作业都会创建一个新的Flink集群，每个Flink作业的运行都相互独立，作业运行完成后，创建的Flink集群也会消失

```shell
flink run -m yarn-cluster *****.jar
```

### 开发环境搭建

#### 方法一

```shell
curl https://flink.apache.org/q/quickstart.sh | bash
```

然后在idea中导入

#### 方法二

1. idea新建maven工程

2. 选择从原型创建

3. 添加原型

   * archetypeGroupId：org.apache.flink

   * archetypeArtifactId：flink-quickstart-java

   * archetypeVersion：1.7.2

   * archetypeRepository：http://maven.aliyun.com/nexus/content/groups/public

4. 选择该原型，创建工程

5. 将pom文件中的dependency的scope标签内容换为compile

### Lambda与泛型

以lambda表达式的形式使用flink算子，如果算子的泛型中再嵌套泛型，会使flink无法推断出被嵌套的泛型类型。需要开发者在lambda表达式后再调用return方法来添加此算子的类型信息提示，且在lambda表达式前显示声明类型

```java
public class lambda {
    public static void main(String[] args) throws Exception {
        final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        DataStream<Tuple2<Integer, String>> dataStream = env.fromElements(Tuple2.of(1, "1"), Tuple2.of(2, "2"));
        
        DataStream<Tuple2<Integer, String>> transStream1 = dataStream.map(i -> i).returns(Types.TUPLE(
                Types.INT,Types.STRING
        ));
        DataStream<Tuple2<Integer, String>> transStream2 = transStream1.map(i -> i).returns(Types.TUPLE(
                Types.INT,Types.STRING
        ));
        
        transStream2.print();
        
        env.execute();
    }
}
```

### DataStream

#### WordCount举例

```java
public class WordCount {
    public static final String[] WORDS = new String[]{
            "com.intsmaze.flink.streaming.window.helloword.WordCountTemplate",
            "com.intsmaze.flink.streaming.window.helloword.WordCountTemplate",
            "com.intsmaze.flink.streaming.window.helloword.WordCountTemplate",
            "com.intsmaze.flink.streaming.window.helloword.WordCountTemplate",
    };

    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        DataStream<String> text = env.fromElements(WORDS);

        DataStream<Tuple2<String, Integer>> counts =
                text.flatMap((FlatMapFunction<String, Tuple2<String, Integer>>) (value, out) -> {
                    String[] tokens = value.toLowerCase().split("\\.");
                    System.out.println("mark" + Arrays.toString(tokens));
                    Arrays.stream(tokens).filter(token -> token.length() > 0).
                            map(token -> new Tuple2<>(token, 1)).forEach(out::collect);
                }).returns(Types.TUPLE(Types.STRING, Types.INT))
                        .keyBy("f0")
                        .sum(1);

        counts.print("hello dataStream");

        env.execute();
    }

}
```

因为数据流是无限的，所以流式处理的结果是不断更新的：对单词的统计是一个不断更新先前计算结果的过程

```java
hello dataStream:7> (flink,1)
hello dataStream:4> (helloword,1)
hello dataStream:7> (flink,2)
hello dataStream:7> (flink,3)
hello dataStream:5> (wordcounttemplate,1)
hello dataStream:4> (helloword,2)
hello dataStream:5> (wordcounttemplate,2)
hello dataStream:2> (intsmaze,1)
hello dataStream:5> (wordcounttemplate,3)
hello dataStream:2> (streaming,1)
hello dataStream:2> (intsmaze,2)
hello dataStream:2> (streaming,2)
hello dataStream:2> (intsmaze,3)
hello dataStream:2> (streaming,3)
hello dataStream:3> (window,1)
hello dataStream:1> (com,1)
hello dataStream:1> (com,2)
hello dataStream:3> (window,2)
hello dataStream:4> (helloword,3)
hello dataStream:3> (window,3)
hello dataStream:1> (com,3)
hello dataStream:4> (helloword,4)
hello dataStream:3> (window,4)
hello dataStream:5> (wordcounttemplate,4)
hello dataStream:7> (flink,4)
hello dataStream:2> (intsmaze,4)
hello dataStream:2> (streaming,4)
hello dataStream:1> (com,4)
```

#### Source

##### 文件

```java
	public <OUT> DataStreamSource<OUT> readFile(FileInputFormat<OUT> inputFormat,
												String filePath,
												FileProcessingMode watchType,
												long interval,
												TypeInformation<OUT> typeInformation)
```

该方法是readFile方法的通用方法，其他readFile的重载方法内部都调用了该方法。该方法提供了最丰富的的语义去满足开发者的各种需求

参数解释：

* FileProcessingMode（监视策略模式）：目前有两种枚举值。PROCESS_ONCE扫描一次路径就退出监视；PROCESS_CONTINUOUSLY会监视路径并对新数据作出反应，当文件被修改时，其内容将被完全**重新处理**
* TypeInformation：将读取到的数据转换为指定类型。默认值为该抽象类类型的实现类BasicTypeInfo的STRING_TYPE_INFO
* FileInputFormat：读取文件的格式。内置了几种该抽象类类型的实现类

```java
public class Source {

    static final String filePath = "/Users/zhuyufeng/IdeaProjects/LearnFlink/src/main/resources/TextFileSource.txt";

    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        TextInputFormat textInputFormat = new TextInputFormat(new Path(filePath));

        DataStream<String> dataStream = env.readFile(textInputFormat,
                filePath,
                FileProcessingMode.PROCESS_CONTINUOUSLY,
                3000,
                BasicTypeInfo.STRING_TYPE_INFO
                );

        dataStream.print();

        env.execute("fileSource DataStream");
    }
}
```

##### socket

```java
public DataStreamSource<String> socketTextStream(String hostname, int port, String delimiter, long maxRetry)
```

该方法是socketTextStream方法的通用方法，其他socketTextStream的重载方法内部都调用了该方法。该方法提供了最丰富的的语义去满足开发者的各种需求

参数解释：

* hostname：主机名
* port：端口
* delimiter：分隔符
* maxRetry：等待socket暂时关闭的最大重试间隔（以秒为单位）。0为立即终止，负值为永久重试

##### 集合

基于Java常规集合创建数据源仅为了方便本地测试，实际生产环境不会使用该方式

```java
public <OUT> DataStreamSource<OUT> fromCollection(Collection<OUT> data)
//基于java.util.Collection创建数据流
public final <OUT> DataStreamSource<OUT> fromElements(OUT... data)
//基于给定对象序列创建数据流
public DataStreamSource<Long> generateSequence(long from, long to)
//基于给定区间生成序列创建数据流
```

##### 自定义

调用StreamExecutionEnvironment的addSource方法可以添加新的数据源，Flink提供了一批实现好的连接器以支持对应的数据源，同时开发者也可以实现自定义的数据源算子去读取指定系统的数据

* SourceFunction接口

  SourceFunction是Flink所有数据源算子实现的基本接口。**SourceFunction算子的并行度只能为1，大于1将会报错**

  ```java
  void run(SourceContext<T> ctx) throws Exception;
  void cancel();
  interface SourceContext<T>{...}
  ```

  run方法用来生成元素，使用参数SourceContext发送元素。cancel在取消数据源算子时调用。SourceContext接口是数据源算子用来发送元素的接口，可以根据需要选择是否发出水印

  ```java
      public static void main(String[] args) throws Exception {
  
          StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
  
          env.setParallelism(2);
          DataStream<Long> inputStream = env.addSource(new SourceFunction<Long>() {
              private static final long serialVersionUID = 1L;
  
              private volatile boolean isRunning = true;
              private long counter = 0;
  
              @Override
              public void run(SourceContext<Long> ctx) throws Exception {
                  while (isRunning) {
                      ctx.collect(counter);
                      System.out.println("send data :" + counter);
                      counter++;
                      long sleepTime = 100;
                      Thread.sleep(sleepTime);
                  }
              }
  
              @Override
              public void cancel() {
                  isRunning = true;
              }
          });
  
          DataStream<Long> inputStream1 = inputStream
                  .map((Long values) ->
                      values + System.currentTimeMillis());
          inputStream1.print();
  
          env.execute("Intsmaze Custom Source");
      }
  ```

* ParallelSourceFunction接口

  与SourceFunction接口不同的是，实现ParallelSourceFunction接口的数据源算子具有并行执行特性，运行时将具有并行实例，数量与并行度一致

  该接口仅仅继承了SourceFunction接口，没有添加任何额外的方法，仅利用多态特性作为标记，以标识该数据源算子可以并行执行

  **如果仅仅实现了ParallelSourceFunction接口，会出现重复发送数据的情况，所以实际生产中往往继承RichParallelSourceFunction抽象类来实现并行数据源算子。运行时可以访问上下文信息，防止数据重复发送**

  ```java
      public static void main(String[] args) throws Exception {
          StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
  
          env.setParallelism(2);
  
          DataStream<Tuple2<String, Long>> streamSource = env
                  .addSource(new RichParallelSourceFunction<Tuple2<String, Long>>() {
                      private long count = 1L;
  
                      private boolean isRunning = true;
  
                      private String sourceFlag;
  
                      @Override
                      public void run(SourceContext<Tuple2<String, Long>> ctx) throws Exception {
  
                          while (isRunning) {
                              count++;
                              if ("DB".equals(sourceFlag)) {
                                  ctx.collect(new Tuple2<>("DB", count));
                              } else if ("MQ".equals(sourceFlag)) {
                                  ctx.collect(new Tuple2<>("MQ", count));
                              }
                              Thread.sleep(1000);
  
                          }
                      }
  
                      @Override
                      public void cancel() {
                          isRunning = false;
                      }
  
                      @Override
                      public void open(Configuration parameters) throws Exception {
                          int parallelSubtasks = getRuntimeContext().getNumberOfParallelSubtasks();
                          System.out.println("当前任务的并行度为:" + parallelSubtasks);
  
                          int indexOfThisSubtask = getRuntimeContext().getIndexOfThisSubtask();
                          if (indexOfThisSubtask == 0) {
                              sourceFlag = "DB";
                          } else if (indexOfThisSubtask == 1) {
                              sourceFlag = "MQ";
                          }
                          //super.open(parameters);
  
                      }
  
                      @Override
                      public void close() throws Exception {
                          //super.close();
                      }
                  });
  
          streamSource.print();
  
          env.execute("RichParalleSourceTemplate");
      }
  ```

* 开启检查点的数据源算子

  可以在自定义数据源算子时实现CheckpointedFunction接口或者ListCheckpointed接口启动检查点机制。将数据的offset保存在数据源算子的内部状态中，通过定期执行检查点操作进行持久化存储以保证数据源算子在失败恢复后仍具有一致性

  需要注意的是，实现CheckpointedFunction接口或者ListCheckpointed接口的数据源算子**必须确保不会同时执行状态的检查点操作、更新内部状态和发送元素**。为此，FLink提供了检查点锁对象来保证<更新内部状态和发送元素>之前锁定检查点锁

  ```java
      private abstract static class StateSource<OUT> extends RichParallelSourceFunction<Long>
              implements ListCheckpointed<Long> {}
  
      public static void main(String[] args) throws Exception {
  
          StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
  
          env.enableCheckpointing(10000);
          String url = "file:///Users/zhuyufeng/IdeaProjects/LearnFlink/src/main/resources";
          StateBackend stateBackend = new RocksDBStateBackend(url, false);
          env.setStateBackend(stateBackend);
          env.setRestartStrategy(RestartStrategies.failureRateRestart(
                  3,
                  Time.of(5, TimeUnit.MINUTES),
                  Time.of(10, TimeUnit.SECONDS)
          ));
          env.setParallelism(2);
          DataStream<Long> inputStream = env
                  .addSource(new StateSource<Long>() {
                      private List<Long> checkPointedCount = new ArrayList<>();
  
                      @Override
                      public List<Long> snapshotState(long checkpointId, long timestamp) throws Exception {
                          return checkPointedCount;
                      }
  
                      @Override
                      public void restoreState(List<Long> state) throws Exception {
                          checkPointedCount = state;
                      }
  
                      @Override
                      public void run(SourceContext<Long> ctx) throws InterruptedException {
                          while (true) {
                              synchronized (ctx.getCheckpointLock()) {
                                  long offset;
                                  if (checkPointedCount.size() == 0) {
                                      offset = 0L;
                                  } else {
                                      offset = checkPointedCount.get(0);
                                      checkPointedCount.remove(0);
                                  }
                                  ctx.collect(offset);
                                  offset+=1;
                                  checkPointedCount.add(0, offset);
  
                                  if (offset == 10) {
                                      int i = 1 / 0;
                                  }
                              }
  
                              Thread.sleep(1000);
                          }
                      }
  
                      @Override
                      public void cancel() {
  
                      }
                  }).setParallelism(1);
  
          inputStream.print();
  
          env.execute("StateSourceTemplate");
      }
  ```

#### Sink

##### 文件

```java
	public <X extends Tuple> DataStreamSink<T> writeAsCsv(
			String path,
			WriteMode writeMode,
			String rowDelimiter,
			String fieldDelimiter)
	
	public DataStreamSink<T> writeAsText(String path, WriteMode writeMode)
```

参数解释：

* WriteMode：目前有两种枚举值。NO_OVERWRITE仅在文件不存在时创建指定文件，不覆盖现有文件和目录。如果指定路径文件存在，会报错；OVERWRITE无论指定路径上是否存在文件或者目录，都将创建新的目标文件，现有文件或者目录在创建之前会自动删除
* rowDelimiter：指定行分隔符
* fieldDelimiter：指定字段分隔符

Flink内置了几种输出到文件的格式，都继承自FileOutputFormat类，writeAsCsv和writeAsText方法是对CsvOutputFormat和TextOutputFormat类的封装

##### 标准输出流

```java
public DataStreamSink<T> print()
public DataStreamSink<T> print(String sinkIdentifier)

public DataStreamSink<T> printToErr()
public DataStreamSink<T> printToErr(String sinkIdentifier)
```

```java
public class Sink {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        //env.setParallelism(1);

        DataStream<Integer> dataStream = env.fromElements(1,2,3);

        dataStream.print("mark");

        env.execute("stdOut DataStream");
    }
}
```

```java
mark:4> 3
mark:2> 1
mark:3> 2
```

如果sink任务的并行度大于1，则输出时指定的固定前缀还会与生成输出的任务的标识符一起作为前缀

##### socket

```java
public DataStreamSink<T> writeToSocket(String hostName, int port, SerializationSchema<T> schema)
```

##### 自定义

调用StreamExecutionEnvironment的addSink方法可以添加新的sink

* SinkFunction接口

  SinkFunction接口是Flink所有sink算子实现的基本接口。每当上游算子向下游sink算子发送一个元素，sink算子的invoke方法就会被调用一次

  ```java
  void invoke(IN value, Context context) throws Exception
  ```

  参数value为sink算子接收的元素。参数context为接收元素的上下文信息

* RichSinkFunction抽象类

  如果sink算子需要实现连接数据库等场景，使用SinkFunction接口在invoke方法中创建数据库链接等申请资源操作，是十分浪费资源的（每接收一条，申请一次资源）。这种情况下，可以使用RichSinkFunction抽象类，在提供的open和close方法中申请和释放资源

  ```http
  https://github.com/intsmaze/flink-book/blob/master/flink-streaming/src/main/java/com/intsmaze/flink/streaming/connector/sink/CustomSinkTemplate.java
  ```

#### Connector

Flink内置了一些基本的数据源算子（文件、socket、集合）和sink算子（文件、输出流、socket），无需添加任何maven依赖。除此之外，FLink还提供了与各种第三方系统（DB、分布式存储、消息队列等）交互的connector，要使用这些connector需要安装额外的第三方组件，在pom.xml文件中添加对应的maven依赖

##### source connector和sink connector的容错保证

##### Flink Kafka Connector

Flink提供了特定的Kafka Connector实现对Kafka服务中指定主题下消息的读取和写入。**同时FLink的Kafka Consumer与Flink的检查点机制进行了集成，以提供Exactly Once语义。为了实现这一语义，FLink并不完全依赖Kafka默认的消费者组的offset跟踪机制，而是在Flink内部跟踪和检查这些offset**

从Flink 1.7开始，提供了一个新的通用Kafka Connector，它不跟踪特定的Kafka主版本，而是在Flink发布时跟踪Kafka的最新版本

**如果Kafka是1.0.0或更新的版本，那么建议使用新的通用Kafka Connector。如果使用Kafka的旧版本（0.11及以前），则应该使用版本对应的Connector**

需要注意的是，**从Flink 1.7开始，通用Kafka Connector被视为Beta状态，并且可能不如0.11版本那么稳定，如果在使用中出现问题，可以尝试使用flink-connector-kafka-0.11_2.11，该版本的Connector与从0.11版本开始的所有版本兼容**

##### Flink Kafka Consumer

##### Flink Kafka Producer

#### 算子

##### Map

场景：一对一映射

```java
public class Operator {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        DataStream<Long> streamSource = env.generateSequence(1, 5);

        DataStream<Tuple2<Long, Integer>> mapStream = streamSource
                .map(values -> new Tuple2<>(values * 100, values.hashCode()))
                .returns(Types.TUPLE(Types.LONG, Types.INT));
        mapStream.print("输出结果");
        env.execute("MapTemplate");
    }
}
```

##### FlatMap

场景：一对n映射。n可能为0、1或多个元素。典型的应用场景是拆分不需要的列表或数组

```java
public class Operator {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        DataStream<Tuple2<String, Integer>> streamSource = env.fromElements(
                new Tuple2<>("liu yang", 1),
                new Tuple2<>("my blog is intsmaze", 2),
                new Tuple2<>("hello flink", 2));
        
        DataStream<Tuple1<String>> resultStream = streamSource
                .flatMap((FlatMapFunction<Tuple2<String, Integer> , Tuple1<String>>) (value , out) -> {
                    if ("liu yang".equals(value.f0)) {
                        //返回0个元素
                    } else if (value.f0.contains("intsmaze")) {
                        //返回n个元素
                        Arrays.stream(value.f0.split(" ")).map(word -> Tuple1.of("Split intsmaze：" + word)).forEach(out::collect);
                    } else {
                        //返回1个元素
                        out.collect(Tuple1.of("Not included intsmaze：" + value.f0));
                    }
                })
                .returns(Types.TUPLE(Types.STRING));
        
        resultStream.print("输出结果");

        env.execute("FlatMapTemplate");
    }
}
```

##### Filter

场景：对输入的元素进行判断来决定保留该元素还是丢弃该元素，返回true保留，返回false丢弃

```java
public class Operator {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        DataStream<Long> streamSource = env.generateSequence(1, 5);
        DataStream<Long> filterStream = streamSource.filter(value -> value != 2L && value != 4L);
        filterStream.print("输出结果");
        env.execute("Filter Template");
    }
}
```

##### KeyBy

场景：将数据流分成不相交的流分区，所有具有相同key的元素都被分配到相同的流分区

Flink的数据模型不要求数据集合中的元素一定要基于键值对，因此不需要将数据集合中的元素类型封装成key-value形式

Flink提供了三种方式来指定元素的哪一个字段作为key

* 使用索引定义键：对于元组类型的数据流，可以通过定义索引的方式指定键

```java
public class Operator {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(10);
        List<Tuple2<Integer, Integer>> list = new ArrayList<Tuple2<Integer, Integer>>();
        list.add(new Tuple2<>(1, 11));
        list.add(new Tuple2<>(1, 22));
        list.add(new Tuple2<>(3, 33));
        list.add(new Tuple2<>(5, 55));

        DataStream<Tuple2<Integer, Integer>> dataStream = env.fromCollection(list);

        KeyedStream<Tuple2<Integer, Integer>, Tuple> keyedStream = dataStream.keyBy(0);

        keyedStream.print("输出结果");

        env.execute("KeyByTemplate");
    }
}
```

* 使用字段表达式定义键：对于指定元组中嵌套的元组的键或Bean类中某个字段为键，索引的方式就无法实现。字段表达式可以很容易的选择（嵌套）复合类型中的字段

```java
public class Operator {
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(10);
        List<Tuple2<Integer, Integer>> list = new ArrayList<Tuple2<Integer, Integer>>();
        list.add(new Tuple2<>(1, 11));
        list.add(new Tuple2<>(1, 22));
        list.add(new Tuple2<>(3, 33));
        list.add(new Tuple2<>(5, 55));

        DataStream<Tuple2<Integer, Integer>> dataStream = env.fromCollection(list);

        KeyedStream<Tuple2<Integer, Integer>, Tuple> keyedStream = dataStream.keyBy("f0");

        keyedStream.print("输出结果");

        env.execute("KeyByTemplate");
    }
}
```

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        List<Person> list = new ArrayList<>();
        list.add(new Person("张三", 20));
        list.add(new Person("张三", 28));
        list.add(new Person("李四", 20));

        DataStream<Person> dataStream = env
                .fromCollection(list)
                .keyBy("age");
        dataStream.print();
        env.execute("testKeyWithPOJO");
    }

		public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        List<Tuple2<Person, Integer>> list = new ArrayList<Tuple2<Person, Integer>>();
        list.add(new Tuple2<>(new Person("张三", 20), 1));
        list.add(new Tuple2<>(new Person("张三", 28), 2));
        list.add(new Tuple2<>(new Person("李四", 20), 33));

        DataStream<Tuple2<Person, Integer>> dataStream = env
                .fromCollection(list)
                .keyBy("f0.age");
        dataStream.print();
        env.execute("testKeyWithPOJO");
    }

    public static class Person {

        private String name;
        private int age;

        public Person() {
        }

        public Person(String name, int age) {
            this.name = name;
            this.age = age;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public int getAge() {
            return age;
        }

        public void setAge(int age) {
            this.age = age;
        }

        @Override
        public String toString() {
            return "Person{" +
                    "name='" + name + '\'' +
                    ", age=" + age +
                    '}';
        }

    }
```

* 使用键选择器函数定义键：键选择器函数接收单个元素作为输入，并返回元素的键

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        List<Person> list = new ArrayList<>();
        list.add(new Person("张三", 20));
        list.add(new Person("张三", 28));
        list.add(new Person("李四", 20));

        DataStream<Person> dataStream = env
                .fromCollection(list)
                .keyBy(element -> element.name);
        dataStream.print();
        env.execute("testKeyWithPOJO");
    }
```

##### Reduce

 场景：将KeyStream中具有相同key的元素合并为单个值，**并且总是将两个元素合并为一个元素，具体为将上一个合并过的值和当前输入的元素结合，产生新的值并发出，直到仅剩一个值为止**

```java
   
public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        List<Trade> list = new ArrayList<>();
        list.add(new Trade("123XXXXX", 899, "2018-06"));
        list.add(new Trade("123XXXXX", 699, "2018-06"));
        list.add(new Trade("188XXXXX", 88, "2018-07"));
        list.add(new Trade("188XXXXX", 69, "2018-07"));
        list.add(new Trade("158XXXXX", 100, "2018-06"));
        list.add(new Trade("158XXXXX", 1000, "2018-06"));

        DataStream<Trade> dataSource = env.fromCollection(list);

        DataStream<Trade> resultStream = dataSource
                .keyBy("cardNum")
                .reduce((value1, value2) -> {
                    String theadName = Thread.currentThread().getName();
                    String info = "theadName:" + theadName;
                    System.out.println(info);W
                    return new Trade(value1.getCardNum(), value1.getTrade() + value2.getTrade(), "----");
                });
        resultStream.print("输出结果");
        env.execute("Reduce Template");
    }

public static class Trade {

        private String cardNum;

        private int trade;

        private String time;

        public Trade() {
        }

        public Trade(String cardNum, int trade, String time) {
            super();
            this.cardNum = cardNum;
            this.trade = trade;
            this.time = time;
        }

        public String getCardNum() {
            return cardNum;
        }

        public void setCardNum(String cardNum) {
            this.cardNum = cardNum;
        }

        public int getTrade() {
            return trade;
        }

        public void setTrade(int trade) {
            this.trade = trade;
        }

        public String getTime() {
            return time;
        }

        public void setTime(String time) {
            this.time = time;
        }

        @Override
        public String toString() {
            return "Trade [cardNum=" + cardNum + ", trade=" + trade + ", time="
                    + time + "]";
        }

    }
```

从标准输出流中可以发现，同一个分组下第一个元素进入算子时，由于只有一个元素，无法合并，所以会将该元素保存在算子中，同时直接发给下游算子。当同一个分组的第二个元素进入算子时，会执行合并操作，然后将合并的结果保存在算子中，同时发给下游算子

##### Aggregations

场景：Aggregations提供了一系列内置的聚合方法，reduce是这些聚合方法的通用方法

Flink提供两种方式对指定字段进行聚合

* 对于Bean类类型可以指定字段名称，同样可以指定嵌套的字段
* 对于元组类型可以指定索引

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        List<Trade> list = new ArrayList<Trade>();
        list.add(new Trade("188XXX", 30, "2018-07"));
        list.add(new Trade("188XXX", 20, "2018-11"));
        list.add(new Trade("158XXX", 1, "2018-07"));
        list.add(new Trade("158XXX", 2, "2018-06"));
        DataStream<Trade> streamSource = env.fromCollection(list);

        KeyedStream<Trade, Tuple> keyedStream = streamSource.keyBy("cardNum");

        keyedStream.sum("trade").print("sum");

        keyedStream.min("trade").print("min");

        keyedStream.maxBy("trade").print("minBy");

        env.execute("Aggregations Template");

    }
```

maxBy取分组中指定字段具有最小值的元素

##### Split和Select

场景：Split算子将元素发送到指定命名的输出中，**该算子将被弃用，请使用side ouput替代**。Select算子从切分的数据流中获取指定的数据流，Select算子的参数就是Split算子中定义的输出名称

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        List<Trade> list = new ArrayList<Trade>();
        list.add(new Trade("185XXX", 899, "周一"));
        list.add(new Trade("155XXX", 1199, "周二"));
        list.add(new Trade("138XXX", 19, "周三"));
        DataStream<Trade> dataStream = env.fromCollection(list);

        SplitStream<Trade> splitStream = dataStream.split(value -> {
            List<String> output = new ArrayList<>();
            if (value.getTrade() < 100) {
                output.add("Small amount");
                output.add("Small amount backup");
            } else if (value.getTrade() > 100) {
                output.add("Large amount");
            }
            return output;
        });

        splitStream.select("Small amount")
                .print("Small amount:");

        splitStream.select("Large amount").
                print("Large amount:");

        splitStream.select("Small amount backup", "Large amount")
                .print("Small amount backup and Large amount");

        env.execute("SplitTemplate");
    }
```

##### Project

场景：Project算子作用在元素数据类型为元组的数据流中，根据指定的索引从元组中选择对应的字段组成一个子集，Project算子的参数是变长参数，输出元组的字段顺序与Project算子参数的字段索引的顺序相对应。该算子作用类似SQL中的select

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        List<Tuple3<String, Integer, String>> list = new ArrayList<Tuple3<String, Integer, String>>();
        list.add(new Tuple3<>("185XXX", 899, "周一"));
        list.add(new Tuple3<>("155XXX", 1199, "周二"));
        list.add(new Tuple3<>("138XXX", 19, "周三"));
        DataStream<Tuple3<String, Integer, String>> streamSource = env.fromCollection(list);

        DataStream<Tuple2<String, String>> result = streamSource.project(2, 0);
        result.print("输出结果");
        env.execute("Project Template");
    }

```

##### Union

场景：将两个或者多个**相同类型**的数据流合并成包含所有元素的新数据流

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        DataStream<Long> dataStream = env.generateSequence(1, 2);

        DataStream<Long> otherStream = env.generateSequence(1001, 1002);

        DataStream<Long> union = dataStream.union(otherStream);
        union.print("输出结果");
        env.execute("Union Template");
    }
```

##### Connect

场景：union虽然可以合并多个数据流，但有一个限制，即多个数据流的数据类型必须相同。connect提供了union类似的功能，用来合并两个数据流，与union不同的是，**connect只能合并两个数据流，两个数据流的数据类型可以不一致**

CoMapFunction处理connect之后的数据流，map1处理第一个流的数据，map2处理第二个流的数据，CoFlatMapFunction同理。**Flink并不能保证两个函数调用顺序，两个函数的调用依赖于两个数据流数据的流入先后顺序，即第一个数据流有数据到达时，map1或flatMap1会被调用，第二个数据流有数据到达时，map2或flatMap2会被调用**

```java
    public static StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

    public static ConnectedStreams<Long, String> init() {
        List<Long> listLong = new ArrayList<Long>();
        listLong.add(1L);
        listLong.add(2L);

        List<String> listStr = new ArrayList<String>();
        listStr.add("www cnblogs com intsmaze");
        listStr.add("hello intsmaze");
        listStr.add("hello flink");
        listStr.add("hello java");

        DataStream<Long> longStream = env.fromCollection(listLong);
        DataStream<String> strStream = env.fromCollection(listStr);
        return longStream.connect(strStream);
    }

    public void testConnectMap() throws Exception {

        ConnectedStreams<Long, String> connectedStreams = init();

        DataStream<String> connectedMap = connectedStreams
                .map(new CoMapFunction<Long, String, String>() {
                    @Override
                    public String map1(Long value) {
                        return "数据来自元素类型为long的流" + value;
                    }

                    @Override
                    public String map2(String value) {
                        return "数据来自元素类型为String的流" + value;
                    }
                });
        connectedMap.print();
        env.execute("CoMapFunction");
    }

    public void testConnectFlatMap() throws Exception {

        ConnectedStreams<Long, String> connectedStreams = init();

        DataStream<String> connectedFlatMap = connectedStreams
                .flatMap(new CoFlatMapFunction<Long, String, String>() {
                    @Override
                    public void flatMap1(Long value, Collector<String> out) {
                        out.collect(value.toString());
                    }

                    @Override
                    public void flatMap2(String value, Collector<String> out) {
                        for (String word : value.split(" ")) {
                            out.collect(word);
                        }
                    }
                });
        connectedFlatMap.print();
        env.execute("CoFlatMapFunction");
    }
```

##### Iterate

场景：迭代计算，用于实现需要不断更新模型的算法。Iterate算子将一个算子的输出重定向到某个先前的操作符，并循环。因为流式处理永远不会完成，所以没有最大迭代次数，开发者需要指定数据流的哪一部分去迭代，哪一部分转发下游算子，通常使用Split算子或Filter实现指定

Iterate算子由两个方法组成：

* iterate：负责启动迭代部分，返回的IterativeStream表示迭代的开始，带有迭代的DataStream永远不会终止，用户可以指定参数设置迭代头的最大等待时间，如果指定时间内没有收到数据，则流会终止，默认值为0秒
* closeWith：定义了迭代部分的末尾，**指定的DataStream参数作为反馈并作为迭代头的输入数据源**

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);

        List<Tuple2<String, Integer>> list = new ArrayList<>();
        list.add(new Tuple2<>("flink", 33));
        list.add(new Tuple2<>("strom", 32));
        list.add(new Tuple2<>("spark", 15));
        list.add(new Tuple2<>("java", 18));
        list.add(new Tuple2<>("python", 31));
        list.add(new Tuple2<>("scala", 29));


        DataStream<Tuple2<String, Integer>> inputStream = env.fromCollection(list);

        IterativeStream<Tuple2<String, Integer>> itStream = inputStream
                .iterate(5000);

        SplitStream<Tuple2<String, Integer>> split = itStream
                .map((MapFunction<Tuple2<String, Integer>, Tuple2<String, Integer>>) value -> {
                    Thread.sleep(1000);
                    System.out.println("迭代流上面调用逻辑处理方法，参数为:" + value);
                    return new Tuple2<>(value.f0, --value.f1);
                }).split((OutputSelector<Tuple2<String, Integer>>) value -> {
                    List<String> output = new ArrayList<>();
                    if (value.f1 > 30) {
                        System.out.println("返回迭代数据:" + value);
                        output.add("iterate");
                    } else {
                        output.add("output");
                    }
                    return output;
                });

        itStream.closeWith(split.select("iterate"));

        split.select("output").print("output:");

        env.execute("IterateTemplate");

    }
```

#### 富函数

将RichFunction接口称为富函数，所有算子上应用的函数都有富函数版本。富函数在基本函数的基础上额外提供了一系列方法方便开发者丰富自己的业务逻辑

* void open(Configuration parameters)：执行算子前的初始化方法，在算子第一次被调用之前调用，适合做一些初始化工作
* void close() throws Exception：在算子最后一次调用之后调用，适合做一些释放资源的工作
* RuntimeContext getRuntimeContext()：获取算子运行时的上下文信息。如算子并行度、算子的子任务索引、执行算子的任务名称等
* IterationRuntimeContext getIterationRuntimeContext()：获取迭代算子运行时的上下文信息
* void setRuntimeContext(RuntimeContext t)：设置算子运行时的上下文信息

使用富函数需要实现算子对应的富函数抽象类。不同算子对应的富函数抽象类都继承自AbstractRichFunction，并且实现了算子对应的函数。而AbstractRichFunction则实现了RichFunction接口

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(2);

        DataStream<Long> streamSource = env.generateSequence(1, 100);
        DataStream<Long> dataStream = streamSource
                .flatMap(new RichFlatMapFunction<Long, Long>() {
                    @Override
                    public void open(Configuration parameters) {
                        RuntimeContext rc = getRuntimeContext();
                        String taskName = rc.getTaskName();
                        String subtaskName = rc.getTaskNameWithSubtasks();
                        int subtaskIndexOf = rc.getIndexOfThisSubtask();
                        int parallel = rc.getNumberOfParallelSubtasks();
                        int attemptNum = rc.getAttemptNumber();
                        System.out.println("调用open方法：" + taskName + "||" + subtaskName + "||"
                                + subtaskIndexOf + "||" + parallel + "||" + attemptNum);
                    }

                    @Override
                    public void flatMap(Long input, Collector<Long> out) throws Exception {
                        Thread.sleep(1000);
                        out.collect(input);
                    }

                    @Override
                    public void close() {
                        System.out.println("调用close方法");
                    }
                })
                .name("intsmaze-flatMap");
        dataStream.print();

        env.execute("RichFunctionTemplate");
    }
```

#### 物理分区

数据流中的元素从上一个算子传递给下一个算子时，上游算子发送的元素被分配给下游算子的哪些**并行实例**（**物理分区**），由分区策略决定。**默认情况下，Flink会将上游算子并行实例发送的元素尽可能地转发到和该实例在同一个TaskManager下的下游算子的并行实例中**

https://www.jianshu.com/p/9e9c087bafc1

##### 自定义分区策略

实现自定义分区策略需要实现org.apache.flink.api.common.functions.Partitioner接口的partition方法

```java
int partition(K key, int numPartitions);
```

参数key用来计算元素发往哪个分区（并行实例），**参数numPartitions为下游算子分区（并行实例）的总数量（numPartitions不能大于并行度，否则会报错！！）**。**分区的数值从0开始，返回值的范围只能是从0到numPartitions -1之间**

调用算子的partitionCustom()方法指定元素发往下游算子的哪一个并行实例，Flink提供了三个重载的partitionCustom()方法

```java
public <K> DataStream<T> partitionCustom(Partitioner<K> partitioner, int field)
public <K> DataStream<T> partitionCustom(Partitioner<K> partitioner, String field)
public <K> DataStream<T> partitionCustom(Partitioner<K> partitioner, KeySelector<T, K> keySelector)
```

参数partitioner为实现org.apache.flink.api.common.functions.Partitioner接口的类，根据指定分区键方式的不同区分三种不同的重载方法，与KeyBy算子指定键的方式类似

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        final String flag = "subtask name is ";
        DataStream<Trade> inputStream = env.addSource(new RichSourceFunction<Trade>() {

            @Override
            public void run(SourceContext<Trade> ctx) {
                List<Trade> list = new ArrayList<>();
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("155XXX", 1111, "2019"));//2
                list.add(new Trade("155XXX", 1199, "2019"));//1
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("138XXX", 19, "2019"));//2
                list.add(new Trade("138XXX", 399, "2020"));//2

                for (Trade trade : list) {
                    ctx.collect(trade);
                }
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                System.out.println("source operator " + flag + subtaskName);
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel方法");
            }
        });

        inputStream.map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " first map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        }).partitionCustom((key, numPartitions) -> {
            if (key.getCardNum().contains("185") && key.getTrade() > 1000) {
                return 0;
            } else if (key.getCardNum().contains("155") && key.getTrade() > 1150) {
                return 1;
            } else {
                return 2;
            }
        }, value -> value).map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " second map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        });

        env.execute("Physical partitioning");
    }
```

##### shuffle分区策略

shuffle分区策略可以使用**随机函数**（Random算法）将上游算子并行实例发送的元素**随机**转发到下游算子的某一个并行实例中

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        final String flag = "subtask name is ";
        DataStream<Trade> inputStream = env.addSource(new RichSourceFunction<Trade>() {

            @Override
            public void run(SourceContext<Trade> ctx) {
                List<Trade> list = new ArrayList<>();
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("155XXX", 1111, "2019"));//2
                list.add(new Trade("155XXX", 1199, "2019"));//1
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("138XXX", 19, "2019"));//2
                list.add(new Trade("138XXX", 399, "2020"));//2

                for (Trade trade : list) {
                    ctx.collect(trade);
                }
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                System.out.println("source operator " + flag + subtaskName);
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel方法");
            }
        });

        inputStream.map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " first map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        }).shuffle().map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " second map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        });

        env.execute("Physical partitioning");
    }
```

##### broadcast分区策略

broadcast分区策略可以将上游算子并行实例发送的元素**广播**到下游算子的**每一个**并行实例中，即每个下游算子的并行实例都可以收到同一个元素

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        final String flag = "subtask name is ";
        DataStream<Trade> inputStream = env.addSource(new RichSourceFunction<Trade>() {

            @Override
            public void run(SourceContext<Trade> ctx) {
                List<Trade> list = new ArrayList<>();
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("155XXX", 1111, "2019"));//2
                list.add(new Trade("155XXX", 1199, "2019"));//1
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("138XXX", 19, "2019"));//2
                list.add(new Trade("138XXX", 399, "2020"));//2

                for (Trade trade : list) {
                    ctx.collect(trade);
                }
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                System.out.println("source operator " + flag + subtaskName);
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel方法");
            }
        });

        inputStream.map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " first map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        }).broadcast().map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " second map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        });

        env.execute("Physical partitioning");
    }
```

##### rebalance分区策略

rebalance分区策略可以将上游算子并行实例发送的元素**均匀地**发送到下游算子的并行实例中。它使用循环遍历下游算子并行实例的方式（round-robin）平均分配上游算子并行实例的元素，每个下游算子的并行实例具有相同的负载。当数据流中的数据存在数据倾斜时，该分区策略对性能有很大提升

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        final String flag = "subtask name is ";
        DataStream<Trade> inputStream = env.addSource(new RichSourceFunction<Trade>() {

            @Override
            public void run(SourceContext<Trade> ctx) {
                List<Trade> list = new ArrayList<>();
                list.add(new Trade("185XXX", 899, "2018"));
                list.add(new Trade("155XXX", 1111, "2019"));
                list.add(new Trade("155XXX", 1199, "2019"));
                list.add(new Trade("185XXX", 899, "2018"));
                list.add(new Trade("138XXX", 19, "2019"));
                list.add(new Trade("138XXX", 399, "2020"));
                list.add(new Trade("138XXX", 399, "2020"));
                list.add(new Trade("138XXX", 399, "2020"));

                for (Trade trade : list) {
                    ctx.collect(trade);
                }
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                System.out.println("source operator " + flag + subtaskName);
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel方法");
            }
        }).partitionCustom((key, numPartitions) -> {
            if (key.contains("185")) {
                return 0;
            } else {
                return 1;
            }
        }, Trade::getCardNum);

        inputStream.map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " first map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        }).setParallelism(2)
                .rebalance()
                .map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " second map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        });

        env.execute("Physical partitioning");
    }
```

##### rescale分区策略

rescale分区策略可以将上游算子并行实例发送的元素**均匀地**发送到下游算子的并行实例的**某个子集中**，rescale分区策略会**尽可能避免数据在网络间传输**，而能否避免在网络中传输上下游算子间的数据，具体还取决于其他配置，比如TaskManager的任务槽数，上下游算子的并行度。如果想平均分配上游算子并行实例中的元素以实现负载均衡，且不期望实现rebalance那样的全局负载均衡，则可以使用rescale分区策略

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(4);

        final String flag = "subtask name is ";
        DataStream<Trade> inputStream = env.addSource(new RichSourceFunction<Trade>() {

            @Override
            public void run(SourceContext<Trade> ctx) {
                List<Trade> list = new ArrayList<>();
                list.add(new Trade("185XXX", 899, "2018"));
                list.add(new Trade("155XXX", 1111, "2019"));
                list.add(new Trade("155XXX", 1199, "2019"));
                list.add(new Trade("185XXX", 899, "2018"));
                list.add(new Trade("138XXX", 19, "2019"));
                list.add(new Trade("138XXX", 399, "2020"));
                list.add(new Trade("138XXX", 399, "2020"));
                list.add(new Trade("138XXX", 399, "2020"));

                for (Trade trade : list) {
                    ctx.collect(trade);
                }
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                System.out.println("source operator " + flag + subtaskName);
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel方法");
            }
        }).partitionCustom((key, numPartitions) -> {
            if (key.contains("185")) {
                return 0;
            } else {
                return 1;
            }
        }, Trade::getCardNum);

        inputStream.map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " first map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        }).setParallelism(2)
                .rescale()
                .map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " second map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        });

        env.execute("Physical partitioning");
    }
```

##### forward分区策略

forward分区策略会将上游算子并行实例发送的元素尽可能地转发到和该实例在同一个TaskManager下的下游算子的并行实例中，**forward分区策略要求上下游算子的并行度相同，否则会报错**

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        final String flag = "subtask name is ";
        DataStream<Trade> inputStream = env.addSource(new RichSourceFunction<Trade>() {

            @Override
            public void run(SourceContext<Trade> ctx) {
                List<Trade> list = new ArrayList<>();
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("155XXX", 1111, "2019"));//2
                list.add(new Trade("155XXX", 1199, "2019"));//1
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("138XXX", 19, "2019"));//2
                list.add(new Trade("138XXX", 399, "2020"));//2

                for (Trade trade : list) {
                    ctx.collect(trade);
                }
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                System.out.println("source operator " + flag + subtaskName);
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel方法");
            }
        });

        inputStream.map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " first map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        }).forward().map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " second map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        });

        env.execute("Physical partitioning");
    }
```

##### global分区策略

global分区策略会将上游算子并行实例发送的元素**全部**发送给下游算子index为0的并行实例上

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(3);

        final String flag = "subtask name is ";
        DataStream<Trade> inputStream = env.addSource(new RichSourceFunction<Trade>() {

            @Override
            public void run(SourceContext<Trade> ctx) {
                List<Trade> list = new ArrayList<>();
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("155XXX", 1111, "2019"));//2
                list.add(new Trade("155XXX", 1199, "2019"));//1
                list.add(new Trade("185XXX", 899, "2018"));//2
                list.add(new Trade("138XXX", 19, "2019"));//2
                list.add(new Trade("138XXX", 399, "2020"));//2

                for (Trade trade : list) {
                    ctx.collect(trade);
                }
                String subtaskName = getRuntimeContext().getTaskNameWithSubtasks();
                System.out.println("source operator " + flag + subtaskName);
            }

            @Override
            public void cancel() {
                System.out.println("调用cancel方法");
            }
        });

        inputStream.map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " first map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        }).global().map(new RichMapFunction<Trade, Trade>() {
            @Override
            public Trade map(Trade value) {
                RuntimeContext context = getRuntimeContext();
                String subtaskName = context.getTaskNameWithSubtasks();
                int subtaskIndexOf = context.getIndexOfThisSubtask();
                System.out.println(value + " second map operator " + flag + subtaskName + " index:" + subtaskIndexOf);
                return value;
            }
        });

        env.execute("Physical partitioning");
    }
```

#### 分布式缓存

Flink提供了类似Hadoop的分布式缓存功能，允许文件在本地被算子的并行实例访问。分布式缓存一般用于共享包含静态外部数据的文件，例如数据字典，配置文件，或者机器学习的模型等

使用分布式缓存，首先要将本地（通过JobManager的BLOB服务进行分发）或者远程文件系统（HDFS）的指定文件/目录注册为缓存文件。JobManager会自动将注册的文件/目录复制到所有执行该程序的TaskManager所在的服务器下，默认路径为/tmp。在程序运行时，算子的并行实例会查找指定目录下的文件/目录

JobManager在启动时会实例化一个BLOB（二进制大型对象）服务，并将其绑定到可用的端口上。当Flink的客户端将本地文件注册为分布式缓存文件时，该文件会发送到BLOB服务，然后存储在BLOB服务的存储路径下的对应文件夹中

```java
public void registerCachedFile(String filePath, String name)
```

获取分布式缓存文件需要运行环境的上下文对象，所以算子需要以实现富函数的方式定义

```java
getRuntimeContext().getDistributedCache().getFile("localFile")
```

**分布式缓存文件的内容被算子的并行实例访问一次后就应该保存在并行实例的内部缓存中，否则并行实例每接收一个元素就要访问一次分布式缓存文件，会大幅降低性能。所以应该重写富函数的open()方法，在open()方法中实现对分布式缓存文件地访问，并将数据存储在并行实例的内部缓存（某个成员变量）中**

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        String cacheUrl = "/Users/zhuyufeng/IdeaProjects/LearnFlink/src/main/resources/TextFileSource.txt";
        env.setParallelism(3);
        env.registerCachedFile(cacheUrl, "localFile");

        DataStream<Long> input = env.generateSequence(1, 20);

        input.map(new RichMapFunction<Long, String>() {
            private String cacheStr;

            @Override
            public void open(Configuration config) {
                File myFile = getRuntimeContext().getDistributedCache().getFile("localFile");
                cacheStr = readFile(myFile);
            }

            @Override
            public String map(Long value) throws Exception {
                Thread.sleep(6000);
                return StringUtils.join(value, "---", cacheStr);
            }

            public String readFile(File myFile) {
                System.out.println("fuck fuck fuck" + myFile.getPath());
                BufferedReader reader = null;
                StringBuilder sbf = new StringBuilder();
                try {
                    reader = new BufferedReader(new FileReader(myFile));
                    String tempStr;
                    while ((tempStr = reader.readLine()) != null) {
                        sbf.append(tempStr);
                    }
                    reader.close();
                    return sbf.toString();
                } catch (IOException e) {
                    e.printStackTrace();
                } finally {
                    if (reader != null) {
                        try {
                            reader.close();
                        } catch (IOException e1) {
                            e1.printStackTrace();
                        }
                    }
                }
                return sbf.toString();
            }
        }).print();

        env.execute();
    }
```

**注意事项：如果分布式缓存文件的路径为本地文件系统，那么提交作业的客户端必须和指定的本地文件在同一台服务器中**

#### 算子参数传递

将参数传递到算子所有并行实例中

##### 通过构造函数

##### 通过ExecutionConfig

##### 通过ParameterTool

### 状态与容错

#### 有状态计算

* 无状态计算：如果任务的每次计算只依赖当前输入的数据，根据当前输入的数据产生独立的计算结果，则该计算是无状态计算
* 有状态计算：如果任务的每次计算不仅依赖于当前输入的数据，还依赖于该次计算之前的计算结果，则该计算是有状态计算

在Flink中，状态始终与特定算子相关联，像reduce、sum等算子都是默认带状态，而map、flatmap等算子则默认不带状态

##### Operator状态和Keyed状态

* Operator状态：Operator状态可以用在所有算子上，**每个Operator状态都绑定到一个算子并行实例上。当修改带有Operator状态算子的并行度时，Operator状态支持在算子并行实例之间重新分配状态数据**
* Keyed状态：Keyed状态只能用在KeyedStream中的算子上，每个key对应一个状态，一个算子并行实例可以处理多个key，根据key访问相应的状态。可以把Keyed状态想象成分区的Operator状态，每个key只有一个状态分区。每个key状态可以理解为唯一的<Operator, Key>二元组

##### 托管状态和原始状态

* 托管状态：使用Flink管理的状态结构。FLink运行时对状态进行编码，并将它们写入检查点，开发者可以根据提供的接口更新、管理状态的值
* 原始状态：将状态保存在开发者自定义的数据结构中，Flink对原始状态的内部结构一无所知，只能看到原始状态的二进制值

FLink的所有算子上都可以使用托管状态，原始状态只能在开发者实现自定义算子时使用，**推荐使用托管状态**

##### 托管的Keyed状态

Flink提供了5种类型不同的托管的Keyed状态结构，状态结构仅用于与状态进行交互，状态不一定存储在FLink程序内部，可能驻留在磁盘或其他分布式文件系统中。Flink程序只是持有了这个状态的句柄

为了得到一个状态的句柄，必须创建状态对应的StateDescriptor，它保存了状态的名称（可以创建多个状态，只要具有唯一的名称，便可以在算子中引用它们）、状态所保存的值的类型，以及指定的算子

获取状态结构需要运行环境的上下文对象，所以算子需要通过富函数实现。与分布式缓存同理，状态结构的初始化需要在open()函数中实现

* ValueState<T>：该状态结构为单个值，可以更新和检索

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.setParallelism(2);

        DataStream<Tuple2<Integer, Integer>> inputStream = env.addSource(new RichSourceFunction<Tuple2<Integer, Integer>>() {

            private static final long serialVersionUID = 1L;

            private int counter = 0;

            @Override
            public void run(SourceContext<Tuple2<Integer, Integer>> ctx) throws Exception {
                while (true) {
                    ctx.collect(new Tuple2<>(counter % 5, counter));
                    System.out.println("send data :" + counter % 5 + "," + counter);
                    counter++;
                    Thread.sleep(1000);
                }
            }

            @Override
            public void cancel() {
            }
        });

        KeyedStream<Tuple2<Integer, Integer>, Tuple> keyedStream = inputStream.keyBy(0);

        keyedStream.flatMap(new RichFlatMapFunction<Tuple2<Integer, Integer>, Tuple2<Integer, Integer>>() {

            public transient ValueState<Tuple2<Integer, Integer>> valueState;

            @Override
            public void open(Configuration config) {
                ValueStateDescriptor<Tuple2<Integer, Integer>> descriptor =
                        new ValueStateDescriptor<>(
                                "ValueStateFlatMap",
                                TypeInformation.of(new TypeHint<Tuple2<Integer, Integer>>() {
                                }));
                valueState = getRuntimeContext().getState(descriptor);
            }

            @Override
            public void flatMap(Tuple2<Integer, Integer> input, Collector<Tuple2<Integer, Integer>> out) throws Exception {
                Tuple2<Integer, Integer> currentSum = valueState.value();
                if (currentSum == null) {
                    currentSum = input;
                } else {
                    currentSum.f1 = currentSum.f1 + input.f1;
                    currentSum.f0 = currentSum.f0 + input.f0;
                }
                out.collect(input);
                valueState.update(currentSum);
                System.out.println(Thread.currentThread().getName() + " currentSum after:" + valueState.value() + ",input :" + input);
            }

        });

        env.execute("Intsmaze ValueStateFlatMap");
    }
```

* ListState<T>：该状态结构为一个值列表，可以向列表中追加元素并可迭代列表

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.setParallelism(2);

        DataStream<Tuple2<Integer, Integer>> inputStream = env.addSource(new RichSourceFunction<Tuple2<Integer, Integer>>() {

            private static final long serialVersionUID = 1L;

            private int counter = 0;

            @Override
            public void run(SourceContext<Tuple2<Integer, Integer>> ctx) throws Exception {
                while (true) {
                    ctx.collect(new Tuple2<>(counter % 5, counter));
                    System.out.println("send data :" + counter % 5 + "," + counter);
                    counter++;
                    Thread.sleep(1000);
                }
            }

            @Override
            public void cancel() {
            }
        });

        KeyedStream<Tuple2<Integer, Integer>, Tuple> keyedStream = inputStream.keyBy(0);

        keyedStream.flatMap(new RichFlatMapFunction<Tuple2<Integer, Integer>, String>() {

            public transient ListState<Tuple2<Integer, Integer>> listState;

            @Override
            public void open(Configuration config) {
                ListStateDescriptor<Tuple2<Integer, Integer>> descriptor =
                        new ListStateDescriptor<>(
                                "ListStateFlatMap",
                                TypeInformation.of(new TypeHint<Tuple2<Integer, Integer>>() {
                                }));
                listState = getRuntimeContext().getListState(descriptor);
            }

            @Override
            public void flatMap(Tuple2<Integer, Integer> input, Collector<String> out) throws Exception {
                listState.add(input);
                Iterator<Tuple2<Integer, Integer>> iterator = listState.get().iterator();
                int number = 0;
                StringBuilder strBuffer = new StringBuilder();
                while (iterator.hasNext()) {
                    strBuffer.append(":").append(iterator.next());
                    number++;
                    if (number == 3) {
                        listState.clear();
                        out.collect(strBuffer.toString());
                    }
                }
            }

        }).print();

        env.execute("Intsmaze ValueStateFlatMap");
    }
```

* ReducingState<T>：该状态结构也保存单个值，该值表示添加到该状态中的所有值得聚合结果，聚合逻辑需要在定义ReducingStateDescriptor时指定，在调用add方法时会根据指定的聚合逻辑更新状态的值

```java
    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.setParallelism(2);

        DataStream<Tuple2<Integer, Integer>> inputStream = env.addSource(new RichSourceFunction<Tuple2<Integer, Integer>>() {

            private static final long serialVersionUID = 1L;

            private int counter = 0;

            @Override
            public void run(SourceContext<Tuple2<Integer, Integer>> ctx) throws Exception {
                while (true) {
                    ctx.collect(new Tuple2<>(counter % 5, counter));
                    System.out.println("send data :" + counter % 5 + "," + counter);
                    counter++;
                    Thread.sleep(1000);
                }
            }

            @Override
            public void cancel() {
            }
        });

        KeyedStream<Tuple2<Integer, Integer>, Tuple> keyedStream = inputStream.keyBy(0);

        keyedStream.flatMap(new RichFlatMapFunction<Tuple2<Integer, Integer>, Tuple2<Integer, Integer>>() {

            public transient ReducingState<Tuple2<Integer, Integer>> reducingState;

            @Override
            public void open(Configuration config) {
                ReducingStateDescriptor<Tuple2<Integer, Integer>> descriptor =
                        new ReducingStateDescriptor<>(
                                "ReducingStateFlatMap",
                                (value1, value2) -> new Tuple2<>(value1.f0, value1.f1 + value2.f1),
                                TypeInformation.of(new TypeHint<Tuple2<Integer, Integer>>() {
                                }));
                reducingState = getRuntimeContext().getReducingState(descriptor);
            }

            @Override
            public void flatMap(Tuple2<Integer, Integer> input, Collector<Tuple2<Integer, Integer>> out) throws Exception {
                reducingState.add(input);
                out.collect(reducingState.get());
            }

        }).print();

        env.execute("Intsmaze ValueStateFlatMap");
    }
```

* AggregatingState<IN, OUT>：该状态结构也保存单个值，该值表示添加到该状态中的所有值得聚合结果。与ReducingState不同的是，聚合的类型可以和添加到该状态中的元素类型不同。使用方式与ReducingState基本相同
* MapState<UK, UV>：该状态结构保存了一个映射列表，可以添加、更新、检索键值对。使用方式与ListState基本相同

* 状态生存时间

##### 托管的Operator状态

使用托管的Operator状态，需要算子实现CheckpointedFunction接口或者ListCheckpointed接口。**目前托管的Operator状态只支持ListState类型的状态结构**，且**ListState中的元素要实现序列化接口**，CheckpointedFunction接口已被标为deprecation，推荐使用ListCheckpointed接口

* CheckpointedFunction

  * void snapshotState(FunctionSnapshotContext context) throws Exception：每当请求对状态的快照执行检查点操作时，会自动调用snapshotState方法。参数FunctionSnapshotContext为当前算子的上下文对象

  * void initializeState(FunctionInitializationContext context) throws Exception：在执行期间**创建算子实例**或者**算子从检查点恢复**时调用。参数FunctionInitializationContext为当前算子初始化的上下文对象。该方法用于初始化算子的状态结构。**可以通过FunctionInitializationContext的isRestored()方法判断算子是处于初始化状态还是从失败恢复的状态，因此initializeState不仅是初始化状态的地方，还是状态恢复的地方**

    当更改了具有Operator状态算子的并行度时，Operator状态的数据可以从算子并行实例之间重新分配数据，Flink提供了两种重新分配状态数据的当时

    * Even-Split：有状态算子的每个并行实例返回一个状态元素列表，整个状态在逻辑上是所有列表的连接。在作业恢复时对状态进行重新分配，**新的状态会被平均地划分为尽可能多的并行实例的子列表**。每个并行实例获取一个子列表，该子列表可以为空，也可以包含一个或多个元素
    * Union：有状态算子的每个并行实例返回一个状态元素列表，整个状态在逻辑上是所有列表的连接。在作业恢复时对状态进行重新分配，**有状态算子的每个并行实例都获得状态元素的完整列表**

    ```java
        public interface CheckpointMap extends MapFunction<Long, String>,
                CheckpointedFunction{}
    
        public static void main(String[] args) throws Exception {
    
            StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
            env.enableCheckpointing(10000);
            env.setParallelism(1);
    
            String path = "file:///Users/zhuyufeng/IdeaProjects/LearnFlink/src/main/resources/";
            FsStateBackend stateBackend = new FsStateBackend(path);
            env.setStateBackend(stateBackend);
            env.setRestartStrategy(RestartStrategies.failureRateRestart(
                    3,
                    Time.of(5, TimeUnit.MINUTES),
                    Time.of(10, TimeUnit.SECONDS)
            ));
    
            DataStream<Long> streamSource = env.addSource(new RichSourceFunction<Long>() {
                private static final long serialVersionUID = 1L;
    
                @Override
                public void open(Configuration parameters) throws Exception {
                    Thread.sleep(10000);
                }
    
                @Override
                public void run(SourceContext<Long> ctx) throws Exception {
                    long offset = 0L;
                    while (true) {
                        ctx.collect(offset);
                        offset += 1;
                        Thread.sleep(1000);
                    }
                }
    
                @Override
                public void cancel() {
                }
            }).setParallelism(1);
    
            DataStream<String> mapResult = streamSource
                    .map(new CheckpointMap() {
                        private transient ListState<Long> checkpointedState;
    
                        private final LinkedList<Long> bufferedElements = new LinkedList<>();
    
                        @Override
                        public String map(Long value) {
                            if (value == 30) {
                                int t = 1 / 0;
                            }
    
                            int size = bufferedElements.size();
                            if (size >= 10) {
                                for (int i = 0; i < size - 9; i++) {
                                    bufferedElements.poll();
                                }
                            }
    
                            String threadName = Thread.currentThread().getName();
                            bufferedElements.add(value);
    
                            return " 集合中第一个元素是:" + bufferedElements.getFirst() +
                                    " 集合中最后一个元素是:" + bufferedElements.getLast() +
                                    " length is :" + bufferedElements.size();
                        }
    
                        @Override
                        public void snapshotState(FunctionSnapshotContext context) throws Exception {
                            checkpointedState.clear();
                            checkpointedState.addAll(bufferedElements);
                        }
    
                        @Override
                        public void initializeState(FunctionInitializationContext context) throws Exception {
                            ListStateDescriptor<Long> descriptor =
                                    new ListStateDescriptor<>(
                                            "CheckpointedFunctionTemplate-ListState",
                                            TypeInformation.of(new TypeHint<Long>() {
                                            }));
    //                        checkpointedState = context.getOperatorStateStore().getUnionListState(descriptor);
                            checkpointedState = context.getOperatorStateStore().getListState(descriptor);
                            if (context.isRestored()) {
                                for (Long element : checkpointedState.get()) {
                                    bufferedElements.offer(element);
                                }
                            }
                        }
                    });
            mapResult.print("输出结果");
            env.execute("Intsmaze CheckpointedFunctionTemplate");
        }
    ```

* ListCheckpointed：ListCheckpointed在作业恢复时使用Even-Split方式分配状态内的数据，如果状态的类型为自定义的JavaBean类型，则JavaBean必须实现Serializable接口

  * List<T> snapshotState(long checkpointId, long timestamp) throws Exception：每当执行检查点操作对当前状态进行快照时，会自动调用snapshotState方法。**此方法返回的容器保存着放入ListState的数据，换句话说，通过此方法返回要存入ListState的数据，Flink会自动将返回容器中的数据填充到ListState中**，返回的容器可以为null或者为空，也可以包含一个或者多个元素。参数timestamp为JobManager触发对状态的快照进行检查点操作时的时间戳，参数checkpointId当前进行检查点操作的ID
  * void restoreState(List<T> state) throws Exception：此方法在**创建算子实例**或者**从检查点恢复时**调用。**参数state为容纳ListState状态数据的容器，换句话说，算子的ListState状态数据会自动填充到state容器中，并作为参数传递给方法**

  ```java
      private interface ListCheckpointMap extends MapFunction<Long, String>,
              ListCheckpointed<Long>{}
  
      public static void main(String[] args) throws Exception {
          StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
          env.enableCheckpointing(10000);
          env.setParallelism(1);
          String path = "file:///Users/zhuyufeng/IdeaProjects/LearnFlink/src/main/resources/";
          StateBackend stateBackend = new FsStateBackend(path);
          env.setStateBackend(stateBackend);
          env.setRestartStrategy(RestartStrategies.failureRateRestart(
                  3,
                  Time.of(5, TimeUnit.MINUTES),
                  Time.of(10, TimeUnit.SECONDS)
          ));
  
          env.addSource(new RichSourceFunction<Long>() {
              private static final long serialVersionUID = 1L;
  
              @Override
              public void open(Configuration parameters) throws Exception {
                  Thread.sleep(10000);
              }
  
              @Override
              public void run(SourceContext<Long> ctx) throws Exception {
                  long offset = 0L;
                  while (true) {
                      ctx.collect(offset);
                      offset += 1;
                      Thread.sleep(1000);
                  }
              }
  
              @Override
              public void cancel() {
              }
          }).setParallelism(1)
                  .map(new ListCheckpointMap() {
                      private List<Long> bufferedElements = new LinkedList<>();
  
                      @Override
                      public List<Long> snapshotState(long checkpointId, long timestamp) {
                          return bufferedElements;
                      }
  
                      @Override
                      public void restoreState(List<Long> state) {
                          bufferedElements = state;
                      }
  
                      @Override
                      public String map(Long value) {
                          if (value == 30) {
                              int i = 1 / 0;
                          }
  
                          int size = bufferedElements.size();
                          if (size >= 10) {
                              for (int i = 0; i < size - 9; i++) {
                                  Long poll = bufferedElements.remove(0);
                              }
                          }
                          bufferedElements.add(value);
  
                          return "集合中第一个元素是:" + bufferedElements.get(0) +
                                  " 集合中最后一个元素是:" + bufferedElements.get(bufferedElements.size() - 1) +
                                  " length is :" + bufferedElements.size();
                      }
                  }).print("输出结果");
  
          env.execute("Intsmaze CheckpointedFunctionTemplate");
      }
  ```

#### 检查点机制

Flink中的每个算子都可以是有状态的，有状态的算子在处理过程中会存储计算的中间结果数据。当具有有状态算子的作业失败后重新启动时，有状态算子中存储的状态数据就会丢失。为了使有状态算子具有容错特性，Flink需要定期对状态的快照进行检查点操作以将状态数据持久化存储。当作业重启时可以从检查点中的数据恢复，让作业具有和无故障执行相同的效果

##### 先决条件

要保证Flink的有状态算子可以和检查点机制的持久存储交互，需要满足两个前提

* 可以在一定时间内重发记录的持久数据源（Kafka、HDFS等）
* 状态的持久存储系统，通常是分布式文件系统

##### 启用检查点

默认情况下检查点机制是禁用的。启用检查点机制需要调用StreamExecutionEnvironment的enableCheckpointing方法

```java
public StreamExecutionEnvironment enableCheckpointing(long interval)
```

参数interval为以毫秒为单位执行检查点操作的间隔，代表每隔interval毫秒执行一次检查点操作

##### 配置检查点

调用StreamExecutionEnvironment的getCheckpointConfig方法得到CheckpointConfig对象

```java
public CheckpointConfig getCheckpointConfig()
```

通过CheckpointConfig对象配置检查点的细粒度参数，除此之外，还可以在$FLINK_HOME/conf/flink-conf.xml配置文件中配置更多的参数

##### 目录结构

检查点由元数据文件组成，根据所选的状态后端，还包括一些额外的数据文件。可以在$FLINK_HOME/conf/flink-conf.xml配置文件中通过state.checkpoints.dir参数**全局**配置元数据文件和数据文件指定存储的目录，也可以在每个作业中指定特定的目录

#### 状态后端

当检查点被激活后，每次检查点操作都会将状态的快照持久化存储来防止失败而导致的状态数据丢失。**状态在内部如何表示，以及在检查点上如何持久保存，取决于所选的状态后端**

状态后端配置了基本的目录结构，将特定检查点的数据保留在特定子目录中。状态后端将会为每一个激活检查点机制的作业创建一个带有作业ID的子目录，比如/Users/zhuyufeng/IdeaProjects/LearnFlink/src/main/resources/3ffd3202ab63449c19a8ed264ad75cc9，该子目录包含实际的检查点数据，每个检查点单独将其所有文件存储在包含检查点编号的子目录中，比如/Users/zhuyufeng/IdeaProjects/LearnFlink/src/main/resources/3ffd3202ab63449c19a8ed264ad75cc9/chk-5

检查点操作执行**完成后**会将该检查点的元数据写入名为_metadata的文件

FLink提供三种可用的状态后端

##### MemoryStateBackend

如果没有为作业配置状态后端，那么默认使用MemoryStateBackend作为作业的状态后端。MemoryStateBackend状态后端将作业的状态数据保存在**TaskManager的JVM堆内存中**。为了防止作业状态数据丢失，检查点操作会将存储在TaskManager内存中的状态数据作为检查点确认消息的一部分发送给JobManager，也就是说**状态数据存储在JobManager的JVM堆内存中**

##### FsStateBackend

FsStateBackend状态后端将作业的状态数据保存在**TaskManager的JVM堆内存中**。为了防止作业状态数据丢失，检查点操作将对TaskManager内存中的状态数据进行快照，并将该快照持久化保存在指定文件系统的路径下，即**状态数据存储在文件系统中**，同时会将极少的元数据存储在JobManager内存中

##### RocksDBStateBackend

RocksDBStateBackend状态后端将作业的状态数据保存在RocksDB数据库中（一种嵌入式本地数据库），**默认情况下该数据库中的数据存储在TaskManager的数据目录中，实际上是采用内存+磁盘的方法进行存储的，因此该状态后端可以存储非常大的状态，并溢出到磁盘中**。为了防止作业状态数据丢失，检查点操作将对RocksDB数据库中的状态进行快照，并将该快照持久化保存在指定文件系统的路径下

如果想在作业中使用RocksDBStateBackend状态后端API，则需要在pom.xml文件中添加RocksDBStateBackend依赖项 

##### 配置状态后端

默认的状态后端是MemoryStateBackend。Flink支持两种方式配置状态后端

* 设置单个作业的状态后端

  ```java
  StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
  env.setStateBackend(new FsStateBackend(path));
  ```

* 设置所有作业默认的状态后端

  在$FLINK_HOME/conf/flink-conf.xml配置文件中通过state.backend和state.checkpoints.dir配置默认的状态后端，该配置会对**所有**作业生效

如果在作业中配置了状态后端，则会覆盖在配置文件中配置的状态后端，否则会使用配置文件中的配置的状态后端

#### 保存点机制

保存点是作业执行时状态的一致性镜像，它是通过FLink的检查点机制创建的，与检查点不同的是，保存点可以用来**停止、恢复和更新作业**

保存点由两部分组成：大型二进制文件和一个相对较小的元数据文件。保存点的元数据文件以绝对路径的形式包含指向稳定存储中属于保存点所有文件的指针

检查点和保存点的使用场景主要有如下不同：

* **检查点的主要作用是在作业意外失败后重新启动时提供快速的状态恢复机制**。检查点的生命周期由Flink管理，也就是说检查点是由FLink自动创建、拥有和发布的，不需要与开发者进行交互，当作业终止后（停止在集群上运行），该作业的检查点就无法再提供状态恢复机制
* **保存点用于手动备份和恢复作业**。例如作业的版本更新、更改作业的DAG图、更改代码的业务逻辑等。保存点由开发者手动创建、拥有和删除，因此保存点必须在作业终止后仍然存在

##### 分配操作符id

虽然检查点和保存点使用场景不同，但在当前版本的Flink中检查点和保存点的实现基本上都使用相同的代码，唯一不同是保存点需要在每个有状态算子上调用uid方法来手动指定该算子的id，这些id用于限定每个算子的状态。需要注意的是，每个算子设置的id必须唯一，否则作业的发布将失败。如果不手动指定每个算子的id，则它们将随机生成，只要这些id不变，作业就可以从保存点自动恢复。保存点可以理解成为每个有状态算子（**无状态算子不是保存点的一部分**）保存一个<id,state>的映射

##### 保存点操作

当为作业的算子分配id后，就可以使用Flink命令行客户端进行触发保存点、取消带有保存点的作业、作业从保存点恢复并处理保存点的操作

https://blog.csdn.net/lvwenyuan_1/article/details/94435388

```java
    private interface ListCheckpointMap extends MapFunction<Long, String>,
            ListCheckpointed<Long> {}

    public static void main(String[] args) throws Exception {

        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(1);
        env.enableCheckpointing(20000);

        String path = "file:///Users/zhuyufeng/IdeaProjects/LearnFlink/src/main/resources";
        StateBackend stateBackend = new RocksDBStateBackend(path);
        env.setStateBackend(stateBackend);

        DataStream<Long> sourceStream = env.addSource(new RichSourceFunction<Long>() {
                    private static final long serialVersionUID = 1L;

                    @Override
                    public void open(Configuration parameters) throws Exception {
                        Thread.sleep(10000);
                    }

                    @Override
                    public void run(SourceContext<Long> ctx) throws Exception {
                        long offset = 0L;
                        while (true) {
                            ctx.collect(offset);
                            offset += 1;
                            Thread.sleep(1000);
                        }
                    }

                    @Override
                    public void cancel() {
                    }
                }).setParallelism(1);

        sourceStream.map(new ListCheckpointMap() {
            private List<Long> bufferedElements = new LinkedList<>();

            @Override
            public List<Long> snapshotState(long checkpointId, long timestamp) {
                return bufferedElements;
            }

            @Override
            public void restoreState(List<Long> state) {
                bufferedElements = state;
            }

            @Override
            public String map(Long value) {

                int size = bufferedElements.size();
                if (size >= 10) {
                    for (int i = 0; i < size - 9; i++) {
                        bufferedElements.remove(0);
                    }
                }
                bufferedElements.add(value);

                return "集合中第一个元素是:" + bufferedElements.get(0) +
                        " 集合中最后一个元素是:" + bufferedElements.get(bufferedElements.size() - 1) +
                        " length is :" + bufferedElements.size();
            }
        }).uid("map-id").print();

        env.execute("Intsmaze SavePointedTemplate");
    }
```

1. 触发保存点操作

   当触发作业的保存点操作时，Flink会创建一个新的保存点目录，其中存储数据和元数据，可以修改配置文件的配置或者执行命令时指定目录

   ```shell
   flink savepoint 7b21d7ed13a29c363c7626e6f4607e78 /Users/zhuyufeng/Desktop
   //取决于Flink作业的部署模式
   flink savepoint 7b21d7ed13a29c363c7626e6f4607e78 -yid application_1625210509488_0003 /Users/zhuyufeng/Desktop
   ```

   通过Flink命令行触发保存点操作不会取消正在运行的作业。如果没有指定目录，则使用$FLINK_HOME/conf/flink-conf.xml配置文件中配置的路径

2. 从保存点恢复作业

   将作业从保存点恢复有FLink命令行和Web UI两种

   ```shell
   flink run -s /Users/zhuyufeng/Desktop/savepoint-7b21d7-0f2d4efe0667 -m yarn-cluster /Users/zhuyufeng/IdeaProjects/LearnFlink/target/LearnFlink-1.0-SNAPSHOT.jar
   ```

3. 允许存在Non-Restored状态

   默认情况下，Flink尝试将保存点中的所有状态与提交的作业中有状态算子进行匹配，如果作业从保存点还原，该保存点包含已删除算子的状态，则作业将无法恢复并执行，默认需要确保所有状态数据都要对应一个算子。如果希望允许跳过无法通过新作业恢复的保存点状态，那么可以设置allowNonRestoredState标志来允许存在非还原的状态，对于Flink命令行，只需要加上-n标识即可

   ```shell
   flink run -s /Users/zhuyufeng/Desktop/savepoint-7b21d7-0f2d4efe0667 -n -m yarn-cluster /Users/zhuyufeng/IdeaProjects/LearnFlink/target/LearnFlink-1.0-SNAPSHOT.jar
   ```

4. 触发保存点操作并取消作业

   正常来说，触发保存点操作后下一步操作应该是停止作业的运行，以便发布新作业。如果触发保存点操作后，作业仍在运行，则从保存点恢复后会出现消息重复处理的情况。Flink为此提供了一套命令在触发保存点操作后取消作业的运行

   ```shell
   flink cancel -s /Users/zhuyufeng/Desktop 11ece526d9a3c1ccb388fac58d72f6a2 -yid application_1625210509488_0006
   ```

##### 保存点配置

Flink提供了在$FLINK_HOME/conf/flink-conf.xml配置文件中通过state.savepoints.dir参数配置保存点的默认目录。在执行保存点命令时指定目标目录会覆盖默认的目标目录。如果既没有配置默认目录，又没有在执行保存点命令时指定，则保存点操作会失败

#### 广播状态

除了普通的状态，Flink还提供了另一种状态即广播状态，引入广播状态的目的是为了支持来自一个数据流的数据有时需要广播到下游算子的所有并行实例的业务场景。例如广播状态可以作为一种模式匹配出现，使用数据流中的元素对来自另一个数据流中的所有元素进行校验

广播状态与将参数传递给算子的区别在于，将参数传递给算子仅在作业初始化运行时传递一次，且在作业运行中无法更改参数值从而达到更新的目的，而对于广播状态，当后续要更改作用于主数据流中元素的参数时，只需要向广播流发送新的元素即可

##### 使用条件

* 广播状态仅提供MapState类型的状态结构，且仅能用于特定的算子上

  ```java
  final MapStateDescriptor<Integer, String> stateDesc = new MapStateDescriptor<>(
          "broadcast-state", Integer.class, String.class
  );
  
  BroadcastStream<Tuple2<Integer, String>> broadcastStream = ruleStream.broadcast(stateDesc);
  ```

* 在非广播数据流中调用connect算子连接广播数据流，得到BroadcastConnectedStream，再调用process算子来使用广播状态的数据去处理另一数据流中的数据。如果非广播流是KeyedStream类型的数据流，process算子的参数就是KeyedBroadcastProcessFunction；如果非广播流是DataStream类型的数据流，process算子的参数就是BroadcastProcessFunction

##### 广播函数

无论是BroadcastProcessFunction还是KeyedBroadcastProcessFunction，都需要实现processElement和processBroadcastElement方法

```java
public abstract void processElement(final IN1 value, final ReadOnlyContext ctx, final Collector<OUT> out) throws Exception;
public abstract void processBroadcastElement(final IN2 value, final Context ctx, final Collector<OUT> out) throws Exception;
```

processElement处理非广播流的元素，processBroadcastElement处理广播流的元素。两种方法提供的上下文对象是不同的，ReadOnlyContext上下文对象对获取的广播状态具有**只读**权限，Context上下文对象对获取的广播状态具有**读写**权限

```java
    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
        env.setParallelism(2);

        DataStream<Tuple2<Integer, String>> ruleStream = env.addSource(new RichSourceFunction<Tuple2<Integer, String>>() {
            private final String[] format = new String[]{"yyyy-MM-dd HH:mm", "yyyy-MM-dd HH",
                    "yyyy-MM-dd", "yyyy-MM", "yyyy"};

            @Override
            public void run(SourceContext<Tuple2<Integer, String>> ctx) throws Exception {
                while (true) {
                    for (String rule : format) {
                        ctx.collect(new Tuple2<>(1, rule));
                        Thread.sleep(5000);
                    }
                }
            }

            @Override
            public void cancel() {

            }
        });

        DataStream<Date> mainStream = env.addSource(new RichSourceFunction<Date>() {

            @Override
            public void run(SourceContext<Date> ctx) throws InterruptedException {
                while (true) {
                    ctx.collect(new Date());
                    Thread.sleep(1000);
                }
            }

            @Override
            public void cancel() {
            }
        });

        final MapStateDescriptor<Integer, String> stateDesc = new MapStateDescriptor<>(
                "broadcast-state", Integer.class, String.class
        );

        BroadcastStream<Tuple2<Integer, String>> broadcastStream = ruleStream.broadcast(stateDesc);

        DataStream<Tuple2<String, String>> result = mainStream.connect(broadcastStream)
                .process(new BroadcastProcessFunction<Date, Tuple2<Integer, String>, Tuple2<String, String>>() {
                    private transient MapStateDescriptor<Integer, String> descriptor;

                    @Override
                    public void open(Configuration parameters) {
                        descriptor = new MapStateDescriptor<>(
                                "broadcast-state", Integer.class, String.class
                        );
                    }

                    @Override
                    public void processElement(Date value, ReadOnlyContext ctx,
                                               Collector<Tuple2<String, String>> out) throws Exception {
                        String formatRule = "";
                        for (Map.Entry<Integer, String> entry :
                                //Map.Entry<K,V>，代表Map集合中的每个元素 https://blog.csdn.net/itaem/article/details/8171663
                                ctx.getBroadcastState(descriptor).immutableEntries()) {
                            if (entry.getKey() == 1) {
                                formatRule = entry.getValue();
                            }
                        }
                        if (StringUtils.isNotBlank(formatRule)) {
                            SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
                            String originalDate = format.format(value);
                            format = new SimpleDateFormat(formatRule);
                            String formatDate = format.format(value);
                            out.collect(Tuple2.of("主数据流元素:" + originalDate, "应用规则后的格式：" + formatDate));
                        }
                    }

                    @Override
                    public void processBroadcastElement(Tuple2<Integer, String> value, Context ctx,
                                                        Collector<Tuple2<String, String>> out) throws Exception {
                        BroadcastState<Integer, String> broadcastState = ctx.getBroadcastState(descriptor);
                        //这里因为元素的key全都相同，所以后面的元素会覆盖前面元素的值
                        broadcastState.put(value.f0, value.f1);
                        out.collect(new Tuple2<>("广播状态中新增元素", value.toString()));
                    }
                });

        result.print("输出结果");

        env.execute("BroadcastState Template");
    }
```



### Flink CDC

