###基础语法
####注释

```
单行：//
多行： 
/*
* 这是一行注释
* 多行注释
*/
```

####包
#####定义包
```
package com.runoob
class HelloWorld
```

第二种：可以在一个文件中定义多个包
```
package com.runoob {
  class HelloWorld 
}
```

#####引用包
* Scala 使用 import 关键字引用包
* import语句可以出现在任何地方，而不是只能在文件顶部
* import的效果从开始延伸到语句块的结束
* 如果想要引入包中的几个成员，可以使用selector（选取器）：

```
import java.awt.Color  // 引入Color
 
import java.awt._  // 引入包内所有成员

import java.awt.{Color, Font}
 
// 重命名成员
import java.util.{HashMap => JavaHashMap}
 
// 隐藏成员
import java.util.{HashMap => _, _} // 引入了util包的所有成员，但是HashMap被隐藏了
```

Scala 默认会导入两个包、scala.Predef 对象以及它们相应的类和成员。只用类名就可以从这些预导入的包中引用相应的类。Scala 按照顺序导入下面的包和类:

* java.lang
* scala
* scala.Predef

Predef 对象中包含了类型、隐式转换以及在 Scala 中常用的一些方法。Predef 对象还提供了一些类型的别名，如 scala.collection.immutable.Set 和 scala.collection.immutable.Map。因此，当使用 Set 或者 Map 的时候，实际使用的 是Predef中对它们的定义，它们分别指向它们在scala.collection.immutable包中的定义

####注意事项
* 区分大小写：大小写敏感
* 类名：对于所有的类名的第一个字母要大写，如果需要使用几个单词来构成一个类的名称，每个单词的第一个字母要大写
* 方法名称：所有的方法名称的第一个字母用小写，如果若干单词被用于构成方法的名称，则每个单词的第一个字母应大写
* 程序文件名：程序文件的名称应该与对象名称完全匹配
* def main(args: Array[String])：Scala程序从main()方法开始处理，这是每一个Scala程序的强制程序入口部分
* Scala能智能地推断出一个语句或者表达式是否是完整的，所以Scala语句末尾的分号 ; 是可选的，如果想要在同一行上写多个语句或者表达式，则必须在末尾放置一个分号，否则可能会出问题

###数据类型

