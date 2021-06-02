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

### Flink on Yarn

#### Yarn集群中启动长期运行的Flink集群

##### 启动

1. 将hadoop的jar包copy至flink/lib目录下

```shell
cp /opt/hadoop/share/hadoop/common/*.jar /opt/flink/lib
cp /opt/hadoop/share/hadoop/common/lib/*.jar /opt/flink/lib
cp /opt/hadoop/share/hadoop/yarn/*.jar /opt/flink/lib
cp /opt/hadoop/share/hadoop/common/lib/*.jar /opt/flink/lib
```

2. 删除flink/lib目录下commons-cli-1.*.jar包

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

以lambda表达式的形式使用flink算子，如果算子的泛型中再嵌套泛型，会使flink无法推断出被嵌套的泛型类型。需要开发者在lambda表达式后再调用return方法来添加此算子的类型信息提示

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

调用StreamExecutionEnvironment的addSource方法可以添加新的数据源，Flink提供了一批实现好的连接器以支持对应的数据源，同时开发者也可以实现自定义的数据源函数去读取指定系统的数据

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

* 使用索引定义键：
* 使用字段表达式定义键：
* 使用键选择器函数定义键：