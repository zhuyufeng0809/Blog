## 关于HTTP

#### 概述：

 <div align=center>
    <img src="http://ww4.sinaimg.cn/large/006tNc79ly1g3b9dsz86tj30ez04w0sm.jpg" width="50%"/>
    <br>
 </div>

&emsp;&emsp;WEB的应用层协议是**超文本传输协议**（HyperText Transfer Protocol，即HTTP），它是WEB的核心。HTTP由两个进程实现：一个**客户**进程和一个**服务器**进程。  
&emsp;&emsp;HTTP定义了WEB客户向WEB服务器请求WEB页面的方式，以及服务器向客户传送WEB页面的方式。  
&emsp;&emsp;HTTP使用**TCP**作为它的运输层协议，默认端口号为**80**。  
&emsp;&emsp;PS：服务器向客户发送被请求的文件，而不存储任何关于该客户的状态信息，所以说HTTP是一个**无状态协议**。

#### 分类：

&emsp;&emsp;**非持续链接**：一个进程为每个请求/响应建立和维护一个全新的TCP链接。（缺点：服务器开销大，分组时延大）  
&emsp;&emsp;**持续链接**：一个进程为所有请求/响应建立和维护一个统一的TCP链接。  
&emsp;&emsp;PS：默认采用**持续链接**。

#### HTTP报文：

 <div align=center>
    <img src="http://ww1.sinaimg.cn/large/006tNc79ly1g3b8zv15kuj30hs079q34.jpg" width="50%"/>
    <br>
 </div>

##### 请求报文： 

 格式：

    <method> <request-URL> <version>（请求行）
    <headers>（头部）
    <entity-body>（请求体）

 **请求行**：请求报文请求服务器对资源进行一些操作。请求行（即请求报文的起始行），包含一个方法和一个请求URL，这个方法描述了服务器应该执行的操作，请求URL描述了要对哪个资源执行这个方法。请求行中包含HTTP的版本，用来告知服务器，客户端使用的是那种HTTP。如下例子：

 <div align=center>
    <img src="http://ww1.sinaimg.cn/large/006tNc79ly1g3bbkybv7yj306r03adfp.jpg" width="30%"/>
    <br>
 </div>

 &emsp;&emsp;[方法](#method)（method）：客户端希望服务器对资源执行的动作，是一个单独的词，如GET,POST等。  

 &emsp;&emsp;请求URL（request-URL）：命名了所请求资源，或者URL路径组件的完整URL。如果直接与服务器进行对话，只要URL的路径组件是资源的绝对路径，通常就不会有什么问题——服务器可以假定自己是URL的主机/端口。  

 &emsp;&emsp;版本(version)：报文所使用的HTTP版本，其格式如下：HTTP/. 其中主要版本号(major)和次要版本号(minor)都是整数。版本号会以http/x、y的形式出现在请求和响应报文的起始行中，为应用程序提供了一种将自己遵循的协议版本告知对方的方式通信时最好使请求和响应的版本号保持一致，否则很容易造成误解，使程序无法识别。PS：版本号不会被当做分数处理，每个数字都是独立的，比如，HTTP/2.22版本高于HTTP/2.3。

 **头部**：  

 &emsp;&emsp;首部（header）：可以有另个或多个首部，每个首部都包含一个名字，后面跟着一个冒号（;），然后是一个可选的空格，接着是一个值，最后是一个CRLF。首部是由一个空行（CRLF）结束的，表示了首部列表的结束和实体主体部分的开始。  

 &emsp;&emsp;首部延续行：将长的首部行分为多行可以提高可读性，多出来的每行前面至少要有一个空格或制表符（tab）。

 **请求体**：

  &emsp;&emsp;实体的主体部分（entity-body）：实体的主体部分包含一个由任意数据组成的数据块。并不是所有的报文都包含实体的主体部分，有时候，报文只是以一个CRLF结束。HTTP报文可以承载很多类型的数字数据：图片、视频、HTML文档、软件应用程序、信用卡事务、电子邮件等。



 <div align=center>
    <img src="http://ww3.sinaimg.cn/large/006tNc79ly1g3b94rbxkcj30hs06x74g.jpg" width="50%"/>
    <br>
 </div>

##### 响应报文：

 格式：

    <version><status><reason-phrase>（状态行）
    <headers>（头部）
    <entity-body>（响应体）
 **状态行**：响应报文承载了状态信息和操作产生的所有结果数据，将其返回给客户端。响应行（即响应报文的起始行），包含了响应报文使用的HTTP版本、数字状态码，以及描述操作状态的文本形式的原因短语。
这些字段都由空格符进行分隔，如下例子:

 <div align=center>
    <img src="http://ww1.sinaimg.cn/large/006tNc79ly1g3bbmouhd6j308c03p0sn.jpg" width="30%"/>
    <br>
 </div>
 
 &emsp;&emsp;版本(version)：同上。  

 &emsp;&emsp;[状态码](#code)（status-code）：这三位数字描述了请求过程中所发生的情况。每个状态码的第一位数字用于描述状态的一般类型（“成功”、“出错”等）。
 
 &emsp;&emsp;原因短语（reason-phrase）：数字状态码的可读版本，包含行种植序列之前的所有文本。原因短语只对人类有意义。原因短语为状态码提供了文本形式的解释，和状态码成对出现，是状态码的可读版本，应用程序将其传给客户，说明在请求期间发生了什么。

 **头部**：  

 &emsp;&emsp;首部（header）：同上。

 **响应体**：
 
 &emsp;&emsp;实体的主体部分（entity-body）：同上。

#### 补充：

##### <span id="method">方法</span>：

|整体范围|已定义范围|分类|
|:-:|:-:|:-:|
|GET|从服务器获取一份文档|否|
|HEAD|只从服务器获取文档的首部|否|
|POST|向服务器发送需要处理的数据|是|
|PUT|将请求的主体部分存储在服务器上|是|
|TRACE|对可能经过代理服务器传送到服务器上去的报文进行追踪|否|
|OPTIONS|决定可以在服务器上执行哪些方法|否|
|DELETE|从服务器上删除一份文档|否|

##### <span id="code">状态码</span>：

|整体范围|已定义范围|分类|
|:-:|:-:|:-:|
|100~199|100~101|信息提示|
|200~299|200~206|成功|
|300~399|300~305|重定向|
|400~499|400~415|客户端错误|
|500~599|500~505|服务器错误|