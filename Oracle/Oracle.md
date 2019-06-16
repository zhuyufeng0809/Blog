## Oracle

 <div align=center>
    <img src="http://ww3.sinaimg.cn/large/006tNc79ly1g43381dkv9j30pk0dwdg6.jpg" width="70%" align="center"/>
 </div>

 <p align=center font-weight:800>甲骨文公司的一款关系数据库管理系统</p>

### 基础概念：

**数据库**：在Oracle中，数据库是一个基于磁盘的数据文件、控制文件、日志文件、参数文件和归档日志文件等组成的物理文件集合，位于**磁盘**中。

**实例**：实例是指一组Oracle后台进程以及在服务器中分配的共享内存区域，位于**内存**中。

**数据库对象**：指表，索引，视图，图表，缺省值，规则，触发器，用户，函数等。

**Scheme**：称为模式或者方案。模式是一个数据库对象的集合。schema和用户是一对一的关系，并且schema的名称与用户的名称相同。也就是说，一个schema是一个包含着同名用户所创建的数据库对象的集合。

**表空间**：包含一个或多个数据文件，物理上类似于操作系统中的文件夹。Oracle的存储空间在逻辑上表现为表空间，物理上表现为数据文件。一个用户创建的多个数据库对象可以存放在不同的表空间下。

**PS**：  

&emsp;&emsp;实例和数据库的关系，不太准确的说，就和程序和进程、类和对象的关系差不多。一个数据库可以拥有多个实例，也就是一对N，但是正常情况下，都是一对一的关系。  
&emsp;&emsp;一个数据库可以包含多个表空间，可以包含多个schema。  
&emsp;&emsp;schema和表空间是多对多的关系，一个schema包含的数据库对象可存放在不同的表空间中，一个表空间中可存放不同schema的数据库对象。schema只是按照不同的用户把数据库对象筛选出来集中在一起。

### 体系结构：

 <div align=center>
    <img src="http://ww1.sinaimg.cn/large/006tNc79ly1g433lvlys5j30i30bujrz.jpg" width="70%" align="center"/>
 </div>

 Oracle的体系结构大概由三部分组成：

 * 前台程序
 * 实例
 * 数据库

 &emsp;&emsp;当用户连接到数据库时，实际上连接的是数据库的实例，然后由实例负责与数据库进行通信。通常情况，一个数据库对应一个实例，用户通过连接实例访问数据库，我们在Oracle客户端，会看到一个叫schema的东西，并且一个实例有很多schema。根据schema的定义，我们查看一个数据库的数据库对象时，是以用户分类的，每个数据库对象都会归类到创建该对象的用户所对应的schema下。

### 数据字典

### 用户与权限管理

### 参考资料：

 <div align=left>
    <img src="http://ww1.sinaimg.cn/large/006tNc79ly1g434j062gaj30u012cwkk.jpg" width="16%"/>
    <br>
 </div>

[Oracle 11g从入门到精通（第2版）](https://book.douban.com/subject/30411280/)

