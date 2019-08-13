Runtime_2

0.OC语言是一门动态语言，会将程序的一些决定工作从编译期推迟到运行期。􏲷由于OC语言运行时的特性，所以其不只需要依赖编译器，还需要依赖运行时环境。

1.**Method 与SEL与IMP的关系**

**typedef struct** method_t *Method; 

**struct** method_t { 

  SEL name; 

  **const char** *types; 

  IMP imp; 

}; 

其中IMP为（IMP本质上就是函数指针）

**typedef void** (*IMP)(**void** */\* id, SEL, ... \*/* );

2.在Xcode进行编译的时候，只会想Xcode的Compile Sources中.m声明的方法编译到Method List,而.h文件中的声明的方法对Method List没有影响。

3.Runtime有检测内存冲突的机制，在类生成实例变量时，会判断实例变量是否有地址冲突，如果发生冲突则调整对象的地址偏移，这样就在运行时解决了地址冲突的问题。

4.objc_class中有个主角就是class_data_bits_t bits 这个成员变量，在编译后class_data_bits_t指向class_ro_t的地址，这个结构体是不可变的（只读）。在运行时，才会通过realizeClass函数将bits指向class_rw_t。

􏰼􏰵􏷲􏷳􏱡􏱢􏱞5.苹果不允许直接访问isa指针，和Tagged Pointer也是有关系的。因为在􏲷􏰼􏰵􏷲􏷳􏱡􏱢􏱞􏱟Tagged Pointer的情况下，isa并不是一个指针指向另外一块内存区，而是直接表示对象的值，所以通过直接访问isa获取到的信息是错误的。

6.为什么只能向运行时动态创建的类添加ivars，不能向已经存在的类添加ivars呢？

这是因为在编译时只读结构体class_ro_t就会被确定，在运行时是不可更改的。ro结构体中有一个字段是instanceSize,表示当前类在创建对象时需要多少空间，后面的创建都根据这个size分配类的内存。

7.load类方法的调用时机比main函数还要靠前，所以一般Method Swizzling都会放在load方法中执行。

如果对一个类添加Category，并且重写其原有的方法，这样会导致Category的方法覆盖原类的方法，但是load方法却是例外，所有Category和原类的load方法都会被执行。load方法执行的顺序是父类->子类->分类。

8.和load方法类似的也有initialize方法，initialize方法也是由runtime进行调用的，自己不可以直接调用，与load不同的是initialize方法是在第一次调用类所属的方法时，才会调用initialize。而load方法是在main函数之前就全部调用了。所以说理论上initialize可能永远不执行，如果当前类的方法永远不被调用的话。

需要注意的是，initalize方法和load方法不一样，Category上的方法是会覆盖原方法的。

9.在runtime中维护了一个SEL(其实就是常量字符串)的表，这个表存储SEL不按照类来存储，只要相同的SEL就会被看做同一个，并存储到表中，在项目加载时，会将所有的方法都加载到这个表中，而动态生成的方法也会被加载到表中。

10.分类(Category)和扩展(Extension)的区别是，Extension在编译期就直接和原类编译在一起，而Category是在运行时动态添加到原类中的。

11.可以创建NSObject的分类拦截相应的方法，例如在resolveInstanceMethod中，动态创建未实现的方法，并将IMP统一设置为dynamicResolveMethod函数进行处理，这样所有未实现的方法都会统一执行dynamicResolveMethod而不再奔溃了。

12.