| 类型 | 字面量 |
| :----: | :----: |
| 布尔 | true&false |
| 字符 | ' |
| 字符串 | " |
| 多行字符串 | """ |

####变量类型推断
与任何静态类型的编程语言一样，Scala在**编译时**验证对象的类型。同时，它不要求明确标注显而易见的类型，它可以进行类型推断。无论是对于简单类型还是泛型，都可以使用类型推断。但是在Scala中，有几个地方需要显式地输入类型声明。在以下几种情况下，必须要显式地指定类型：

* 当定义没有初始值的类字段时
* 当定义函数或方法的参数时
* 当定义函数或方法的返回类型，仅当我们使用显式的return语句或者使用递归时
* 当将变量定义为另一种类型，而不是被直接推断出的类型时，如 val frequency: Double = 1

除了上述这些情况之外，类型信息都是可选的

####返回值类型推断
除了推断变量的类型，Scala还试图推断函数和方法的返回值类型。不过，Scala是否自动推断取决于你如何定义函数。只有当你使用等号(=)将方法的声明和方法的主体部分区分开时，Scala的返回值类型推断才会生效。否则，该方法将会被视为返回一个Unit。所有函数和方法的返回值类型都是在编译时确定的

####基础类型
#####Any类型
Scala的Any类型是所有类型的超类型，Any类型可以作为任意类型对象的一个通用引用。Any是一个抽象类。Any类型的直接后裔是AnyVal和AnyRef类型  
AnyVal是Scala中所有值类型(如Int、Double等)的基础类型，并映射到了Java中的原始类型  
AnyRef是所有引用类型的基础类型

#####Nothing类型
在Scala中，Nothing是一切类型的子类型。Nothing类型在Scala的类型验证机制的支持上意义重大，Scala的类型推断尽可能地确定表达式和方法的类型。如果推断出的类型太过宽泛，则不利于类型验证。Nothing类型这时候就派上用场了，通过作为所有类型的子类型，它使类型推断过程得以顺利进行。因为它是所有类型的子类型，所以它可以替代任何东西。Nothing是抽象的，因此在运行时永远都不会得到一个真正的Nothing实例。它是一个纯粹的辅助类型，用于类型推断以及类型验证

#####Option类型
Scala进一步指定了可能的不存在性。使用Scala的Option[T]，可以进行有意图的编程，并指定打算不返回结果。如果显式指定类型为Option[T]，Scala强制检查实例是否不存在，这是在编译时强制执行的

#####Either类型
如果希望从一个函数中返回两种不同类型的值之一，可以使用Scala的Either类型。Either类型有两种值:左值(通常被认为是错误)和右值(通常被认为是正确的或者符合预期的值)。使用单例对象Right将其包装到Either的右值中，使用单例对象Left将其作为Either类型的左值返回
```
def compute(input: Int) = if (input > 0)
  Right(math.sqrt(input)) else
  Left("Error computing, invalid input")
```

####富封装器(rich wrapper)

* scala没有java中的原生类型，数据类型都是对象

###变量
####声明
```
var VariableName : DataType [=  Initial Value]
或
val VariableName : DataType [=  Initial Value]

var xmax, ymax = 100
```

####注意事项
* 在Scala中声明变量和常量不一定要指明数据类型，在没有指明数据类型的情况下，其数据类型是通过变量或常量的初始值推断出来的。所以，如果在没有指明数据类型的情况下声明变量或常量必须要给出其初始值，否则将会报错
* Scala不支持多重赋值，因为赋值操作符被解释成方法，返回值为Unit
* 和Java不同，在Scala中，不论类型是什么，==表示都是基于值的比较，这是在类 Any(Scala 中所有类型都衍生自 Any)中实现了 final 的==()方法保证的。如果要比较引用，可以使用 Scala 中的 eq()方法

```
val str1 = new String("String")
val str2 = new String("String")

println(str1 == str2)
println(str1 eq str2)
```

###访问修饰符
#####Private
用**private**关键字修饰，带有此标记的成员仅在包含了成员定义的类、包含了成员定义的类的内部类、包含了成员定义的类的对象、包含了成员定义的类的伴生对象内部可见
#####Protected
允许保护成员在定义了该成员的类的子类**内部**被访问
```
class Vehicle {
  protected def checkEngine() {}
}

class Car extends Vehicle {
  def tow() {
    checkEngine() // 编译正确
  }
  def tow(car: Car) {
    car.checkEngine() // 编译正确
  }
  def tow(vehicle: Vehicle) {
    vehicle.checkEngine() // 编译错误
  }
}

class GasStation {
  def fillGas(vehicle: Vehicle,car: Car) {
    car.checkEngine() // 编译错误
    vehicle.checkEngine() // 编译错误 
}
```
#####Public
如果没有指定任何的修饰符，则默认为**public**，所以无须显式使用 public 关键字。这样的成员在任何地方都可以被访问
#####作用域保护
访问修饰符可以通过使用限定词强调。格式为:
```
private[x] 
或 
protected[x]

//Scala实用指南的问题

这里的x指代某个所属的包、类、单例对象或this。如果写成private[x],读作"这个成员除了对[…]中的类或[…]中的包中的类及它们的  
伴生对像可见外，对其它所有类都是private

这种技巧在横跨了若干包的大型项目中非常有用，它允许你定义一些在你项目的若干子包中可见但对于项目外部的客户却始终不可见的东西
```

###循环
#####while
```
while(condition)
{
   statement(s);
}
```
#####do...while
```
do {
   statement(s);
} while( condition );
```
#####for
```
for( var x <- Range by 2){
   statement(s);
}
Range 可以是一个数字区间表示 i to j ，或者 i until j，to两端为闭区间，until为左闭右开区间  
to和until被解释成to()和until()方法  
左箭头 <- 用于为变量 x 赋值，默认为val类型  
by是步长

函数式风格：
(1 to 3).foreach(i => print(s"$i,"))
```
for循环区间：可以使用分号(;)来设置多个区间，它将迭代给定区间所有的可能值
```
for( a <- 1 to 3; b <- 1 to 3){
         println( "Value of a: " + a );
         println( "Value of b: " + b );
      }

Value of a: 1
Value of b: 1
Value of a: 1
Value of b: 2
Value of a: 1
Value of b: 3
Value of a: 2
Value of b: 1
Value of a: 2
Value of b: 2
Value of a: 2
Value of b: 3
Value of a: 3
Value of b: 1
Value of a: 3
Value of b: 2
Value of a: 3
Value of b: 3
```
for循环集合
```
for( x <- List ){
   statement(s);
}
```
for循环过滤：可以使用一个或多个 if 语句来过滤一些元素
```
for( var x <- List
      if condition1; if condition2...){
   statement(s);
}
```
for循环返回值
```
var retVal = for{ var x <- List
     if condition1; if condition2...
}yield x*2

大括号中用于保存变量和条件，yield 会把当前的元素记下来，保存在集合中，循环结束后将返回该集合
注意：
针对每一次 for 循环的迭代, yield 会产生一个值，被循环记录下来
当循环结束后, 会返回所有 yield 的值组成的集合
返回集合的类型与被遍历的集合类型是一致的

val doubleEven = for (i <- 1 to 10; if i % 2 == 0) yield i * 2
/*
表达式像是对一个值的集合进行SQL查询，这在函数式编程中称为列表推导(list comprehension)
*/

//可以将分号替换成换行符，括号替换成大括号
for {
  i <- 1 to 10
  if i % 2 == 0
} yield i * 2
```
#####break和continue
Scala语言中默认是没有break和continue语句，但是可以Scala2.8版本后可以使用另外一种方式来实现break和continue语句
```
import scala.util.control.Breaks._

#break
breakable(
    for(i<-0 until 10) {
      println(i)
      if(i==5){
        break()
      }
    }
  )

#continue
for(i<-0 until 10){
      breakable{
      if(i==3||i==6) {
        break
      }
      println(i)
      }
    }

当在循环中使用 break 语句，在执行到该语句时，就会中断循环并执行循环体之后的代码块
{}和()疑问
```
###方法与函数
####方法与函数的区别
#####1.函数可作为一个参数传入到方法中，而方法不行，必须先将方法转换成函数。有两种方法可以将方法转换成函数：
```
//方法
def method (a:Int,b:Int):Int = a+b

//在方法名称后面紧跟一个空格和下划线告诉编译器将方法m转换成函数，而不是要调用这个方法
var fun1 = method _

//也可以显示地告诉编译器需要将方法转换成函数
var fun2:(Int,Int)=>Int = method
```
**通常情况下编译器会自动将方法转换成函数，例如在一个应该传入函数参数的地方传入了一个方法，编译器会自动将传入的方法转换成函数。在期望出现函数的地方提供了一个方法的话，该方法就会自动被转换成函数。该行为被称为ETA展开(ETA expansion)**
#####2.函数必须要有参数列表，而方法可以没有参数列表
#####3.在Scala中操作符被解释成方法，所以技术上说，Scala 没有操作符，操作符重载其实就是重载方法
* 前缀操作符：op obj 被解释称 obj.op
* 中缀操作符：obj1 op obj2 被解释称 obj1.op(obj2)
* 后缀操作符：obj op 被解释称 obj.op

虽然Scala没有操作符，但并不能免去处理操作符优先级的需要。Scala通过方法的第一个字符用来决定它们的优先级。如果在一个表达式中两个字符的优先级相同，那么在左边的方法优先级更高。下面是第一个字母的优先级从低到高的列表：

* |
* ^
* &
* <>
* =!
* :
* +-
* */ %
* 所有其他的特殊字符

```
val t1 = new target
val t2 = new target
val t3 = new target

t1 + t2 * t3

t2 * t3 + t1

t1.+(t2.*(t3))

class target {
  def +(op: target): target = {
    println("Calling +")
    new target
  }
  def *(op: target): target = {
    println("Calling *")
    new target
  }
}
```

当有一系列的相同优先级的操作符时，操作符的结合性决定了它们从左到右求值还是从右到左求值，在Scala中操作符都是左结合的，除了:

* 以冒号:结尾的操作符
* 赋值操作符

如果操作符（方法名）以冒号(:)结尾，那么调用的目标是该操作符后面的实例
```
class Cow {
  def ^(moon: Moon): Unit = println("Cow jumped over the moon")
}
class Moon {
  def ^:(cow: Cow): Unit = println("This cow jumped over the moon too")
}

val cow = new Cow
val moon = new Moon
cow ^ moon
cow ^: moon
```

#####4.对于Scala中的方法与函数有两套说法：一种是def语句定义的称作方法，val语句定义的称作匿名方法，也就是函数；另一种是def语句定义的称作函数，val语句定义的称作匿名函数。本文采用第二种  
####函数声明
```
def functionName ([参数列表]) : [return type] = {
   function body
   return [expr]
}

def function1 { Math.sqrt(4) }
def function2 = { Math.sqrt(4) }
def function3 = Math.sqrt(4)
def function4: Double = { Math.sqrt(4) }

def functionName ([参数列表]) : [return type]

如果不写等于号和方法主体，那么方法会被隐式声明为抽象(abstract)，包含它的类型于是也是一个抽象类型

函数体如果只有一行简单表达式或者复合表达式，可省略 {}

如果没有参数列表，可省略 ()

函数最后一段会被自动return，且编译器会自动推断返回值类型;
但如果显示写出return，则必须写明返回值类型

即使选择写明返回值类型，也最好避免显式的return命令

无须加入显式的return语句可以简化代码，尤其是在将一个闭包传递为方法参数时
```
####函数调用
```
//括号和点号也是可选的
functionName( 参数列表 )
或
[instance.]functionName( 参数列表 )
或
instance functionName ( 参数列表 )

def main(args: Array[String]): Unit = {
  val t = new test_class(2)
  t add 2
  t super_add (3,3)
  t call_god ()
  t call_devil
}

class test_class(val m: Int) {
  var num: Int = m
  def add(a: Int) = {
    num += a
    println(num)
  }

  def super_add(a: Int, b: Int) = {
    num += a
    num += b
    println(num)
  }

  def call_god() = println("god")

  def call_devil = println("devil")
}
```
####传值调用和传名调用
* 传值调用（call-by-value）：先计算参数表达式的值，再应用到函数内部
* 传名调用（call-by-name）：将未计算的参数表达式直接应用到函数内部  

在变量名和变量类型之间使用 => 符号来设置传名调用  

在进入函数内部前，传值调用方式就已经将参数表达式的值计算完毕，而传名调用是在函数内部进行参数表达式的值计算的。这就造成了一种现象，每次使用传名调用时，解释器都会计算一次表达式的值

```
object helloworld {

  var a = 10

  def main(args: Array[String]): Unit = {
    call_by_value(argument_fun(1,1))
    call_by_name(argument_fun(1,1))
  }

  def argument_fun(m:Int,n:Int): Int = {
    a -= (m + n)
    a
  }

  def call_by_value(fun: Int): Unit = {
    for (i <- 1 to 3) {
      println("第" + i + "次调用")
      println(fun)
    }
  }

  def call_by_name(fun: => Int): Unit = {
    for (i <- 1 to 3) {
      println("第" + i + "次调用")
      println(fun)
    }
  }
}
```

####指定函数参数名
一般情况下函数调用参数，就按照函数定义时的参数顺序一个个传递。但是也可以通过指定函数参数名，并且不需要按照顺序向函数传递参数

```
//指定参数名可不按顺讯传递参数
def main(args: Array[String]): Unit = {
  parameter(b = 1, a = 2)
}
def parameter(a: Int, b: Int) = println("parameter")
```

* 对于所有没有默认值的参数，必须要提供参数的值
* 对于那些有默认值的参数，可以选择性地使用命名参数传值
* 一个参数最多只能传值一次
* 在重载基类的方法时，应该保持参数名字的一致性。如果不这样做，编译器就会优先
使用基类中的参数名，就可能会违背最初的目的  
* 如果有多个重载的方法，它们的参数名一样，但是参数类型不同，那么函数调用就很
有可能产生歧义。在这种情况下，编译器会严格报错，就不得不切换回基于位置的参数形式

####可变参数
Scala 允许指明函数的最后一个参数可以是重复的，即不需要指定函数参数的个数，可以向函数传入可变长度参数列表。Scala 通过在参数的类型之后放一个星号来设置可变参数(可重复的参数)  

当参数的类型使用一个尾随的星号声明时，Scala会将参数定义成该类型的数组，但可变参数不能将数组作为参数值传入

```
def function(input: Int*): Unit = println(input.getClass)

//例1
def printStrings( args:String* ) = {
      var i : Int = 0;
      for( arg <- args ){
         println("Arg value[" + i + "] = " + arg );
         i = i + 1;
      }
   }

//例2
def max(values: Int*) = values.foldLeft(values(0)) { Math.max }
def max(values: Int*) = values.foldLeft(values(0)) ({Math.max})
def max(values: Int*) = values.foldLeft(values(0)) (Math.max)

max(8, 2, 3)
max(2, 5, 3, 7, 1, 6)

//例3
val lst = List(20, 30, 60, 90)
val rs = lst.foldLeft(0)((b, a) => {
  b + a
})
```

####默认参数值
Scala 可以为函数参数指定默认参数值，使用了默认参数，在调用函数的过程中可以不需要传递参数，这时函数就会调用它的默认参数值，如果传递了参数，则传递值会取代默认值。一个函数包含默认参数，同时包含普通参数时，无默认值的参数在前，默认参数在后  

对于多参数的方法，如果对于其中一个参数，选择使用它的默认值，就不得不让这 个参数后面的所有参数都使用默认值。这种限制的原因在于，被省去的参数所使 用的默认值是由参数的位置决定的，可使用指定函数参数名打破这一限制
```
/*
对于有默认值的多参数方法，只要传递参数值时指定名称，那么(在省略某个参数后)接下来的参数都必须使用默认值的限制就不存在了
*/
def main(args: Array[String]): Unit = {
  default(b = 2)
}

def default(a: Int = 1, b: Int) = println("default")
```

####高阶函数
可以将其他函数作为参数的函数就被称为高阶函数（Higher-Order Function）。Scala 中允许使用高阶函数, 高阶函数可以使用其他函数作为参数，或者使用函数作为输出结果
```
  var a = 10

  def main(args: Array[String]): Unit = {
    Higher_Order_Function(argument_fun)
  }

  def argument_fun(m:Int,n:Int): Int = {
    a -= (m + n)
    a
  }
  def Higher_Order_Function(fun:(Int,Int)=>Int): Unit = {
      println(fun(1,2))
  }

  def totalResultOverRange(number: Int, codeBlock: Int => Int) = {
    var result = 0
    for (i <- 1 to number) {
      result += codeBlock(i)
    }
    result
  }

  //第二个参数是一个匿名的即时函数，即一个没有名称只有参数和实现的函数
  println(totalResultOverRange(11, i => i))
  println(totalResultOverRange(11, i => if (i % 2 == 0) i else 0))
  println(totalResultOverRange(11, i => if (i % 2 == 0) 0 else i))

PS：高阶函数设置函数形参的语法和传名调用很相似，但传名调用传递的是值，而高阶函数的函数形参传递的是完整的函数代码
```

####函数嵌套
可以在 Scala 函数内定义函数，定义在函数内的函数称之为局部函数或者内嵌函数

####匿名函数
箭头左边是参数列表，右边是函数体。在 Scala 中，匿名函数实际上就是对象
```
/*
在符号=>左边指定了函数的预期输入类型，在其右边指定了函数的预期输出类型。“输入=>输出”
这种语法形式旨在帮助我们将函数的作用视为接收输入并转换为输出且不产生任何副作用的过程
*/
var|val 变量名称 [:] [(参数类型列表)=>return type] = (参数列表) => [return type] {
   function body
   return [expr]
}

var inc = (x:Int) => x+1
或
var inc = (x:Int) => Int {x+1}
或
var inc:Int=>Int = (x:Int) => Int {x+1}

def inject(arr: Array[Int], initial: Int, operation: (Int, Int) => Int) = {
  var carryOver = initial
  arr.foreach(element => carryOver = operation(carryOver, element))
  carryOver
}

val array = Array(2, 3, 5, 1, 6, 4)
val sum = inject(array, 0, (carry, elem) => carry + elem)
val max = inject(array, Integer.MIN_VALUE, (carry, elem) => Math.max(carry, elem))

//内置foldLeft()方法，实现相同的效果
val sum = array.foldLeft(0) { (sum, elem) => sum + elem }
val max = array.foldLeft(Integer.MIN_VALUE) { (large, elem) =>
Math.max(large, elem) }

//foldLeft()方法有一个等效的/:操作符
val sum = (0 /: array) ((sum, elem) => sum + elem)
val max = (Integer.MIN_VALUE /: array) { (large, elem) => Math.max(large, elem) }
```
https://www.cnblogs.com/noyouth/p/12818054.html

####偏应用函数
调用一个函数，实际上是在一些参数上应用这个函数。如果传递了所有期望的参数，就是对这个函数的完整应用，就能得到这次应用或者调用的结果。如果传递的参数比所要求的参数少，就会得到另外一个函数。这个函数被称为偏应用函数。偏应用函数是一种表达式，你不需要提供函数需要的所有参数，只需要提供部分，或不提供所需参数。使用下划线(_)替换缺失的参数列表，并把这个新的函数值的索引的赋给变量
```
def add(x:Int,y:Int,z:Int) = x+y+z

def addX = add(1,_:Int,_:Int)
def addXAndY = add(10,100,_:Int)
def addZ = add(_:Int,_:Int,10)

def log(date: Date, message: String): Unit = {
  //...
  println(s"$date ---- $message") 
}

val date = new Date(1420095600000L)
val logWithDateBound = log(date, _: String)
logWithDateBound("message1")
logWithDateBound("message2")
logWithDateBound("message3")
```

当创建一个偏应用函数的时候，Scala在内部会创建一个带有特殊apply()方法的新类。在调用偏应用函数的时候，实际上是在调用apply()方法

https://blog.csdn.net/hellojoy/article/details/81062068  
https://www.jianshu.com/p/c198bea5c34a  
偏函数、偏应用函数、柯里化区别

####函数柯里化(Currying)
Scala允许函数定义多组参数列表，每组写在一对圆括号里。当用少于定义数目的参数来调用函数的时候，将返回一个以余下的参数列表为参数的函数，这个过程叫柯里化(Currying)。Scala中的柯里化(currying)会把接收多个参数的函数转化为接收多个参数列表的函数
```
//原始函数
def add(x:Int,y:Int,z:Int):Int=x+y+z

//柯里化函数
def add1_1(x:Int,y:Int):Int=>Int=(z:Int)=>x+y+z
def add1_2(x:Int,y:Int)(z:Int):Int=x+y+z

def add2_1(x:Int):(Int,Int)=>Int=(y:Int,z:Int)=>x+y+z
def add2_2(x:Int)(y:Int,z:Int):Int=x+y+z

def add3_1(x:Int):Int=>Int=>Int=(y:Int)=>(z:Int)=>x+y+z
def add3_2(x:Int)(y:Int):Int=>Int=(z:Int)=>x+y+z
def add3_3(x:Int)(y:Int)(z:Int):Int=x+y+z 

//原始函数
def foo(a: Int, b: Int, c: Int) = {}

//柯里化函数
def foo(a: Int)(b: Int)(c: Int) {}

//调用柯里化函数
foo(1)(2)(3)
foo(1){2}{3}
foo{1}{2}{3}
```

####参数占位符
如果在匿名函数中出现只引用过一次的参数时，可以用下划线(_)来表示这个匿名函数只引用一次的参数
```
val negativeNumberExists1 = arr.exists { elem => elem < 0 }
val negativeNumberExists2 = arr.exists { _ < 0 }

//多个_可通过位置对应
val total = (0 /: arr) { (sum, elem) => sum + elem }
val total = (0 /: arr) { _ + _ }
```

####参数路由
_不仅能表示单个参数，也能表示整个参数列表
```
val largest =
(Integer.MIN_VALUE /: arr) { (carry, elem) => Math.max(carry, elem) }

val largest = (Integer.MIN_VALUE /: arr) { Math.max(_, _) }

val largest = (Integer.MIN_VALUE /: arr) { Math.max _ }

val largest = (Integer.MIN_VALUE /: arr) { Math.max }
/*
编译器会检查方法/:的函数签名，第二个参数列表接收一个匿名函数，编译器会要求这个匿名函数接收两个参数，
尽管没有指定max()方法的参数，但是编译器也会知道这个方法接收两个参数，编译器让函数签名中的两个参数
和max()方法的两个参数对号入座，并最终执行正确的参数路由
*/
```

####复用匿名函数
可以创建对匿名函数的引用，然后复用它们
```
val calculator = { input: Int => println(s"calc with $input"); input }
```
为了达到代码复用的目的，还有一种更加符合习惯的方法。**可以在预期接收匿名函数的地方传入一个常规函数**，没有必要把匿名函数赋值给变量，直接传递函数名就可以了，这是复用函数值的一种方式
```
class Equipment(val routine: Int => Int) {
  def simulate(input: Int): Int = {
    print("Running simulation...")
    routine(input)
  }
}

def calculator(input: Int) = { println(s"calc with $input"); input }

val equipment1 = new Equipment(calculator) 
val equipment2 = new Equipment(calculator)
```

###闭包
可以创建带有未绑定变量的代码块，这些变量可以绑定到或者捕获作用域和参数列表之外的变量，这样的代码块被称之为闭包。闭包是一个函数，返回值依赖于声明在函数外部的一个或多个变量。闭包通常来讲可以简单的认为是可以访问一个函数里面局部变量的另外一个函数，比如柯里化：柯里化的前提是Scala支持闭包，才会有柯里化
```
var factor = 3  
val multiplier = (i:Int) => i * factor

def loopThrough(number: Int)(closure: Int => Unit): Unit = {
  for (i <- 1 to number) {
    closure(i)
  }
}

var result = 0
val addIt = { value: Int =>
  result += value
}

loopThrough(10) { elem => addIt(elem) } 
println(s"Total of values from 1 to 10 is $result")

result = 0

loopThrough(5) { addIt }
println(s"Total of values from 1 to 5 is $result")

var product = 1
loopThrough(5) { product *= _ }
println(s"Product of values from 1 to 5 is $product")
```

###字符串
在Scala中，字符串的类型实际上是Java String，Scala本身没有String类。Scala 能够自动将 String 转化为 scala.runtime.RichString。String是一个不可变的对象，所以该对象不可被修改。这就意味着如果修改字符串就会产生一个新的字符串对象。但其他对象，如数组就是可变的对象
####创建字符串
```
var greeting:String = "Hello World!"
```
如果需要创建一个可以修改的字符串，可以使用String Builder类
```
val buf = new StringBuilder
    buf += 'a'
    buf ++= "bcdef"
    println( "buf is : " + buf.toString )
```

####字符串连接
String类中使用concat()方法来连接两个字符串，同样也可以使用加号(+)来连接
```
string1.concat(string2)
或
string1+string2
```

####创建格式化字符串
String类中可以使用printf()方法来格式化字符串并输出，String format()方法可以返回String对象而不是PrintStream对象。
```
var floatVar = 12.456
var intVar = 2000
var stringVar = "Hello World!"
var fs = printf("浮点型变量为 " +
                   "%f, 整型变量为 %d, 字符串为 " +
                   " %s", floatVar, intVar, stringVar)
println(fs)
```

####字符串插值
#####s字符串插值器
解析字符串变量
```
val name = "Tom"
println(s"His name is $name")
println(s"His name is ${name}my")
println(s"23 + 78 = ${23+78}")

//字符串变量是不可变的
//如果字符串中有$符号，那么还可以被用作转义符
val discount = 10
var price = 100
val totalPrice =
  s"The amount after discount is $$${price * (1 - discount / 100.0)}"
println (totalPrice)
price = 50
println(totalPrice)
```

#####f字符串插值器
格式化的输出，变量名后用%指定格式，可以用一个额外的%转义已有的百分号，如果没有指定格式，那么f插值器将会假定格式是%s，也就是说直接转化为字符串
```
val num = 2.345
println(f"The height is $num%2.2f")
println(f"The height is $num%2.5f")
```

#####raw插值器
字符串原封原样的输出，屏蔽控制效果
```
println(raw"/t/n")
```

####多行原始字符串
在Scala中创建一个跨行的字符串非常简单，只要将多行的字符串放在一对3个双引号之中("""...""")就可以了。将3个双引号中间的内容保持原样，在Scala中这种字符串被称为原始字符串。在创建正则表达式的时候，原始字符串十分有用
```
val str = """In his famous inaugural speech, John F. Kennedy said
"And so, my fellow Americans: ask not what your country can do for you-ask what you can do for your country." He then proceeded to speak to the citizens of the World..."""
```

###数组
####声明数组
```
var z:Array[String] = new Array[String](3)
或
var z = new Array[String](3)
或
var z = Array("Alibaba", "Baidu", "Google")
```

####处理数组
数组的元素类型和数组的大小都是确定的，所以当处理数组元素时候，通常使用基本的for循环
```
var myList = Array(1.9, 2.9, 3.4, 3.5)

for ( x <- myList ) {
         println( x )
      }
```

####多维数组
```
val myMatrix = Array.ofDim[Int](3, 3, 3)

var num = 1

for (m <- 0 to 2;n <- 0 to 2;t <- 0 to 2){
  myMatrix(m)(n)(t) = num
  num += 1
}

for (m <- 0 to 2;n <- 0 to 2;t <- 0 to 2){
  println(myMatrix(m)(n)(t))
}
```

####合并数组
使用concat()方法来合并两个数组，但只能拼接一维
```
import Array._
//必须引入Array._
//拼接一维
var myList1 = Array(1.9, 2.9, 3.4, 3.5)
var myList2 = Array(8.9, 7.9, 0.4, 1.5)

var myList3 =  concat( myList1, myList2)

//拼接二维
val myMatrix3 = Array.ofDim[String](3, 4)
val myMatrix4 = Array.ofDim[String](3, 4)

for (m <- 0 to 2; n <- 0 to 3) {
  myMatrix3(m)(n) = m.toString + n.toString
}

for (m <- 0 to 2; n <- 0 to 3) {
  myMatrix4(m)(n) = m.toString + n.toString
}

var myMatrix9 = concat(myMatrix3, myMatrix4)

for (m <- 0 to 5; n <- 0 to 3) {
      println(myMatrix9(m)(n))
}

//拼接三维
val myMatrix1 = Array.ofDim[String](3, 3, 3)
val myMatrix2 = Array.ofDim[String](3, 3, 4)

for (m <- 0 to 2; n <- 0 to 2; t <- 0 to 2) {
  myMatrix1(m)(n)(t) = "myMatrix1 " + m.toString + n.toString + t.toString
}

for (m <- 0 to 2; n <- 0 to 2; t <- 0 to 3) {
  myMatrix2(m)(n)(t) = "myMatrix2 " + m.toString + n.toString + t.toString
}

var myMatrix8 = concat(myMatrix1, myMatrix2)

for (m <- 0 to 5; n <- 0 to 2; t <- 0 to 3) {
        if (!(m <= 2 && t == 3)) {
          println(myMatrix8(m)(n)(t))
        }
    }
```

####创建区间数组
使用range()方法来生成一个区间范围内的数组。range()方法最后一个参数为步长，默认为1
```
import Array._
//必须引入Array._

var myList1 = range(10, 20, 2)
var myList2 = range(10,20)
```

####数组展开
Scala的可变参数允许函数的最后一个参数可以是可变长度的参数，但可变参数不能将数组作为参数值传入，可以使用数组展开标记(array explode notation)解决这个问题
```
def max(values: Int*) = values.foldLeft(values(0)) { Math.max }

val numbers = Array(2, 5, 3, 7, 1, 6)
max(numbers: _*)
```

###Collection
Scala有3种主要的集合类型:

* List— 有序的对象集合
* Set— 无序的集合
* Map— 键值对字典

Scala集合分为可变的和不可变的集合

* 可变集合可以在适当的地方被更新或扩展。可以修改，添加，移除一个集合的元素
* 不可变集合，永远不会改变。不过仍然可以模拟添加，移除或更新操作。但是这些操作将在每一种情况下都返回一个新的集合，同时使原来的集合不发生改变

Scala推崇不可变集合，不可变集合是线程安全的，不受副作用影响。如果想修改集合，而且集合上所有的操作都在单线程中进行，那么就可以选择可变集合。如果打算跨线程、跨Actor地使用集合，那么不可变集合将会是更好的选择  

可以通过选择下列两个包之一来选择所使用的版本: **scala.collection.mutable** 或者 **scala.collection.immutable**  

如果不指定所使用的包名，默认情况下，Scala会使用不可变集合。因为(被默认包含的)Predef对象为集合提供了别名，指向的是不可变的实现  

因为特殊的apply()方法，创建一个集合对象可以不使用new关键字，Scala会自动调用这个类的伴生对象上的apply()方法

####List
* 以线性方式存储
* 可以存放重复对象
* 列表是不可变的，值一旦被定义了就不能改变
* 列表具有递归的结构，而数组不是

通过使用head方法，Scala使访问一个列表的第一个元素更加简单快速。使用tail方法，可以访问除第一个元素之外的所有元素。访问列表中的最后一个元素需要对列表进行遍历，因此相比访问列表的头部和尾部，该操作更加昂贵。所以，列表上的大多数操作都是围绕着对头部和尾部的操作构造的  

在Scala的标准库实现中，默认的List的实现只有两个子类，即Nil和::，其中Nil代表空列表，而::代表一个非空列表，并且由一个头部(head)和一个尾部(tail)组成，尾部又是一个List  

可以使用从0到list.length - 1的索 引来访问List中的元素。当调用XXXX(1)方法时，我们使用的是 List的apply()方法

#####定义列表
```
/*
::()方法表示将一个元素放在当前List的前面，a :: list读作“将a前插到list”
*/
var site: List[Int] = List(1, 2, 3, 4)
val site = 1 :: 2 :: 3 :: 4 :: Nil
val site = 1 :: (2 :: (3 :: (4 :: Nil)))
val site = Nil.::(4).::(3).::(2).::(1)

//空列表
val empty: List[Nothing] = Nil
val empty: List[Int] = List()
val empty = Nil

//二维列表
val dim: List[List[Int]] =
      List(
        List(1, 0, 0),
        List(0, 1, 0),
        List(0, 0, 1)
      )
val dim = (1 :: (0 :: (0 :: Nil))) ::
          (0 :: (1 :: (0 :: Nil))) ::
          (0 :: (0 :: (1 :: Nil))) :: Nil
```

#####连接列表
可以使用 ::: 运算符或 List.:::() 方法或 List.concat() 方法来连接两个或多个列表
```
val test1 = List(1,1)
val test2 = List(2,2)
val test3 = List(3,3)

//list ::: listA，读作“将list前插到listA”
val test = test1 ::: test2 ::: test3
val test = test1 ::: (test2 ::: test3)
val test = test3.:::(test2).:::(test1)

:: 和 ::: 的区别：
:: 向列表的头部追加数据，一般用来构造新的列表，无论追加的是列表与还是元素，都只将成为新生成列表的第一个元素，如下
val test = test1 :: test2 :: test3
val test = test1 :: (test2 :: test3)
val test = test3.::(test2).::(test1)
::: 只能用于连接两个List类型的集合
```

#####foldLeft()和foldRight()
foldLeft()方法将从列表的左侧开始，为列表中的每个元素调用给定的函数值(代码块)。它将两个参数传递给该函数值，第一个参数是使用(该列表中的)前一个元素执行该函数值得到的部分结果，这就是为何其被称为“折叠”(folding)，好像列表经过这些计算折叠出结果一样。第二个参数是列表中的一个元素。部分结果的初始值被作为该方法的参数提供。foldLeft()方法形成了一个元素链，并在该函数值中将计算得到的部分结果值，从左边开始，从一个元素携带到下一个元素。类似地，foldRight()方法也一样，但是它从右边开始  

为了使前面的方法更加简洁，Scala提供了替代方法。/:()方法等价于foldLeft()方法，而\:()方法等价于foldRight()方法

####Set
* 集合中的对象不按特定的方式排序
* 没有重复的对象，所有的元素都是唯一
* 分为可变的和不可变的集合
* 默认情况下，Scala使用的是不可变集合，也就是默认引用 scala.collection.immutable.Set，如果想使用可变集合，需要引用 scala.collection.mutable.Set

#####定义集合
```
val set:Set[Int] = Set(1,2,3)
val set:Set[Int] = Set()
val set = Set(1,2,3)

println(set.getClass.getName)
println(set.exists(_ % 2 == 0)) //true

import scala.collection.mutable.Set

val mutableSet = Set(1,2,3)

mutableSet.add(4)
mutableSet.remove(1)
mutableSet += 5
mutableSet -= 2

println(mutableSet)

val another = mutableSet.toSet

println(another.getClass.getName)

注意：不可变Set进行操作，会产生一个新的set，原来的set并没有改变，而对可变Set进行操作，改变的是该Set本身
```

#####连接集合
可以使用 ++ 运算符或 Set.++() 方法来连接两个集合。如果元素有重复的就会移除重复的元素
```
val site1 = Set("Runoob", "Google", "Baidu")
val site2 = Set("Faceboook", "Taobao")

// ++ 作为运算符使用
var site = site1 ++ site2
println( "site1 ++ site2 : " + site )

//  ++ 作为方法使用
site = site1.++(site2)
println( "site1.++(site2) : " + site )
```

#####交集
可以使用 Set.& 方法或 Set.intersect 方法来查看两个集合的交集元素
```
val num1 = Set(5,6,9,20,30,45)
val num2 = Set(50,60,9,20,35,55)

// 交集
println( "num1.&(num2) : " + num1.&(num2) )
println( "num1.intersect(num2) : " + num1.intersect(num2) )
```

####Map
* Map是一种可迭代的键值对（key/value）结构
* Map中的键都是唯一的
* Map也叫哈希表（Hash tables）
* Map有两种类型，可变与不可变，区别在于可变对象可以修改它，而不可变对象不可以
* 默认情况下Scala使用不可变 Map。如果需要使用可变集合，需要显式的引入 import scala.collection.mutable.Map 
* 在Scala中可以同时使用可变与不可变Map，不可变的直接使用Map，可变的使用 mutable.Map

#####定义Map
```
var A:Map[Char,Int] = Map()
val colors = Map("red" -> "#FF0000", "azure" -> "#F0FFFF")

//可以使用 + 号添加 key-value 对
A += ('I' -> 1)
A += ('L' -> 100)
```

#####Map合并
可以使用++运算符或Map.++()方法来连接两个Map，Map合并时会移除重复的key
```
val colors1 = Map("red" -> "#FF0001",
  "azure" -> "#F0FFFF",
  "peru" -> "#CD853F")
val colors2 = Map("blue" -> "#0033FF",
  "yellow" -> "#FFFF00",
  "red" -> "#FF0002")

//  ++ 作为运算符
var colors = colors1 ++ colors2
println( "colors1 ++ colors2 : " + colors )

//  ++ 作为方法
colors = colors1.++(colors2)
println( "colors1.++(colors2) : " + colors )
```

#####Map更新
要更新Map，可以使用updated()方法。除了显式地调用updated()方法之外，也可以利用另一个Scala小技巧，如果在赋值语句的左边的类或者实例上使用圆括号，那么Scala将自动调用updated()方法
```
X() = b
//等价于
X.updated(b)
```

如果updated()接受多个参数，那么可以将除尾参数之外的所有参数都放置在括号内部
```
X(a) = b
//等价于
X.updated(a,b)
```

####元组
* 元组是不同类型的值的集合
* 元组是不可变的
* 元组的值是通过将单个的值包含在圆括号中构成的
* 元组的实际类型取决于它的元素的类型
* 目前Scala支持的元组最大长度为22

#####定义元组
```
val t = (1, 3.14, "Fred")
val t = new Tuple3(1, 3.14, "Fred")
val t = Tuple4(1,2, 3.14, "Fred")

\\可以使用t._n访问第n个元素
val t = (4,3,2,1)
val sum = t._1 + t._2 + t._3 + t._4
```

#####多重赋值
可以将元组中的多个元素同时赋值给多个 val 或者 var
```
val firstName, lastName, emailAddress =
      ("Venkat", "Subramaniam", "venkats@agiledeveloper.com")
```

####Option
* Option类型用来表示一个值是可选的（有值或无值)
* Option[T]是一个类型为T的可选值的集合：如果值存在，Option[T]就是一个Some[T]，如果不存在，Option[T]就是对象None
* Option有两个子类，一个是Some，一个是None  
* Option实际上是一个集合，集合的大小是1或者是0

**Scala使用Option非常频繁，在Java中使用null关键字来表示空值，代码中很多地方都要添加null关键字检测，因为null是一个关键字，不是一个对象，对它调用任何方法都是非法的，所以很容易出现NullPointException。Scala的Option类型可以避免这种情况，因此Scala推荐使用Option类型来代表一些可选值。使用Option类型，读者一眼就可以看出这种类型的值可能为None** 


**为了让所有东西都是对象的目标更加一致，也为了遵循函数式编程的习惯，Scala 鼓励在变量和函数返回值可能不会引用任何值的时候使用Option类型。在没有值的时候，使用 None，这是Option的一个子类。如果有值可以引用，就使用Some来包含这个值。Some也是Option的子类。 None 被声明为一个对象，而不是一个类，因为我们只需要它的一个实例。这样，它多少有点像 null 关键字，但它却是一个实实在在的，有方法的对象。**
```
val a: Option[Int] = Some(5)
val b: Option[Int] = None

//当Option类型时None时，可以使用getOrElse()使用默认的值
println(a.getOrElse(10))
println(b.getOrElse(10))

def div(a: Int, b: Int): Option[Int] = {
  if (b != 0) Some(a / b) else None
}
val x1 = div(10, 5).getOrElse(0)//2
val x2 = div(10, 0).getOrElse(0)//0
```

####Iterator（迭代器）
Scala的Iterator（迭代器）不是一个集合，而是一种用于访问集合的方法
```
/*
迭代器 it 的两个基本操作是 next 和 hasNext
调用 it.next() 会返回迭代器的下一个元素，并且更新迭代器的状态
调用 it.hasNext() 用于检测集合中是否还有元素
 */

val it: Iterator[String] = Iterator("Runoob", "Google", "Baidu", "Baidu")
val it: Iterator[Int] = Iterator(1, 2, 3, 4)
val it: Iterator[(String, Int)] =
      Iterator("Baidu" -> 1, "Google" -> 2, "Runoob" -> 3, "Taobao" -> 4)

while (it.hasNext) {
      println(it.next())
    }
```

https://blog.csdn.net/qq_41455420/article/details/79440164  
https://blog.csdn.net/bluejoe2000/article/details/30465175  
https://blog.csdn.net/u013007900/article/details/79178749

###类和对象
####定义
Scala的类定义可以有参数，称为类参数，类参数在整个类中都可以访问，类参数作为主构造函数的参数
```
class Point(xc: Int, yc: Int) {
   var x: Int = xc
   var y: Int = yc

   def move(dx: Int, dy: Int) {
      x = x + dx
      y = y + dy
      println ("x 的坐标点: " + x);
      println ("y 的坐标点: " + y);
   }
}
```
如果类定义没有主体，可以省略大括号{}
```
class CreditCard(val number: Int, var creditLimit: Int)
```
Scala编译器会自动将类参数和类中定义的变量映射到一个private变量声明（就算变量显示标记为public编译器还是会映射一个private变量），并默认生成相应的getter和setter方法，**默认生成的getter和setter不遵循JavaBean惯例**
```
//上述Scala代码等价于下面的Java代码
public class CreditCard {
  private final int number;
  private int creditLimit;
  public int number();
  public int creditLimit();
  public void creditLimit_$eq(int); public CreditCard(int, int);
}
```
**如果声明的类参数没有声明val或者var关键字，那么编译器会生成一个标记为private final的字段用于类内部的访问。这样的参数不会自动生成getter和setter，并且不能从类的外部访问**

Scala 编译器默认生成的访问器并不遵循JavaBean方法的命名规范。不过可以使用 scala.beans.BeanProperty 注解来实现，在期望的变量上标记@BeanProperty注解，编译器就会生成类似于 JavaBean 的访问器，以及 Scala 风格的访问器，可以选择JavaBean风格或者Scala风格的访问器来访问成员变量
```
import scala.beans.BeanProperty

class Dude(@BeanProperty val firstName: String, val lastName: String) {
  @BeanProperty var position: String = _
}
//等价于
public class Dude {
    private final java.lang.String firstName;
    private final java.lang.String lastName;
    private java.lang.String position;
    public java.lang.String firstName();
    public java.lang.String lastName();
    public java.lang.String position();
    public void position_$eq(java.lang.String);
    public void setPosition(java.lang.String);
    public java.lang.String getFirstName();
    public java.lang.String getPosition();
    public Dude(java.lang.String, java.lang.String);
}
```

Scala 会执行主构造器中任意表达式和直接内置在类定义中的可执行语句
```
class Construct(param1: String,param2 :Int = 1+2) {
  println(s"Creating an instance of Construct with parameter $param1$param2 ")
}

def main(args: Array[String]): Unit = {
  println("Let's create an instance")
  new Construct("sample")
}
```

Scala可以使用this()方法定义辅助构造函数。Scala强制规定:辅助构造函数的第一行有效语句必须调用主构造函数或者其他辅助构造函数，这个规定的效果是Scala中的每个构造函数调用最终都会调用该类的主构造函数。因此，主构造函数是类的入口
```
class Person(val firstName: String, val lastName: String) {
  def this(firstName: String, lastName: String, positionHeld: String) {
    this(firstName, lastName)
  }
}
```

Scala要求类中声明的成员变量在使用前必须初始化，可以使用下划线 _ 来表示相应类型的默认值。对于Int来说，是0，对于Double来说，则是0.0;对于引用类型来说，是 null，以此类推。用 val 声明的变量无法使用下划线这种方便的初始化方法，因为 val 变量创建后就无法更改，所以必须在初始化的时给定一个合理的值，**该语法只适用于成员变量，而不适用于局部变量**
```
class Person(val firstName: String, val lastName: String) {
  var position: String = _
}
```

####类型别名
Scala使用type关键字声明一个类名的别名
```
class PoliceOfficer(val name: String)

type Cop = PoliceOfficer
val topCop = new Cop("Jack")
println(topCop.getClass)
```

####创建实例
如果构造器没有参数，Scala 允许在创建实例时省略()
```
new StringBuilder("hello")
new StringBuilder()
new StringBuilder
```

####继承
Scala使用extends关键字来继承一个类

* 在子类中重写父类的抽象方法时，不需要使用override关键字
* 在子类中重写父类的非抽象方法时，必须使用override修饰符
* 只有主构造函数才可以往父类的构造函数里传递参数，因为只有主构造函数能调用一个父类的构造函数，所以把这个调用直接放在extends声明之后的父类名后面
* 在子类主构造函数传给父类构造函数的参数前加关键字override，Scala编译器就不会为加了关键字override的参数生成字段，而是会将这些参数的访问器方法路由到父类的相应方法，如果忘了在想传递的参数前写上override关键字，就会遇到编译错误
* 子类会继承父类的所有属性和方法
* Scala只允许继承一个父类

```
class PoliceOfficer(val name: String) {

  def method_A(a: Int): Unit = {
    println("this is method_A")
  }

  def method_A(a: Int, b: Int): Unit = {
    println("this is overload method_A")
  }

  def method_B(a: Int): Unit = {
    println("this is method_B")
  }
}

class PoliceCar(override val name: String) extends PoliceOfficer(name) {

  def method_A(a: Int, b: Int, C: Int): Unit = {
    println("this is overdefine method_A")
  }

  def method_B(a: Int, b: Int): Unit = {
    println("this is overdefine method_B")
  }

  override def method_B(a: Int): Unit = {
    println("this is override method_B")
  }
}
```

####参数化类型（泛型）
Scala可以使用方括号[ ]来指定泛型
```
def echo[T](input1: T, input2: T): Unit =
    println(s"got $input1 (${input1.getClass}) $input2 (${input2.getClass})")

echo("hello", "there")
echo(4, 5)
/*
注意：由于Scala的所有类型都派生自Any，所以可以混用不同类型的参数，但这样做会有很高的风险
如果目的本来就是接受两个不同类型的参数，应声明两个不同的泛型，而不是混用不同类型的参数
*/
echo("hi", 5)
//可以在使用泛型对象时，显示声明泛型的类型，可以防止混用不同类型的参数，保证类型统一
echo[Int](4, 5)
```

####参数化类型的型变
在期望接收一个基类实例的集合的地方，能够使用一个子类实例的集合的能力叫作协变(covariance)。而在期望接收一个子类实例的集合的地方，能够使用一个超类实例的集合的能
力叫作逆变(contravariance)。在默认的情况下，Scala都不允许(即不变)

#####协变
```
class Pet(val name: String) {
  override def toString: String = name
}

class Dog(override val name: String) extends Pet(name)

def playWithPets[T <: Pet](pets: Array[T]): Unit =
  println("Playing with pets: " + pets.mkString(", "))
```
T <: Pet表明由T表示的类派生自Pet类。这个语法用于定义一个上界(如果可视化这个类的层次结构，那么Pet将会是类型T的上界)，T可以是任何类型的Pet，也可以是在该类型层次结构中低于Pet的类型。通过指定上界，我们告诉Scala 数组参数的类型参数T必须至少是一个Pet的数组，但是也可以是任何派生自Pet类型的类的实例数组

#####逆变
```
def copyPets[S, D >: S](fromPets: Array[S], toPets: Array[D]): Unit = {
  //...
}
```
S设定了类型D的下界，它可以是类型S，也可以是它的超类型

#####定制集合的型变
如果假定派生类型的集合可以被看作是其基类型的集合，可以通过将参数化类型标记为+T来完成这项操作，+T告诉Scala允许协变，在类型检查期间，它要求Scala接受一个类型或者该类型的派生类型
```
class MyList[+T] //...
var list1 = new MyList[Int]
var list2: MyList[Any] = _ 
list2 = list1 // 编译正确
```

同样，通过使用参数化类型-T，可以要求Scala为类型提供逆变支持

####单例对象
单例指的是只有一个实例的类，Scala使用关键字object实现单例模式。因为不能实例化一个单例对象，所以不能传递参数给它的构造器

* object单例对象不能带参数
* object单例对象的变量必须有初始值（因为不能实例化，所以只能在声明时设置好）

```
class Marker(val color: String) {
  println(s"Creating ${this}")
  override def toString = s"marker color $color"
}

object MarkerFactory {
  private val markers = mutable.Map("red" -> new Marker("red"),
                                    "blue" -> new Marker("blue"),
                                    "yellow" -> new Marker("yellow"))
  def getMarker(color: String): Marker =
    markers.getOrElseUpdate(color, new Marker(color))

}

println(MarkerFactory getMarker "blue")
println(MarkerFactory getMarker "blue")
println(MarkerFactory getMarker "red")
println(MarkerFactory getMarker "red")
println(MarkerFactory getMarker "green")
```

####伴生对象
单例对象是一个独立对象，它和任何类都没有自动的联系。Scala可以定义一个与已定义的类同名的object单例对象，这个单例对象就被关联到一个类，这样的单例对象被称为伴生对象(companion object)，相应的类被称为伴生类

* 当单例对象与某个类共享同一个名称时，他被称作是这个类的伴生对象：companion object；类被称为是这个单例对象的伴生类：companion class
* 类和它的伴生对象可以互相访问其私有成员
* 必须在同一个源文件里定义类和它的伴生对象

```
//伴生类
//私有构造方法
class Marker private (val color: String) {
  println(s"Creating ${this}")
  override def toString = s"marker color $color"
}

//伴生对象，与类名字相同，可以访问类的私有属性和方法
object Marker {
  private val markers = mutable.Map("red" -> new Marker("red"),
                                    "blue" -> new Marker("blue"),
                                    "yellow" -> new Marker("yellow"))

  def getMarker(color: String): Marker =
    markers.getOrElseUpdate(color, new Marker(color))

  def supportedColors: Iterable[String] = markers.keys

  /*
  使用apply()方法，可以不用new关键字就可以创建伴生类的实例，这是一种创建或者获得实例的 轻量级语法，也被称为工厂方法
  */
  def apply(color: String): Marker =
    markers.getOrElseUpdate(color, op = new Marker(color))
}

println(Marker getMarker "blue")
println(Marker getMarker "blue")
println(Marker getMarker "red")
println(Marker getMarker "red")
println(Marker getMarker "green")

println(s"Supported colors are : ${Marker.supportedColors}")
#调用Marker("blue")时，实际上在调用Marker.apply("blue")
println(Marker("blue"))
println(Marker("red"))
```

####枚举类
Scala没有从语言层面上支持枚举，需要利用继承Enumeration的方式实现枚举。在枚举中，使用type 枚举名 = Value把枚举名作为任何一种枚举值的通用引用，使枚举名被视为一种类型，而不是一个实例
```
object Currency extends Enumeration {
  type Currency = Value
  val CNY, GBP, INR, JPY, NOK, PLN, SEK, USD = Value
}

class Money(val amount: Int, val currency: Currency) {
  override def toString = s"$amount $currency"
}

object DayOfWeek extends Enumeration {
  val SUNDAY: DayOfWeek.Value = Value("Sunday")
  val MONDAY: DayOfWeek.Value = Value("Monday")
  val TUESDAY: DayOfWeek.Value = Value("Tuesday")
  val WEDNESDAY: DayOfWeek.Value = Value("Wednesday")
  val THURSDAY: DayOfWeek.Value = Value("Thursday")
  val FRIDAY: DayOfWeek.Value = Value("Friday")
  val SATURDAY: DayOfWeek.Value = Value("Saturday")
}
```
https://www.dazhuanlan.com/2019/08/20/5d5b05dd042ea/  
https://blog.csdn.net/u010003835/article/details/85167510  
https://blog.csdn.net/u010454030/article/details/77509613

####包对象
Scala的包除了接口、类、枚举和注解类型，还可以有变量和函数，它们都被放在一个称为包对象(package object)的特殊的单例对象中  
如果发现自己创建的一个类，仅仅是为了保留在同一个包中的其他类之间共享的一组方法（仅仅为了让包中的其他类调用），那么包对象就能避免创建并重复引用这样一个额外的类的负担
```
//WorkingWithObjects/finance1/finance/currencies/Currency.scala
//WorkingWithObjects/finance1/finance/currencies/Money.scala

//WorkingWithObjects/finance1/finance/currencies/Converter.scala
object Converter {
  def convert(money: Money, to: Currency): Money = {
    // 获取当前的市场汇率......这里使用了模拟值
    val conversionRate = 2
    new Money(money.amount * conversionRate, to)
  }
}

//WorkingWithObjects/finance1/finance/currencies/Charge.scala
object Charge {
  def chargeInUSD(money: Money): String = {
    def moneyInUSD = Converter.convert(money, Currency.USD)
    s"charged $$${moneyInUSD.amount}"
  }
}

/*
Converter.scala文件中的Converter单例对象中的convert()方法，
在Charge.scala文件中的Charge单例对象的chargeInUSD方法中被调用，
必须在convert()方法前加上Converter前缀，这个前缀是个人工的占位符，可以使用包对象避免
*/
```

Scala中的package关键字有两种用途:其一是定义一个包，其二是定义一个包对象。通过 package object packagename 定义一个包对象，将包含这个包对象的.scala文件放到包对象对应目录下。调用包对象中的方法时，就可省去前缀，创造一种这个方法直接属于这个包的印象
```
//WorkingWithObjects/finance1/finance/currencies/Currency.scala
//WorkingWithObjects/finance1/finance/currencies/Money.scala

//WorkingWithObjects/finance1/finance/currencies/package.scala
package object currencies {
  import Currency._
  def convert(money: Money, to: Currency): Money = { 
    // 获取当前的市场汇率......这里使用了模拟值
    val conversionRate = 2
    new Money(money.amount * conversionRate, to)
  }
}

//WorkingWithObjects/finance1/finance/currencies/Charge.scala
object Charge {
  def chargeInUSD(money: Money): String = {
    def moneyInUSD = convert(money, Currency.USD)
    s"charged $$${moneyInUSD.amount}"
  }
}
```

Scala在标准库中大量运用包对象。在所有Scala代码中，scala包都会被自动导入。因此，scala这个包的包对象也会被导入。这个包对象包含了很多类型别名和隐式类型转换

###Implicit（隐式）
Scala在面对编译出现类型错误时，提供了一个由编译器自我修复的机制，编译器试图去寻找一个隐式implicit的转换方法，转换出正确的类型，完成编译。这就是implicit的意义

####隐式参数和隐式变量
通常情况下，函数的参数默认值是由函数的创建者决定的，而不是由调用者决定。Scala还提供另外一种赋默认值的方法，可以由调用者来决定所传递的默认值，而不是由函数的定义者来决定  

函数的定义者首先需要把想要设置为隐式的参数标记为implicit，并且，Scala要求把隐式参数放在一个单独的参数列表而非常规的参数列表中。如果一个参数被定义为implicit，那么就像有默认值的参数，该参数的值传递是可选的，如果没有传值，Scala会在调用的作用域中寻找一个隐式变量，**这个隐式变量必须和相应的隐式参数具有相同的类型**，**在一个作用域中每一种类型都最多只能有一个 隐式变量**
```
object ImplicitToValue {
  
  def funImplicit1(implicit age: Int): Unit = {
    println("funImplicit1: age: " + age)
  }

  def funImplicit2(implicit age: Int, name: String): Unit = {
    println("funImplicit2: age: " + age + ", name:" + name)
  }
 
  //方法的参数如果有多个隐式参数的话，只需要使用一个implicit关键字即可，隐式参数列表必须放在方法的参数列表后面
  def funImplicit3(age: Int)(implicit name: String): Unit = {
    println("funImplicit3: age: " + age + ", name:" + name)
  }
}

implicit val impAge = 30
implicit val implName = "Jack"
 
funImplicit1
funImplicit2
funImplicit3(25)
```

####查找范围
当需要查找隐式对象、隐式方法、隐式类时，查找的范围是：

1. 现在当前代码作用域下查找
2. 如果当前作用域下查找失败，会在隐式参数类型的作用域里查找。
类型的作用域是指与该类型相关联的全部伴生模块，一个隐式实体的类型T它的查找范围如下：
    * 如果T被定义为T with A with B with C,那么A,B,C都是T的部分，在T的隐式解析过程中，它们的伴生对象都会被搜索
    * 如果T是参数化类型，那么类型参数和与类型参数相关联的部分都算作T的部分，比如List[String]的隐式搜索会搜索List的伴生对象和String的伴生对象
    *  如果T是一个单例类型p.T，即T是属于某个p对象内，那么这个p对象也会被搜索
    *  如果T是个类型注入S#T，那么S和T都会被搜索

####一次规则
编译器在需要使用 implicit 定义时，只会试图转换一次，也就是编译器永远不会把 x + y 改写成 convert1(convert2(x)) + y

####无歧义
* 对于隐式参数，如果查找范围内有两个该类型的变量，则编译报错
* 对于隐式转换，如果查找范围内有两个从A类型到B类型的隐式转换，则编译报错

```
implicit val default:Int = 500

def sum(a: Int)(implicit b: Int, c: Int): Int = {
    a + b + c
  }

/*
如果有多个相同类型的隐式参数，由于隐式变量最多只能有一个，所以这个类型的所有隐式参数都会被
赋予同一个隐式变量
*/
val result = sum(10)
```

####隐式类型转换
在两种情况下会使用隐式转换：

* 调用方法时，传递的参数类型与方法声明的参数类型不同时，编译器会在查找范围下查找隐式转换，把传递的参数转变为方法声明需要的类型
* 调用方法时，如果对象没有该方法，那么编译器会在查找范围内查找隐式转换，把调用方法的对象转变成有该方法的类型的对象

如果有多个隐式转换可见，那么Scala将会挑选最合适的，以便代码可以成功编译。但是，Scala一次最多只能应用一个隐式转换。如果对于同一个方法调用，有多个隐式转换相互竞争，那么Scala将会给出一个错误  
实现类型转换有两种不同的方式，隐式函数和隐式类。在scala包的包对象和Predef对象中，Scala已经定义好了大量的隐式转换，它们在默认情况下都已被导入。例如，当编写1 to 3的时候，Scala会隐式地将1从Int转换为其更加饱满的包装器RichInt，然后调用它的to()方法

####隐式函数
```
//使用隐式函数转换方法参数
object ImplicitObject1 {
  implicit def doubleToInt(x: Double) = x toInt
}

object ImplicitConvertTest1 {
  def showInt(i: Int) = println("i is " + i)

  def main(args: Array[String]): Unit = {
    import net.qingtian.scala.test1.implicit_.ImplicitObject1._
    showInt(1.1)

    val ii: Int = 1.2
    println("ii is " + ii)
  }
}
```

####隐式类
可以使用隐式类来消除转换隐式函数，只需要编写一个隐式类，Scala就会负责创建所有必要的管道代码。更倾向于使用隐式类，而不是隐式方法，隐式类表意更加清晰明确，并且比任意的隐式转换方法更容易定位
```
//使用隐式类转换调用不存在方法的对象
class Speaker {
  def speak(str: String) = println("Speaker说：" + str)
}

class Aminal

object ImplicitObject2 {

  implicit class StringImprovement(val s: String) { //隐式类
    def increment = s.map(x => (x + 1).toChar)
  }

  implicit def toSpeaker(s: Aminal) = new Speaker
}

object ImplicitConvertTest2 {
  def main(args: Array[String]): Unit = {
    import net.qingtian.scala.test1.implicit_.ImplicitObject2._

    // 通过隐式类进行转换
    // 把字符串"abcde"隐式转换成ImplicitObject2.StringImprovement
    println("abcde".increment)

    // 通过隐式方法转换
    // 把rabbit对象转换成Speaker对象使用
    val rabbit = new Aminal
    rabbit.speak("hello world")
  }
}
```

####值类
隐式转换越多，所创建的短生命周期的垃圾对象也就越多。使用值类，编译器将会使用没有中间对象的函数组合来直接编译这些方法调用，垃圾对象将会被消除。创建一个值类，只需要继承AnyVal即可
```
implicit class DateHelper(val offset: Int) extends AnyVal{
  //...
}
```
Scala中的隐式包装类(如RichInt和RichDouble)都是作为值类实现的  

值类在任何简单值或者原始值已经够用但你希望使用类型来进行更好的抽象的地方都是有用的
```
//可以在获得抽象的好处的同时，在字节码级别将其保留为原始值
class Name(val value: String) extends AnyVa {
  override def toString: String = value
  def length: Int = value.length
}

object UseName extends App {
  def printName(name: Name): Unit = {
    println(name)
  }
  val name = new Name("Snowy")
  //对length()方法的调用也从对实例上方法的调用变成了对一个扩展方法的调用
  println(name.length)
  //在源代码级别上，printName()方法仍然接受的是一个 Name类的实例，但是在字节码级别上，它现在接受的是一个String的实例
  printName(name)
}
```

值类并不总能够避免创建实例，如果将值类的值赋值给另一种类型，或者将其看作是另一种类型，那么Scala将会创建值类的实例
```
val any: Any = name
```

https://blog.csdn.net/u012798083/article/details/82705768  
https://blog.csdn.net/bingospunky/article/details/88854352  
https://www.cnblogs.com/yinzhengjie/p/9376317.html

###Trait(特征)
Scala的Trait(特征)相当于Java的接口，不同的是可以定义属性和方法的实现。一般情况下Scala的类只能够继承单一父类，不过可以继承多个Trait(特征)，从而实现了多重继承。任何已定义但未被初始化的val和var变量都被认为是抽象的，混入这些特征的类需要实现它们
```
trait Equal {
  def isEqual(x: Any): Boolean
  def isNotEqual(x: Any): Boolean = !isEqual(x)
}

class Point(xc: Int, yc: Int) extends Equal {
  var x: Int = xc
  var y: Int = yc
  def isEqual(obj: Any) =
    obj.isInstanceOf[Point] &&
      obj.asInstanceOf[Point].x == x
}
```
如果一个类已经继承了另外一个类，那么可以使用with关键字来混入第一个特征。可以混入任意数量的特征，如果要混入更多的特征，也需要使用with关键字
```
trait Friend {
  val name: String
  def listen(): Unit = println(s"Your friend $name is listening")
}

class Animal

class Dog(val name: String) extends Animal with Friend {
  // 选择性重写方法
  override def listen(): Unit = println(s"$name's listening quietly")
}
```
可以在混入了某个特征的类实例上调用该特征的方法，同时也可以将指向这些类的引用视为指向该特征的引用
```
class Human(val name: String) extends Friend

class Woman(override val name: String) extends Human(name)
class Man(override val name: String) extends Human(name)

object UseFriend extends App {
  val john = new Man("John")
  val sara = new Woman("Sara")
  val comet = new Dog("Comet")
  john.listen()
  sara.listen()
  comet.listen()
  val mansBestFriend: Friend = comet
  mansBestFriend.listen()
  def helpAsFriend(friend: Friend): Unit = friend.listen()
  helpAsFriend(sara)
  helpAsFriend(comet)
}
```
特征要求混入了它们的类去实现在特征中已经声明但尚未初始化的(抽象的)变量(val 和 var)，特质的构造器不能接受任何参数，特质连同对应的实现类被编译为Java中的接口，实现类中保存了特质中已经实现的所有方法

####选择性混入
在某些场景下，可以在实例级别有选择性地混入特征，在这种情况下，我们可以将某个类的特定实例视为某个特征的实例
```
class Cat(val name: String) extends Animal

def useFriend(friend: Friend): Unit = friend.listen()

val angel = new Cat("Angel") with Friend
val friend: Friend = angel

angel.listen()
useFriend(angel)
```

####特征中的方法延迟绑定
在Scala中，特征可以是独立的，也可以继承自某个类。继承为特征添加了两项能力:这些特征只能被混入那些继承了相同基类的类中，以及可以在这些特征中使用基类的方法  
在特征中，使用super来调用方法将会触发延迟绑定(late binding)。这不是对基类方法的调用。相反，调用将会被转发到混入该特征的类中。如果混入了多个特征，那么调用将会被转发到混入链中的下一个特征中，更加靠近混入这些特征的类
```
abstract class Writer {
  def writeMessage(message: String): Unit
}

trait UpperCaseWriter extends Writer {
  abstract override def writeMessage(message: String): Unit =
    super.writeMessage(message.toUpperCase)
}

trait ProfanityFilteredWriter extends Writer {
  abstract override def writeMessage(message: String): Unit =
    super.writeMessage(message.replace("stupid", "s-----"))
}

class StringWriterDelegate extends Writer {
  val writer = new java.io.StringWriter
  def writeMessage(message: String): Unit = writer.write(message)
  override def toString: String = writer.toString
}

val myWriterProfanityFirst =
      new StringWriterDelegate with UpperCaseWriter with ProfanityFilteredWriter
val myWriterProfanityLast =
      new StringWriterDelegate with ProfanityFilteredWriter withUpperCaseWriter

myWriterProfanityFirst writeMessage "There is no sin except stupidity"
myWriterProfanityLast writeMessage "There is no sin except stupidity"
```

####特征构造顺序
特征也可以有构造器，由字段的初始化和其他特征体中的语句构成。这些语句在任何混入该特征的对象在构造时都会被执行。构造器的执行顺序：

* 调用超类的构造器
* 特征构造器在超类构造器之后、类构造器之前执行
* 特征由左到右被构造
* 每个特征当中，父特征先被构造
* 如果多个特征共有一个父特征，父特征不会被重复构造
* 所有特征被构造完毕，子类被构造

构造器的顺序是类的线性化的反向。线性化是描述某个类型的所有超类型的一种技术规格

###模式匹配
一个模式匹配包含了一系列备选项，每个都开始于关键字case。每个备选项都包含了一个模式及一到多个表达式。箭头符号=>隔开了模式和表达式，使用下划线(_)表示其他情况
```
//匹配字符串
def activity(day: String): Unit = {
  day match {
    case "Sunday"   => print("Eat, sleep, repeat... ")
    case "Saturday" => print("Hang out with friends... ")
    case "Monday"   => print("...code for fun...")
    case "Friday"   => print("...read a good book...")
  }
}

//匹配Int
def matchTest(x: Int): String = x match {
      case 1 => "one"
      case 2 => "two"
      case _ => "many"
   }

//匹配枚举
object DayOfWeek extends Enumeration {
  val SUNDAY: DayOfWeek.Value = Value("Sunday")
  val MONDAY: DayOfWeek.Value = Value("Monday")
  val TUESDAY: DayOfWeek.Value = Value("Tuesday")
  val WEDNESDAY: DayOfWeek.Value = Value("Wednesday")
  val THURSDAY: DayOfWeek.Value = Value("Thursday")
  val FRIDAY: DayOfWeek.Value = Value("Friday")
  val SATURDAY: DayOfWeek.Value = Value("Saturday")
}

def activity(day: DayOfWeek.Value): Unit = {
  day match {
    case DayOfWeek.SUNDAY   => println("Eat, sleep, repeat...")
    case DayOfWeek.SATURDAY => println("Hang out with friends")
    case _                  => println("...code for fun...")
  }
}

//匹配元组
def processCoordinates(input: Any): Unit = {
  input match {
    case (lat, long) => printf("Processing (%d, %d)...", lat, long)
    case "done"      => println("done")
    case _           => println("invalid input")
  }
}

//匹配列表
def processItems(items: List[String]): Unit = {
  items match {
    case List("apple", "ibm")         => println("Apples and IBMs")
    case List("red", "blue", "white") => println("Stars and Stripes...")
    /*
    提供关心的元素即可，对于剩下的元素使用数组展开(array explosion)标记(_*)，
    ，匹配指定的开头两个元素的List
    */
    case List("red", "blue", _*)      => println("colors red, blue,... ")
    /*
    如果需要引用List中剩下的元素，可以在特殊的@符号之前放置一个变量名
    */
    case List("apple", "orange", otherFruits @ _*) =>
      println("apples, oranges, and " + otherFruits)
  }
}

//匹配类型
def process(input: Any): Unit = {
  input match {
    case (_: Int, _: Int)          => print("Processing (int, int)... ")
    case (_: Double, _: Double)    => print("Processing (double, double)..")
    //守卫约束
    case msg: Int if msg > 1000000 => println("Processing int > 1000000")
    case _: Int                    => print("Processing int... ")
    case _: String                 => println("Processing string... ")
    case _                         => printf(s"Can't handle $input... ")
  }
}
```
match对应Java里的switch，但是写在选择器表达式之后。即：选择器match{备选项}。match表达式将会自上而下地对case表达式进行求值，只要发现有一个匹配的case，剩下的case不会继续匹配，相当于自动进行了break，所以在编写多个case表达式时，它们的顺序很重要
```
def matchTest(x: Any): Any = x match {
      case 1 => "one"
      case "two" => 2
      case y: Int => "scala.Int"
      case _ => "many"
   }
```

####模式变量和常量
Scala期望模式变量名都以小写字母开头，而常量名则是大写字母。如果一个常量使用的是非大写字母的名称，它将只假设其是一个模式变量，在作用域范围内任何具有相同非大写字母的变量名都将会被隐藏
```
class Sample {
  val max = 100
  def process(input: Int): Unit = {
    input match {
      case max => println(s"You matched max $max")
    }
  }
}

val sample = new Sample
try {
  sample.process(0)
} catch {
  case ex: Throwable => println(ex)
}
```

可以使用显式的作用域指定来访问在case表达式中被隐藏的字段
```
//使用点号表示
case this.max => println(s"You matched max $max")
//使用反单引号(`)
case `max` => println(s"You matched max $max")
```

可以使用以上两种方法的任何一种来指示Scala将非大写字母的名称看作是作用域范围内的预定义值，而不是模式变量。最好避免这样做，请将大写字母的名称用于真正的常量
```
class Sample {
  val MAX = 100
  def process(input: Int): Unit = {
    input match {
      case MAX => println("You matched max")
    }
  }
}

val sample = new Sample
try {
  sample.process(0)
} catch {
  case ex: Throwable => println(ex)
}
```

####样例类
使用了case关键字的类定义就是就是样例类(case classes)，样例类是种特殊的类，经过优化以用于模式匹配（匹配类的实例）
```
object Test {
   def main(args: Array[String]) {
        val alice = new Person("Alice", 25)
        val bob = new Person("Bob", 32)
        val charlie = new Person("Charlie", 32)
   
    for (person <- List(alice, bob, charlie)) {
        person match {
            case Person("Alice", 25) => println("Hi Alice!")
            case Person("Bob", 32) => println("Hi Bob!")
            case Person(name, age) =>
               println("Age: " + age + " year, name: " + name + "?")
         }
      }
   }
   // 样例类
   case class Person(name: String, age: Int)
}

//还有几种模式匹配
case 0 | "" => false    //在0或空字符串的情况下,返回false
case 2 | 4 | 6 | 8 | 10 => println("偶数")     //在10及以下的偶数,返回"偶数"
case x if x == 2 || x == 3 => println("two's company, three's a crowd")       //在模式匹配中使用if
```
在声明样例类时，自动发生以下过程：

* 构造器的每个参数都成为val，除非显式被声明为var，但是并不推荐这么做
* 在伴生对象中提供了apply方法，所以可以不使用new关键字就可构建对象
* 提供unapply方法使模式匹配可以工作
* 生成toString、equals、hashCode和copy方法，除非显示给出这些方法的定义

####提取器(Extractor)
提取器是从传递给它的对象中提取出构造该对象的参数。Scala提取器是一个带有unapply方法的对象。通过apply方法，无需使用new操作就可以创建对象。unapply方法算是apply方法的反向操作：unapply接受一个对象，然后从对象中提取值，提取的值通常是用来构造该对象的值
```
//编译器在实例化的时会调用apply方法
//当在提取器对象中使用match语句时，unapply将自动执行
object Test {
   def main(args: Array[String]) {
     
      val x = Test(5)
      println(x)

      x match
      {
         case Test(num) => println(x + " 是 " + num + " 的两倍！")
         //unapply 被调用
         case _ => println("无法计算")
      }

   }
   def apply(x: Int) = x*2
   def unapply(z: Int): Option[Int] = if (z%2==0) Some(z/2) else None
}

////////////////////
object Symbol {
  def unapply(symbol: String): Boolean = {
    // 查找了数据库，但是只识别了GOOG和IBM
    symbol == "GOOG" || symbol == "IBM"
  }
}

object StockService {
  def process(input: String): Unit = {
    //match表达式将自动将input作为参数发送给unapply()方法
    input match {
      case Symbol() => println(s"Look up price for valid symbol $input")
      case _        => println(s"Invalid input $input")
    }
  }
}

StockService process "GOOG"
StockService process "IBM"
StockService process "ERR"

/*
Look up price for valid symbol GOOG
Look up price for valid symbol IBM
Invalid input ERR
*/

////////////////////
object ReceiveStockPrice {
  def unapply(input: String): Option[(String, Double)] = {
    try {
      if (input contains ":") {
        val splitQuote = input split ":"
        Some((splitQuote(0), splitQuote(1).toDouble))
      } else {
        None
      }
    } catch {
      case _: NumberFormatException => None
    }
  }
}

object StockService {
  def process(input: String): Unit = {
    input match {
      case Symbol() => println(s"Look up price for valid symbol $input")
      //接收从提取器中传出的参数
      case ReceiveStockPrice(symbol, price) =>
        println(s"Received price $$$price for symbol $symbol")
      case _ => println(s"Invalid input $input")
    }
  }
}

StockService process "GOOG"
StockService process "GOOG:310.84"
StockService process "GOOG:BUY"
StockService process "ERR:12.21"

/*
Look up price for valid symbol GOOG
Received price $310.84 for symbol GOOG
Invalid input GOOG:BUY
Received price $12.21 for symbol ERR
*/

////////////////////
//可以在一个case语句中应用多个提取器
//在模式变量后面加上@符号
//先调用ReceiveStockPrice提取器，再调用Symbol提取器
case ReceiveStockPrice(symbol @ Symbol(), price) =>
  println(s"Received price $$$price for symbol $symbol")
```
  
https://blog.csdn.net/bitcarmanlee/article/details/76736252

####正则表达式
Scala通过scala.util.matching包中的Regex类来支持正则表达式
```
//构造Regex对象
val pattern = "Scala".r
val pattern = new Regex("(S|s)cala")

val str = "Scala is scalable and cool"

//findFirstIn方法找到首个匹配项
println(pattern findFirstIn str)

//findAllIn方法找到所有匹配项
//可以使用mkString()方法来连接正则表达式匹配结果的字符串
println((pattern findAllIn str).mkString(","))

//可以使用replaceFirstIn()方法来替换第一个匹配项，使用replaceAllIn()方法替换所有匹配项
println(pattern replaceFirstIn(str, "Java"))
```

####正则表达式作为提取器
当创建了一个正则表达式时，将自动得到一个提取器。Scala将放置在括号中的每个匹配项看作是一个模式变量
```
"(Sls)cala".r //unapply()方法返回Option[String]
"(Sls)(cala)".r //unapply()方法Option[(String,String)]
```

```
def process(input: String): Unit = {
  val GoogStock = """^GOOG:(\d*\.\d+)""".r
  input match {
    case GoogStock(price) => println(s"Price of GOOG is $$$price")
    case _                => println(s"not processing $input")
  }
}

def process(input: String): Unit = {
  val MatchStock = """^(.+):(\d*\.\d+)""".r
  input match {
    case MatchStock("GOOG", price) => println(s"We got GOOG at $$$price")
    case MatchStock("IBM", price)  => println(s"IBM's trading at $$$price")
    case MatchStock(symbol, price) => println(s"Price of $symbol is $$$price")
    case _                         => println(s"not processing $input")
  }
}
```

###异常处理
Scala不区分受检异常和不受检异常，它将所有的异常都看作是不受检异常，即不强制对异常进行捕获
####抛出异常
```
throw new IllegalArgumentException
```

####捕获异常
Scala并不强迫捕不关心的异常，即使是受检异常。这可以避免添加不必要的catch代码块，只需让不想捕获的异常按照调用链向上传播即可  

Scala使用模式匹配来进行异常处理，如果抛出的异常不在catch字句中，该异常则无法处理，会被升级到调用者处  

Scala还支持finally代码块，finally语句用于执行不管是正常处理还是有异常发生时都需要执行的步骤
```
object Tax {
  def taxFor(amount: Double): Double = {
    if (amount < 0)
      throw new IllegalArgumentException("Amount must be greater than zero")
    if (amount < 0.01)
      throw new RuntimeException("Amount too small to be taxed")
    if (amount > 1000000) throw new Exception("Amount too large...")
    amount * 0.08
  }
}

for (amount <- List(100.0, 0.009, -2.0, 1000001.0)) {
  try {
    print(s"Amount: $$$amount ")
    println(s"Tax: $$${Tax.taxFor(amount)}")
  } catch {
    case ex: IllegalArgumentException => println(ex.getMessage)
    case ex: RuntimeException         =>
      // 如果需要一段代码来处理异常
      println(s"Don't bother reporting...${ex.getMessage}")
    /*
    如果想要捕获任何抛出的异常，那么可以捕获Throwable，如果并不关心异常的详细信息，那么也可以使用 _ 来代替变量名
    */
    case _: Throwable => println("Something went wrong")
  }
}
```

如果有异常发生，catch字句是按次序捕捉的。如果前面的语句处理了本打算在后面的语句中处理的异常，Scala并不会产生警告，所以在catch字句中，越具体的异常越要靠前，越普遍的异常越靠后。由于异常捕捉是按次序，如果最普遍的异常，Throwable，写在最前面，则在它后面的case都捕捉不到，因此需要将它写在最后面
```
val amount = -2
try {
  print(s"Amount: $$$amount ")
  println(s"Tax: $$${Tax.taxFor(amount)}")
} catch {
  case _: Exception                 => println("Something went wrong")
  case ex: IllegalArgumentException => println(ex.getMessage)
}
```

###下划线使用场景总结
_(下划线)在Scala中无处不在

* 作为包引入的通配符，import java.util._
* 作为元组索引的前缀，val names = ("Tom", "Jerry")， names._1、names._2
* 作为函数值的隐式参数，list.map { _ * 2 }、list.reduce { _ + _ }
* 用于用默认值初始化变量，var min : Int = _、var msg : String = _
* 用于在函数名中混合操作符
* 在进行模式匹配时作为通配符，case _
* 在处理异常时，在catch代码块中和case联用
* 作为分解操作的一部分，max(arg: _*)
* 用于部分应用一个函数，val square = Math.pow(_: Int,2)

###文件I/O
####写操作
Scala进行文件写操作，直接使用java中的I/O类（java.io.File)
```
import java.io._

val writer = new PrintWriter(new File("test.txt" ))
```

####读操作
```
//接收在来自屏幕的输入
val line = StdIn.readLine()
//接收在来自文件的输入
//使用Scala的Source类及伴生对象来读取文件
import scala.io.Source
Source.fromFile("test.txt" ).foreach{
         print
      }
```

https://www.cnblogs.com/joymufeng/p/6866999.html  
https://www.zhihu.com/question/21622725  
https://my.oschina.net/joymufeng/blog/863823