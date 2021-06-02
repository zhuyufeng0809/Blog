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

