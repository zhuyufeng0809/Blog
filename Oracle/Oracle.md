## Oracle

 <div align=center>
    <img src="http://ww3.sinaimg.cn/large/006tNc79ly1g43381dkv9j30pk0dwdg6.jpg" width="70%" align="center"/>
 </div>

 <p align=center font-weight:800>甲骨文公司的一款关系数据库管理系统</p>

### 基础概念：

**数据库**：在Oracle中，数据库是一个基于磁盘的数据文件、控制文件、日志文件、参数文件和归档日志文件等组成的物理文件集合，位于**磁盘**中。

**实例**：实例是指一组Oracle后台进程以及在服务器中分配的共享内存区域，位于**内存**中。

**PS**：实例和数据库的关系，不太准确的说，就和程序和进程、类和对象的关系差不多。一个数据库可以拥有多个实例，也就是一对N，但是正常情况下，都是一对一的关系。

### 体系结构：

 <div align=center>
    <img src="http://ww1.sinaimg.cn/large/006tNc79ly1g433lvlys5j30i30bujrz.jpg" width="70%" align="center"/>
 </div>

 Oracle的体系结构大概由三部分组成：

 * 前台程序
 * 实例
 * 数据库

 &emsp;&emsp;当用户连接到数据库时，实际上连接的是数据库的实例，然后由实例负责与数据库进行通信。

### 数据字典

### 用户与权限管理

### 参考资料：

 <div align=left>
    <img src="http://ww1.sinaimg.cn/large/006tNc79ly1g434j062gaj30u012cwkk.jpg" width="16%"/>
    <br>
 </div>

[Oracle 11g从入门到精通（第2版）](https://book.douban.com/subject/30411280/)

