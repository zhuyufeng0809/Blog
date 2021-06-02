#### 位图

https://www.cnblogs.com/cjsblog/p/11613708.html

#### 匿名类

Java中可以实现一个类中包含另外一个类，且不需要提供任何的类名直接实例化。匿名类是不能有名字的类，它们不能被引用，只能在创建时用new语句来声明它们。

**匿名类通常继承一个父类或实现一个接口**

匿名类语法格式：

```
class outerClass {

    // 定义一个匿名类
    object1 = new 父类名|接口名(参数列表) {
         // 匿名类代码
    };
}
```

```
public class AnonymousClass {
    public static void main(String[] args) {
        AnonymousDemo1 an1 = new AnonymousDemo1();
        an1.createClass();

        AnonymousDemo2 an2 = new AnonymousDemo2();
        an2.createClass();
    }
}

class Polygon1 {
    public void display() {
        System.out.println("在 Polygon 类内部");
    }
}

class AnonymousDemo1 {
    public void createClass() {
        // 创建的匿名类继承了 Polygon 类
        Polygon1 p1 = new Polygon1() {
            @Override
            public void display() {
                System.out.println("在匿名类内部");
            }
        };
        p1.display();
    }
}

interface Polygon2 {
    public void display();
}

class AnonymousDemo2 {
    public void createClass() {
        // 匿名类实现一个接口
        Polygon2 p1 = new Polygon2() {
            public void display() {
                System.out.println("在匿名类内部");
            }
        };
        p1.display();
    }
}
```
#### 多线程共享数据的方式

1. 静态成员变量

2. 使用同一个runnable对象

3. 将共享数据分别传递给不同的runnable对象

```
public class Test {
    public static void main(String[] args) {
        final Data data = new Data();
        new Thread(new RunnableA(data)).start();
        new Thread(new RunnableB(data)).start();
    }
}

public class Data {
    int a = 1;
    synchronized public void add(){
        a += 1;
    }
}

public class RunnableA implements Runnable{
    private final Data data;

    public RunnableA(Data data){
        this.data = data;
    }

    @Override
    public void run(){
        data.add();
        System.out.println("RunnableA：" + data.a);
    }
}

public class RunnableB implements Runnable{
    private final Data data;

    public RunnableB(Data data){
        this.data = data;
    }

    @Override
    public void run(){
        data.add();
        System.out.println("RunnableB：" + data.a);
    }
}
```

4. 将这些Runnable对象作为一个内部类,将共享数据作为成员变量

https://www.cnblogs.com/pony1223/p/9256224.html

#### Optional类

Optional 类是一个可以为null的容器对象。如果值存在则isPresent()方法会返回true，调用get()方法会返回该对象

Optional 是个容器：它可以保存类型T的值，或者仅仅保存null。Optional提供很多有用的方法，这样就不用显式进行空值检测

Optional 类的引入很好的解决空指针异常

```
public class OptionalTest {
    public static void main(String[] args){
        
        System.out.println(sum(getNullInteger(), getNotNullInteger()));
    }

    private static Integer sum(Integer a, Integer b){
        Integer value1 = Optional.ofNullable(a).orElse(0);
        Integer value2 = Optional.ofNullable(b).orElse(0);
        return Optional.of(value1 + value2).orElse(0);
    }

    private static Integer getNullInteger(){
        return null;
    }

    private static Integer getNotNullInteger(){
        return 10;
    }
}
```

注意：

**Optional不能序列化，不能作为类的字段(field)**

**Optional不适合作为方法参数**

**推荐Optional作为函数返回值**

**如果你想返回null，请停下来想一想，这个地方是否更应该抛出一个异常**

https://www.cnblogs.com/woshimrf/p/java-optional-usage-note.html

#### 函数式接口

函数式接口(Functional Interface)就是一个**有且仅有一个抽象方法，但是可以有多个非抽象方法的接口**

函数式接口可以被隐式转换为 lambda 表达式

定义了一个函数式接口如下：

```
@FunctionalInterface
interface GreetingService 
{
    void sayMessage(String message);
}
```

JDK 1.8 之前已有的函数式接口:

* java.lang.Runnable
* java.util.concurrent.Callable
* java.security.PrivilegedAction
* java.util.Comparator
* java.io.FileFilter
* java.nio.file.PathMatcher
* java.lang.reflect.InvocationHandler
* java.beans.PropertyChangeListener
* java.awt.event.ActionListener
* javax.swing.event.ChangeListener

JDK 1.8 新增加的函数接口：

* java.util.function

#### Lambda表达式

