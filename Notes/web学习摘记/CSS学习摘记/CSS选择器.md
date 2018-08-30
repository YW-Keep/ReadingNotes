## CSS选择器

1.浏览器有时候会有一些私有属性，这些属性就会被带上标记已做区别：其中chrome,safari 是-webkit- firefox 是 -moz- IE是 -ms- opera 则是-o-

### 简单选择器

#### 标签选择器  

p {color: blue}

#### 类选择器 (.)

.spcical{clor:blue}

可以有多个类

#### id选择器 (#)  

 \#banner{color:black}

id只能有一个

#### 通配符选择器(*)

*{color black;} 选择页面中的所有元素

  #### 属性选择器([])

[disabled]{background-color:#eee}

(ps：其实id选择器和类选择器都是属性选择器的特例)  

#### 伪类选择器(:)

（例如a:link有链接的, a:visite访问过的,a:hover移上去的，a:active点击过的）

### 伪元素选择器（为了区分伪类选择器所以是::）

::fist-letter  表示选择第一个字符。

::fist-line 第一行 

 ::before{content:"before"} 在content第一行插入文本（after同理）

::selection 应用于被用户选中的内容

### 组合选择器

#### 后代选择器和子选择器

后代选择器为空格相连  例如 div p  为div 下面的p 而子选择器为>相连，div>p为div下的第一个p

#### 兄弟选择器

h2+p 即跟着h2的p标签

h2~p 只要前面有h2标签的p元素（不需要跟着）

### 选择器分组

就是可以用,分割多个选择器然后赋予相同的样式。

### 继承

子元素可以继承到父元素的一部分属性例如：color font text-align list-style

有些元素是不会自动继承：background border position

具体看文档

### CSS优先级计算

-a = 行内样式

-b = ID选择器的数量

-c = 类、伪类和属性选择器的数量

-d = 标签选择器和伪元素选择器的数量

value = a * 1000 + b * 100 + c * 10 + d

通过这个可以计算出优先值 优先级高的会覆盖优先级低的。

#### CSS层叠

相同的属性会覆盖：

-优先级（高的覆盖低的）

-后面覆盖前面（优先级一样的时候）

不同的属性会合并

#### 改变优先级的方法

1.改变书写位置

2.提升选择器的优先级

3.属性值后面加 !important （慎用 因为其实已经破坏了前面的规则）



