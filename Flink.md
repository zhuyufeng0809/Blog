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