Lambda 表达式，也可称为闭包，Lambda 允许把函数作为一个方法的参数（函数作为参数传递进方法中）

lambda 表达式的语法格式如下：

```
(parameters) -> expression
或
(parameters) ->{ statements; }
```

以下是lambda表达式的重要特征：

* 可选类型声明：不需要声明参数类型，编译器可以统一识别参数值
* 可选的参数圆括号：一个参数无需定义圆括号，但多个参数需要定义圆括号
* 可选的大括号：如果主体包含了一个语句，就不需要使用大括号
* 可选的返回关键字：如果主体只有一个表达式返回值则编译器会自动返回值，大括号需要指定明表达式返回了一个数值

```
// 1. 不需要参数,返回值为 5  
() -> 5  
  
// 2. 接收一个参数(数字类型),返回其2倍的值  
x -> 2 * x  
  
// 3. 接受2个参数(数字),并返回他们的差值  
(x, y) -> x – y  
  
// 4. 接收2个int型整数,返回他们的和  
(int x, int y) -> x + y  
  
// 5. 接受一个 string 对象,并在控制台打印,不返回任何值(看起来像是返回void)  
(String s) -> System.out.print(s)
```

**Lambda表达式主要用来定义接口，此接口要求必须是函数式接口(@FunctionalInterface)，接口中有且仅有一个需要被重写的抽象方法，如果其中有两个方法则lambda表达式会编译错误**

```
public class LambdaTest {
    public static void main(String[] args){
        LambdaTest tester = new LambdaTest();

        // 类型声明
        MathOperation addition = (int a, int b) -> a + b;

        // 不用类型声明
        MathOperation subtraction = (a, b) -> a - b;

        // 大括号中的返回语句
        MathOperation multiplication = (int a, int b) -> { return a * b; };

        // 没有大括号及返回语句
        MathOperation division = (int a, int b) -> a / b;

        System.out.println("10 + 5 = " + addition.operation(10, 5));
        System.out.println("10 - 5 = " + addition.operation(10, 5));
        System.out.println("10 x 5 = " + addition.operation(10, 5));
        System.out.println("10 / 5 = " + addition.operation(10, 5));

        // 不用括号
        GreetingService greetService1 = message ->
                System.out.println("Hello " + message);

        // 用括号
        GreetingService greetService2 = (message) ->
                System.out.println("Hello " + message);

        greetService1.sayMessage("Runoob");
        greetService2.sayMessage("Google");
    }

    interface MathOperation {
        int operation(int a, int b);
    }

    interface GreetingService {
        void sayMessage(String message);
    }

    private int operate(int a, int b, MathOperation mathOperation){
        return mathOperation.operation(a, b);
    }
}
```

##### 变量作用域

lambda 表达式只能引用标记了 final 的外层局部变量，这就是说不能在lambda 内部修改定义在域外的局部变量，否则会编译错误

```
public class LambdaTest {
    final static String salutation = "Hello! ";

    public static void main(String[] args){
        final String name = "tom";
        GreetingService greetService1 = () ->
                System.out.println(salutation + name);
        greetService1.sayMessage();
    }

    interface GreetingService {
        void sayMessage();
    }
}
```

##### lambda实现Runnable接口

```
new Thread(() -> System.out.println("Hello world !")).start();  
```

#### 方法引用

有些情况下，用Lambda表达式仅仅是调用一些已经存在的方法，除了调用动作外，没有其他任何多余的动作，在这种情况下，我们倾向于通过方法名来调用它，而Lambda表达式可以帮助我们实现这一要求，它使得Lambda在调用那些已经拥有方法名的方法的代码更简洁、更容易理解。方法引用可以理解为Lambda表达式的另外一种表现形式

| 类型 | 语法 | 对应的Lambda表达式 |
| :----: | :----: | :----: |
| 静态方法引用 | 类名::staticMethod | (args) -> 类名.staticMethod(args) |
| 实例方法引用 | inst::instMethod | (args) -> inst.instMethod(args) |
| 对象方法引用 | 类名::instMethod | (inst,args) -> 类名.instMethod(args) |
| 构建方法引用 | 类名::new | (args) -> new 类名(args) |

```
public static void main(String args[]){
   List<String> names = new ArrayList();
     
   names.add("Google");
   names.add("Runoob");
   names.add("Taobao");
   names.add("Baidu");
   names.add("Sina");
     
   names.forEach(System.out::println);
}
```

#### 默认方法

Java 8 新增了接口的默认方法。简单说，默认方法就是接口可以有实现方法，而且不需要实现类去实现其方法。只需在方法名前面加个 default 关键字即可实现默认方法

