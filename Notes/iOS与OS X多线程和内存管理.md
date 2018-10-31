## 关于内存管理 Block 多线程（iOS与OS X多线程和内存管理）

### 内存管理

#### 引用计数式内存管理的思考方式：

1.自己生成的对象，自己持有。

2.非自己生成的对象，自己也能持有。

3.不在需要自己持有对象时释放。

4.非自己持有的对象无法释放。

5.没有人持有时，对象废弃。

生成并持有对象 -> alloc/new/copy/mutableCopy等方法。

持有-> retain方法

释放-> release方法

废弃-> delloc方法

引用计数表（散列表也就是哈希表）各记录中存有内存块地址，可从各个记录追溯到各对象的内存块。

#### autorelease的具体使用方法：

1.生成并持有NSAutoreleasePool对象。

2.调用已分配对象的autorelease。

3.废弃NSAutoreleasePool。

PS:ARC（NSAutoreleasePool已经不可用可以使用@autoreleasepool）

#### 所有权修饰符

ARC有效时，id类型和对象类型必须附加所有权修饰符**：

__strong修饰符（默认 所以可以忽略不写）

__weak修饰符 

__unsafe_unretained 修饰符

__autoreleasing

其中除了__unsafe_unretained修饰符其他修饰符变量会自动初始化为nil。（声明后）

__strong修饰符会持有对象，而\_\_weak修饰符则不会持有对象。（\_\_weak主要用于防止循环引用，当然还有个优点是在对象被释放时会自动设置为nil）

__unsafe_unretained 不会自动设置成nil其他与\_\_weak相同。

__autoreleasing基本上隐式使用，例如

对象作为函数的返回值，编译器会自动将其注册到autoreleasepool。

id的指针或者对象的指针在没用显式的指定时会被附加上__autoreleasing修饰符。例如**error。

#### ARC有效的情况下，应遵循如下规则（下面很多编译器帮你校验了）:

1.不能使用retain/release/retainCount/autorlease

2.不能使用NSAllocateObject/NSDeallocateObject

3.须遵守内存管理的方法命名规则

4.不要显式调用dealloc

5.使用@autoreleasepool块代替NSAutoreleasePool

6.不能使用区域（NSZone）

7.对象型变量不能作为你C语言结构体（struct/union）的成员

8.显示的转换"id"和"void*"

**属性赋值给指定的属性中就相当于赋值给附加各属性对应的所有权修饰符的变量中。**

assign -> __unsafe_unretained

copy -> __strong

retain -> __strong

strong -> __strong

unsafe_unretained -> __unsafe_unretained

weak -> __weak

**ARC的实现不单单只有编译器进行内存管理，还需要运行时的协助。**

#### __weak的实现

__weak 能自动设置为nil的实现是因为用其修饰的对象，会以对象地址作为建，变量地址作为值存入weak表中。（哈希表，即散列表）而对象被废弃时最后会调用objc_clear_deallocating函数它会：

1.从weak表中获取废弃对象的地址为键值的记录。

2.讲将包含在记录中附有__weak修饰符变量的地址赋值为nil。

3.从weak表中删除该记录。

4.从引用计数表（也是散列表）中删除废弃对象的地址为键值的记录。

**所以，如果大量使用附有__weak修饰符的变量，则会消耗相应的CPU资源，良策是只在需要避免循环引用时使用\_\_weak修饰符。**

### Blcoks

带有自动变量（局部变量）的匿名函数。

Blocks中将匿名函数部分称为"Block literal",简称"Block"。

#### Block

Block 语法为： ^返回值类型 参数表 表达式

```objective-c
^int (int count){return count + 1;}
```

其中返回值类型与参数表可以省略。

block类型变量的声明则为： 返回值类型  ^类型名 参数表 

```objective-c
int (^myBlock)(int) = ^int (int count){return count + 1;};
```

由于这么写十分繁琐 一般用typedef 来简写

```objective-c
typedef int (^MyBlock)(int)
MyBlock block = ^int (int count){return count + 1;};
```

使用附有__block说明符的自动变量可在Block中赋值，该变量称为\_\_block变量。

**Block即为Objective-C对象。** 
**所谓"截获自动变量值"意味着在执行Block语法时，Block语法表达式所使用的自动变量值被保存到Block的结构体实例（即Block自身）中。**

**__block之所以修饰之后block中可以修改是因为该修饰的变量被转化为了一个结构体类型的自动变量，结构体中有forwarding指针指向自己**

block超出变量作用域可以存在的原因是：

**Blocks提供了将Block和__block变量从栈上复制到堆上的方法**

内存一般分配：栈上运行，堆放对象。

一般情况下Blocks会在需要时把Block从栈上复制到堆上，但是有时候不会，不会时需要手动调用copy。

什么时候栈上的Blocks会复制到堆：

1.调用Block的copy实例方法

2.Block作为函数返回值返回时

3.将Block赋值给附有__strong修饰符id类型的类或Block类型成员变量时。

4.在方法名中含有usingBlock的Cocoa框架方法或Grand Central Dspatch的API中传递Block时。

**如果在Block中使用附有__strong修饰符的对象类型自动变量，那么当Block从栈复制到堆时，该对象为Block所持有，这样容易引起循环引用。**

解除block循环引用有两种方法：

1.把自动变量设置为__weak(相对比较好用的比较多的方式)

2.用__block修饰自动变量，在block结束后设置为nil（这种方式有个缺点就是block不执行还是存在内存泄露）