当需要修改接口时候，需要修改全部实现该接口的类，是没法在给接口添加新方法的同时不影响已有的实现。所以引进的默认方法。目的是为了解决接口的修改与现有的实现不兼容的问题

默认方法语法格式如下：

```
public interface Vehicle {
   default void print(){
      System.out.println("我是一辆车!");
   }
}
```

#### Stream

Java 8 API添加了一个新的抽象称为流Stream，可以让你以一种声明的方式处理数据。Stream使用一种类似用SQL语句从数据库查询数据的直观方式来提供一种对Java集合运算和表达的高阶抽象。这种风格将要处理的元素集合看作一种流，流在管道中传输，并且可以在管道的节点上进行处理，比如筛选，排序，聚合等。元素流在管道中经过中间操作（intermediate operation）的处理，最后由最终操作(terminal operation)得到前面处理的结果

```
+--------------------+       +------+   +------+   +---+   +-------+
| stream of elements +-----> |filter+-> |sorted+-> |map+-> |collect|
+--------------------+       +------+   +------+   +---+   +-------+
```

Stream（流）是一个来自数据源的元素队列并持聚合操作

* 元素是特定类型的对象，形成一个队列。 Java中的Stream并不会存储元素，而是按需计算
* 数据源 流的来源。 可以是集合，数组，I/O channel，产生器generator等
* 聚合操作 类似SQL语句一样的操作， 比如filter, map, reduce, find, match, sorted等

和以前的Collection操作不同，Stream操作还有两个基础的特征：

* Pipelining：中间操作都会返回流对象本身。这样多个操作可以串联成一个管道，如同流式风格（fluent style）。这样做可以对操作进行优化，比如延迟执行(laziness)和短路(short-circuiting)
* 内部迭代：以前对集合遍历都是通过Iterator或者For-Each的方式，显式的在集合外部进行迭代，这叫做外部迭代。Stream提供了内部迭代的方式，通过访问者模式(Visitor)实现

##### 生成流

在 Java 8 中, 集合接口有两个方法来生成流：

* stream() − 为集合创建串行流
* parallelStream() − 为集合创建并行流

```
List<String> strings = Arrays.asList("abc", "", "bc", "efg", "abcd","", "jkl");
List<String> filtered = strings.stream().filter(string -> !string.isEmpty()).collect(Collectors.toList());
```

```
List<String> strings = Arrays.asList("abc", "", "bc", "efg", "abcd","", "jkl");
long count = strings.parallelStream().filter(string -> string.isEmpty()).count();
```

##### 回调函数

当程序跑起来时，一般情况下，应用程序（application program）会时常通过API调用库里所预先备好的函数。但是有些库函数（library function）却要求应用先传给它一个函数，好在合适的时候调用，以完成目标任务。这个被传入的、后又被调用的函数就称为回调函数（callback function）

https://www.zhihu.com/question/19801131

#### 泛型

泛型类：是在实例化类的时候指明泛型的具体类型

泛型方法：是在调用方法的时候指明泛型的具体类型

泛型类中的类型参数与泛型方法中的类型参数是没有相应的联系的，泛型方法始终以自己定义的类型参数为准，为了避免混淆，如果在一个泛型类中存在泛型方法，那么两者的类型参数最好不要同名

**jdk1.7之前要求实例化的时候需要指明泛型。而1.7以及以后的版本中可以省略**

```
    public static void main(String[] args) {
        Test1<String> t = new Test1();
        t.testMethod1(1);

    }
    public static class Test1<U>{

        public <U> void testMethod1(U u){
            System.out.println("t type is:" + u.getClass().getName());
        }
    }
```

```
    public static void main(String[] args) {
        Test1<String> t = new Test1();
        t.testMethod1(0, "a string");

    }

    public static class Test1<U>{

        public <T> void testMethod1(T t, U u){
            System.out.println("t type is:" + t.getClass().getName());
            System.out.println("u type is:" + u.getClass().getName());
        }
    }
```

https://segmentfault.com/a/1190000005337789
https://blog.csdn.net/briblue/article/details/76736356
https://zhidao.baidu.com/question/498912887372724004.html
https://blog.csdn.net/Mrzhang__/article/details/53230674

```java
class Base{}

class Sub extends Base{}

Sub sub = new Sub();
Base base = sub;

###############

List<Sub> lsub = new ArrayList<>();
List<Base> lbase = lsub;
```

类之间支持协变，泛型不支持协变，需要通配符

#### ...

https://blog.csdn.net/xxdw1992/article/details/78709281

