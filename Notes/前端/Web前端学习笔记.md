# Web前端学习笔记

## HTML

1. 文档章节标签（语义化）
   + header 头部
   + nav 导航
   + aside 边栏
   + article 文章/内容
   + section 章节 一般嵌套在article内
   + footer 尾部
   + hx 标题

## CSS

### 选择器

#### 属性选择器

+ [attr] 选择包含 attr 属性的所有元素，不论 attr 的值为何。
+ [attr=val] 选择 attr 属性被赋值为 val 的所有元素。
+ [attr~=val] 选择具有 attr 属性的元素，而且要求 `val` 值是 `attr` 值包含的**被空格分隔**的取值列表里中的一个。例如 `class="animal dog"` 可以用 `[class=dog]` 选中。
+ [attr|=val] : 选择attr属性的值是 `val` 或值以 `val-` 开头的元素（注意，这里的 “-” 不是一个错误，这是用来处理语言编码的）。
+ [attr^=val] : 选择attr属性的值以 `val` 开头（包括 `val`）的元素。
+ [attr$=val] : 选择attr属性的值以 `val` 结尾（包括 `val`）的元素。
+ [attr*=val] : 选择attr属性的值中包含子字符串 `val` 的元素（一个子字符串就是一个字符串的一部分而已，例如，”cat“ 是 字符串 ”caterpillar“ 的子字符串）。

#### 伪类选择器

+ a:link	选中href有值的a元素
+ a:visited  选中状态为已点击过的a元素
+ a:hover   选中状态为鼠标悬浮的a元素（该伪类可作用于任意元素）
+ a:active   选中状态为选中焦点（包括鼠标点击和tab选中）是的a元素（该伪类可作用于任意元素）
+ :enabled 选中状态为可用的元素
+ :disabled 选中状态为不可用的元素
+ :checked 选中状态为勾选的元素
+ :focus 选中状态为选中的表单元素
+ li:fitst-child 选中第一个li元素（该li元素必须是所有兄弟结点中的第一个结点）
+ li:last-child 选中最后一个li元素（该li元素必须所有兄弟结点中的最后一个结点）
+ li:nth-child(even/odd) 选中偶/奇数项的li元素
+ li:nth-child(3n+1) 选中第3n+1项的li元素，n是从0开始算的
+ li:nth-last-child(3n+1) 按倒序选中第3n+1项的li元素，n为0时是倒数第一项
+ li:only-child 选中作为唯一子元素的li元素
+ dt:first-of-type 选中第一个dt类型的元素（该dt元素是所有dt兄弟结点中的第一个）
+ dt:last-of-type 选中最后一个dt类型的元素（该dt元素是所有dt兄弟结点中的最后一个）
+ dt:nth-of-type(2n) 选中第2n个dt类型的元素
+ dt:nth-last-of-type(2n) 选中倒数第2n个dt类型的元素
+ dt:only-of-type() 选中唯一的dt类型的子元素。与only-child的区别是前者前者子元素中只能有一个dt元素，可以有其他类型的元素；后者指只有一个子元素。
+ :empty 选中不包含内容的空元素，例如\<p>\</p>
+ :root 选中根元素 即html元素

#### 伪元素选择器

+ ::first-letter 选中元素的第一个字符
+ ::fitst-line 选中元素的第一行
+ ::before ::after 在元素**内容**之前/后插入一些内容 例：p::before{content:""haha} 在p元素内容之前插入before，插入的内容默认为行内元素，可以使用display改变。**（注意是在元素内容前后插入）**
+ ::selection 选中被用户选中的内容

#### 组合选择器

+ A,B	匹配满足A或B的任意元素.
+ A B	匹配任意元素，满足条件：B是A的后代结点（B是A的子节点，或者A的子节点的子节点）
+ A > B 匹配任意元素，满足条件：B是A的直接子节点
+ A + B 匹配任意元素，满足条件：B是A的下一个兄弟节点（AB有相同的父结点，并且B紧跟在A的后面）
+ A ~ B 匹配任意元素，满足条件：B是A之后的兄弟节点中的任意一个（AB有相同的父节点，B在A之后，但不一定是紧挨着A

#### 选择器优先级

选择器优先级由选择器的权重决定，不同类型选择器有不同权重，组合权重值高的选择器，优先级高。

+ a = 行内样式 权重1000
+ b = ID选择器 权重100
+ c = 类、伪类和属性选择器 权重10
+ d = 标签选择器和伪元素选择器 权重1

e.m.

| 选择器      | a    | b    | c    | d    | value |
| ----------- | ---- | ---- | ---- | ---- | ----- |
| h1          | 0    | 0    | 0    | 1    | 1     |
| p > em      | 0    | 0    | 0    | 2    | 2     |
| style:""    | 1    | 0    | 0    | 0    | 1000  |
| .comment p  | 0    | 0    | 1    | 1    | 11    |
| div#content | 0    | 1    | 0    | 1    | 101   |
| a:link      | 0    | 0    | 1    | 1    | 11    |

当权重一样时，层叠覆盖，即按照解释顺序后面的覆盖前面的，也就是后面的优先级高。 

`!important`  强制指定优先级最高。例如 `p.content{color:red !import;}`

#### 浏览器支持度

关于不同浏览对各种CSS选择器的兼容性，查看  [桌面浏览器](https://www.quirksmode.org/css/selectors/) 、 [手机浏览器](https://www.quirksmode.org/css/selectors/mobile.html) 。

### 文本样式

#### 相关属性

+ font-size：字体大小

+ font-famaly：字体类型

+ font-weight：字体粗细

+ font-style：字体类型 normal|italic|oblique

+ line-height：行高 normal|\<number>|\<length>|\<percentage> 具体。当值为`<length>|<percentage>`时，行高为`font-size*（<length>|<percentage>）` 

  >line-height \<number>和\<percentage>的区别：300% 和 3 为例，假如父元素div字体大小30px，若其line-height:300%，则其子元素继承的line-height为90px；若其line-height:3，则其子元素继承的line-height为3，实际行高为子元素字体大小*3。也就是说，前者继承的是计算后的结果，后者直接继承。
  >
  >em和%同理。

+ font：以上字体样式的缩写

+ color：文本颜色 值为transparent时表示全透明

+ text-align: 内容水平对齐方式 left|right|center|justify **作用于容器**，使得块级元素内的行内元素以及行内元素的文本内容以指定方式对齐。

+ vertical-align：行内元素垂直对齐方式 baseline基线|sub下标|super上标|top居顶吗|text-top居文本顶|bottom|text-bottom|\<percentage>以baseline为基准往上走行高*\<percentage>的距离|\<length>以baseline为基准往上走length距离。**作用于行内元素或行内块级元素** 

    > 这个是水很深的属性，和line-height关系密切，有疑惑可参考文章 https://juejin.im/post/5a7d6b886fb9a06349129463

+ text-indent：首行缩进 \<length>|\<percentage>。 一般设置为2em，表示缩进两个字体大小

+ white-space：指定文本中空格、回车换行、tab、文本换行的处理方式。normal|nowrap|pre|pre-wrap|pre-line

  | 属性值             | 回车换行 | 空格/Tab | 文本换行（指当一行文本容纳不下时是否会换行） |
  | ------------------ | -------- | -------- | -------------------------------------------- |
  | normal             | 合并     | 合并     | 换行                                         |
  | nowrap             | 合并     | 合并     | 不换行                                       |
  | pre                | 保留     | 保留     | 不换行                                       |
  | pre-wrap（较常用） | 保留     | 保留     | 换行                                         |
  | pre-line           | 保留     | 合并     | 换行                                         |

  合并指合并成一个空格。

+ word-wrap：当**一个单词**(比如一个很长的单词)一行显示不下时是否换新行显示 normal不换行|break-word换行

+ word-break：当**单词**一行显示不下要换行时以何种方式换行 normal|keep-all|break-all以字符为单位换行

+ word-spacing:  单词间距 normal|\<length-percantage>

+ letter-spacing: 字符间距

+ text-shadow: 文字阴影 none|[\<length>{2,3}&&\<color>?]# 当color不写时阴影颜色为文字颜色

+ cursor: 悬浮时的光标形状 常用的是pointer 对于可点击的元素用一个手指形状的图片 

#### 盒模型

+ width/height: content部分宽度/高度 作用于块级元素

+ padding: 内边距 值对应顺序为**上右下左**（TRBL）。缩写规则：对面相等，后者省略；4面相等，只设一个。

  | 值                  | 结果                            |
  | ------------------- | ------------------------------- |
  | 10px                | TRBL==10px                      |
  | 10px 20px           | TB==10px RL==20px               |
  | 10px 20px 30px      | T==10px R==20px B==30px L==20px |
  | 10px 20px 30px 40px | T==10px R==20px B==30px L==40px |

+ margin: 外边距 值规则同padding。

  + margin合并：毗邻元素（元素之间没有其他元素、padding、border）外边距会合并，取较大值；父元素与第一个子元素的或最后一个子元素的外边距会合并，取较大值。
  + 水平居中：0 auto 块级元素水平居中

+ border: 边框 [\<border-width>||\<border-style>||\<border-color>]

+ border-radius: 圆角半径 `border-radius:0px 5px 10px 15px/20px 15px 10px 0px` 分别对用上右下左的x轴半径和y轴半径

+ overflow：设置盒子中内容超出时如何显示 visible 超出部分仍然显示|hidden超出部分隐藏|scroll可滚动（不管内容是否超出都显示滚动条）|auto超出时可滚动 

+ overflow-x/overflow-y: 对应overflow的水平方向和垂直方向

+ box-sizing: content-box|border-box 指定width/height的作用范围为内容范围还是边框范围

+ box-shadow: 盒子阴影 `box-shadow:inset 4px 6px 3px 2px red` inset表示内阴影，不写为外阴影。后面4个length值分别对应水平偏移、垂直偏移、阴影半径、阴影大小，最后为阴影颜色。阴影可多个叠加，逗号隔开。

+ outline: 轮廓  [\<outline-width>||\<outline-style>||\<outline-color>] 与boder的区别：不占空间、物理位置在border外围。主要用于链接、表单元素等可获取焦点的元素在焦点状态下展示。

#### 背景样式

+ background-color: 背景颜色

+ background-image: 背景图片 可设置多张图片，逗号隔开。可以用url引入图片，也可以用linear-gradient()/radial-gradient()绘制渐变

+ background-repeat: 背景图片展示平铺方式 常用的是no-repeat

+ background-attachment: scroll(默认 背景不随内容滚动)|fixed|local背景随内容滚动

+ background-position: 背景图片显示的位置 注意当用percentage时，是**图片的百分比点和容器的百分比位置对齐**，例如 `background-position:20% 50%` 图片沿x轴20%点与容器沿x轴20%点对齐，图片沿y轴50%点与容器沿y轴50%点对齐；因此 `background-position:50% 50%` 就是将背景图片居中，等同于`background-position:center center`。

  | 关键字 | 等同于    |
  | ------ | --------- |
  | center | 50%       |
  | left   | 沿x轴0%   |
  | right  | 沿x轴100% |
  | top    | 沿y轴0%   |
  | bottom | 沿y轴100% |

  以上所述为该样式有两个值的情况，例如`background-position:50% 50%`。除此之外也可以有4个值，例如 `background-position:right 10px top 20px`，表示图片与容器右边界相距10px，与上边界相距20px，此时的right与top就不再是上述表格中的含义了。
+ background-origin: 设置背景图片background-position的参照
  +  border-box 以边框范围为参照
  + padding-box 以内边距范围为参照（默认）
  + content-box 以内容范围为参照
+ background-clip: 设置背景裁剪
  + border-box: 裁剪边框以外的背景图片（默认）
  + padding-box: 裁剪内边距以外的背景图片
  + content-box: 裁剪内容以外的背景图片
+ background-size: \<bg-size> [,\<bg-size>]*    bg-size:[\<length>|\<percentage>|auto]{1,2}|cover|contain
  + \<percentage> 相对容器的百分比
  + auto 原始尺寸（默认） 当只有一个值时，第二个值默认为auto，表示原始比例
  + cover 以能够完全覆盖容器的最小尺寸等比显示
  + contain 以能够完全显示图片的最大尺寸等比显示
+ background: 背景缩写形式 `background：url('back.png') 0 0/20px 20px no-repeat content-box green`
  + url('back.png'): background-image
  + 0 0: background-position
  + 20px 20px：background-size
  + no-repeat：background-repeat
  + content-box： 当只有一个值时同时设置background-origin和background-clip，当有两个值时分别设置这两个属性
  + green：background-color

#### 布局样式

##### display布局
+ block：块级元素
  + 默认宽度为父元素宽度
  + 可设置宽高
  + 换行显示
+ inline：行内元素
  + 默认宽度为内容宽度
  + 不可设置宽高
  + 同行显示
+ inline-block：行内块级元素 主要是一些表单元素
  + 默认宽度为内容宽度
  + 可设置宽高
  + 同行显示，显示不下整块换行
+ none：设置元素不显示。与 `visibility:hidden` 的区别在于`display:none` 不显示且不占位置；后者不显示但会占据位置。

##### position布局

> 定位布局，使用top、right、bottom、left、z-index来定位元素位置（定位需要）。
>
> 定位布局使得元素得以重叠布局。

+ static：静态（默认），即没有使用定位的方式
+ relative：相对定位
  + 仍在文档流中
  + 定位时参照物为**元素本身**
  + 一个最常用的场景是作为**绝对定位元素的参照物**
+ absolute：绝对定位
  + 默认宽度为内容宽度
  + 脱离文档流
  + 定位参照物为**第一个定位父元素或根元素（html元素）**
+ fixed：固定定位
  + 默认宽度为内容宽度
  + 脱离文档流
  + 参照物为**视窗**

##### float布局

>浮动布局
>
>方便了列布局

+ 默认宽度为内容宽度

+ **半脱离文档流**（对元素，脱离文档流；对内容，在文档流。所谓内容指容器中的行内元素、行内块级元素以及文本内容）

+ 浮动元素在父元素容器中横向浮动（left/right），而标准流的容器是竖向排列的 

+ 由于float布局并不是完全脱离文档流的，会影响元素内容的布局，为了避免对后续容器布局的影响，往往需要对后续元素进行浮动清除，这就需要 `clear` 属性

  >应用于浮动元素的后续元素并且应用于块级元素
  >

  + none：不会向下移动清除之前的浮动
  + left：向下移动用于清除之前的**左**浮动
  + right：向下移动用于清除之前的**右**浮动
  + both：向下移动用于清除之前的**左右**浮动（常用）

  ```
  .clearfix:after {
      content:'.';
      display:block;
      height:0;
      line-height:0;
      clear:both;
      visibility:hidden;
  }
  ```

##### flex 布局

> 弹性布局 display:flex
>
> 对于弹性容器，其所有在文档流中的直接子元素都是弹性子元素

###### 方向

+ flex-direction：设置弹性容器中的子元素的排列方向 row(默认 从左向右)|row-reverse|column|column-reverse
+ flex-wrap：设置弹性容器中的子元素的换行 nowrap(默认 不换行)|wrap|wrap-reverse
+ flex-flow：\<flex-direction>||\<flex-wrap>
+ order：\<integer>设置弹性子元素的排列顺序 值大的元素排在值小的元素的后面

###### 弹性

+ flex-basis：设置弹性子元素的在主轴上的初始长度。即如果flex-direction为row，则设置的是初始宽度；若为column，设置的是初始高度
+ flex-grow：\<number> 默认为0。 用于设置当主轴上有空余空间时，弹性元素占据的空余空间的比例。元素实际占据的主轴上的长度计算公式为：`flex-basis+remain*(flex-grow/sum(flex-grow))` 其中remain为空余空间。默认为0表示元素默认不占用空余空间，即默认为flex-basis的长度；若设置为1则表示各个元素平分剩余空间
+ flex-shrink：\<number> 默认为1。 用于设置当主轴上的元素超出父容器长度时，弹性元素需要压缩的长度的比例。元素实际占据的主轴上的长度计算公式为：`flex-basis+(-remain*(flex-shrink)/sum(flex-shrink))` 其中remain为超出弹性容器部分的长度。默认为1表示各个元素默认在flex-basis的基础上压缩相同的长度。
+ flex：\<flex-grow>||\<flex-shrink>||\<flex-basis> 初始值为0 1 main-size

###### 对齐

+ justify-content：设置**容器内所有flex子元素**在主轴方向上的对齐方式 flex-start|flex-end|center|space-between|space-around **设置在弹性容器上**
+ align-items：设置**容器内所有flex子元素**在辅轴方向上的对齐方式 flex-start|flex-end|center|baseline|stretch  **设置在弹性容器上**
+ align-self：设置**单个flex子元素**在辅轴方向上的对齐方式  auto(默认 由父容器的align-items决定)|flex-start|flex-end|center|baseline|stretch **设置在弹性子元素上**
+ align-content：设置辅轴方向上**各行**对齐方式，即当容器内有多行时，各行在容器中的对齐方式。 flex-start|flex-end|center|space-between|space-around|stretch

#### 变形样式

+ transform：none|\<transform-function>+ 注意变形不管哪种操作变的都是**坐标轴**(默认x轴水平向右，y轴水平向**下**，z轴垂直向前)，因此当有多个变形时，不同的顺序会有不同的结果。例如 `transform:rotate(45deg) translate(50px) ` 和 `transform:translate(50px) rotate(45deg)` 结果是不一样的。此处的坐标轴指的是始终以元素中心点为坐标原点的X、Y轴线。
  + rotate()/rotateX()/rotateY()： 旋转 注意旋转的是坐标轴 e.m. `rotate(45deg)` 整体向右旋转45度。另外默认为沿Z轴，即二维的旋转。rotateX()和rotateY()分别为沿X轴和沿Y轴的旋转，呈现3D效果。
  + translate()/translateX()/translateY()：平移 e.m. `translate(40px,50%)` x轴方向偏移40px，y轴偏移自身高度的50%
  + scale()/scaleX()/scaleY()：缩放 e.m. `scale(1.5)` 整体放大1.5倍
  + skew()/skewX()/skewY()：倾斜 注意倾斜的是x轴/y轴 e.m. `skew(30deg,60deg)`  y轴往x轴的正方向倾斜30度，x轴往y轴的正方向倾斜60度。

  以上变形操作都是2维的，自然是有3维的变形操作：

  + rotate3d()：3维旋转 可产传3个参数 单传Z轴旋转可以用rotateZ()

  + translate3d()：3维平移 可传3个参数 单纯Z轴平移可以用translateZ()
  + scale3d()：3维缩放 可传3个参数 单纯Z轴缩放可以用scaleZ()

+ transform-origin：设置坐标轴的位置，介绍transform说过默认以元素中心点为原点，也就是默认为`transform-origin:50% 50%`

+ perspective：设置透视效果 none|\<length> 值越小，相当于人眼到物体的距离越近，透视效果越明显。注意，要呈现真实3D效果，就要设置perspective，否则呈现的是扁平3D效果。

+ perspective-origin：设置透视位置，默认为`perspective-origin:50% 50%`

+ transform-style：flat|preserve-3d 设置当变形元素嵌套时，内部的变形元素是呈现扁平效果还是透视效果

+ backface-visibility：visible|hidden 设置3D背面是否展示

#### 动画样式

##### transition动画

> 简单动画 动画需要主动触发；只能用于简单的一个状态向另一个状态转变的动画，即不支持多帧

+ transition-property：设置动画属性 none|\<single-transition-property>[, \<single-transition-property>]\*   single-transition-property用来指定需要动画的属性，例如left、color等。默认为all
+ transition-duration：设置动画时间
+ transition-timing-function：设置动画时间函数 主要有以下几种类型
  1. ease|linear|ease-in|ease-out|ease-in-out
  2. cubic-bezier(\<number>,\<number>,\<number>,\<number>) 贝塞尔曲线
  3. step-start|step-end|step(\<integer>[,[start|end]]?) 按步动画 \<integer>为步数
+ transition-delay：设置动画延迟开始执行时间 `transition-delay:2s` 表示延吃2s执行动画
+ transition：缩写 \<single-transition>[, \<single-transition>]\* where \<single-transition>=[none||\<single-transition-property>||\<time>||\<single-transition-timing-function>||\<time>]  e.m. `transition:left 2s ease 1s` 表示：left属性，动画时间2s，动画方式为ease，延迟1s执行

##### animation动画

> 关键帧动画 页面加载即可触发动画；支持多帧动画

@keyframes：定义关键帧动画 下面定义了两个关键帧动画

```
@keyframes abc {
    from{opacity:1; height:100px;}
    to{opacity:0.5;height:200px;}
}
```

```
@keyframes abcd {
    0%,50%,100% {opacity:1;}
    25%,75% {opacity:0;}
}
```

+ animation-name：设置关键帧动画，值为定义好的关键帧动画名，可设置多个 \<single-animation-name> [, \<single-animation-name>]\*

+ animation-dutation：设置动画时间

+ animation-timing-function：设置动画时间函数

+ animation-iteration-count：设置动画执行次数 inifite|\<number>  默认为1次,initite表示无限执行

+ animation-direction：设置动画执行的方向 normal|reverse|alternate|alternate-reverse 

  + normal：默认 表示从动画从第一帧执行到最后一帧
  + reverse：表示动画从定义的最后一帧执行到第一帧
  + alternate；表示在normal的基础上往返执行动画
  + alternate-reverse：表示在reverse的基础上往返执行动画

+ animation-play-state：设置动画状态 running执行|paused暂停

+ animation-delay：设置动画延迟开始执行时间

+ animation-fill-mode：设置动画开始/结束时保持的状态：none|backwards|forwards|both

  + none：不做设置 默认 即动画开始前和结束后都回到原始的状态
  + backwards：动画开始时保持第一帧的状态
  + forwards：动画结束时保持最后一帧的状态
  + both：动画开始时保持第一帧的状态，结束时保持最后一帧的状态

+ animation：动画缩写：\<single-animation>[, \<single-animation>]\* where \<single-animation>  = \<single-animation-name>||\<animation-dutation>||\<single-animation-timing-function>||\<animation-delay>||\<single-animation-iteration-count>||\<single-animation-direction>||\<single-animation-fill-mode>||\<single-animation-play-state>

  e.m. `animation:abc 1s 2s both,abcd 2s both;` 表示动画abc执行1s，延迟2s执行，保留动画执行状态；动画abcd执行2s，保留动画执行状态


#### 常用操作

1. 文本单行显，显示不下时显示...

   ```
   white-space:nowrap; //指定不换行 即单行显示
   overflow:hidden; 	//指定溢出部分裁剪
   text-overflow:ellipsis;	//指定溢出情况下用...显示
   ```

2. 文本换行常用模式：

   ```
   word-break: break-all;	//换行模式以字符为单位换行
   word-wrap: break-word;	//当一个单词一行显示不下时截断换行
   ```

3. 多行本文显示不下显示...

    ```
    overflow:hidden;
    text-overflow:ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;	//目标行数
    -webkit-box-orient: vertical;
    ```

#### 小记

1. 一个元素的padding，若值为百分比，那么其参照对象是其父元素的宽度，即使对于 `padding-bottom` 和 `padding-top` 也是如此。

2. 100vm = 浏览器视窗宽度

3. 设置opacity会使所有子元 素一起透明，若想单纯设置背景透明就用rgba设置背景色。

4. 隐藏元素的几种方式：

    | 隐藏方式            | 是否占用布局？ | 是否保持交互？ | 是否可被读屏软件捕捉？ |
    | ------------------- | -------------- | -------------- | ---------------------- |
    | opacity:0;          | Y              | Y              | Y                      |
    | visibility: hidden; | Y              | N              | N                      |
    | display: none       | N              | N              | N                      |

5. 对于 `:last-of-type` 和 `last-child` 伪类的深入认识。

    ```html
    <body class="body">
      <h1 class="X">这是标题</h1>       <!--A-->
      <h1 class="X">这是标题2</h1>      <!--B-->
    
      <p class="X">这是第一个段落。</p>     <!--C-->
      <p class="X">这是第二个段落。</p>     <!--D-->
      <p class="X">这是第三个段落。</p>     <!--E-->
      <p class="Y">这是第四个段落。</p>     <!--F-->
    
      <div>div 111</div>            <!--G-->
      <div class="X">div 222</div>  <!--H-->
    </body>
    ```

    首先看`:last-of-type`，选择器如下：

    ```css
    .X:last-of-type {
    	background: #ff0000;
    }
    ```

    最终背景变红的不只是H，而是B和H。原因分析：当`last-of-type`作用于类名时，首先找出所有类名符合的兄弟元素（除了F、G，其他都符合，也就是ABCDEH都命中）；其次根据类名前面指定的元素类型，找兄弟节点中的最后一个同类型元素，若类名前未指定元素类型，则所有类型都找（此处没有指定元素类型，故h1、p、div都找，最终命中BFH）。最后，把这两个条件命中的元素取交集（ABCDEH∪BFH = BH），最终结果为BH。

    而对于下面选择器，则只命中H：

    ```css
    div.X:last-of-type{
    	background: #ff0000;
    }
    ```

    总结一下，命中`:last-of-type`有两个条件：**1.类名符合；2.同种元素类型的最后一个兄弟节点。** 根据这个规则，可以看到这个系列的伪类可能同时命中多个节点。

    再看 `:last-child` ，它相对简单多了。例如：

    ```css
    .X:last-child {
        background: #ff0000;
    }
    ```

    命中H，因为它的命中条件是：**1.兄弟节点中的最后一个节点 2.符合类名。** 因此如果换成 `p.X:last-child` 或者 `.Y:last-child` 都是不会命中任何节点的。根据这个规则可以看到，这一系列的伪类只可能命中一个节点。

6. `input` 标签有默认宽度，不同浏览器宽度不一样，通常宽度是若干个字符大小。

7. 消除inline-block元素之间的间隙的几种方法（产生的原因是元素之间换行产生看不见的空格）[参考文章](https://www.zhangxinxu.com/wordpress/2012/04/inline-block-space-remove-%E5%8E%BB%E9%99%A4%E9%97%B4%E8%B7%9D/)

    + 上一个元素尾标签与下一个元素开标签不换行，或者中间用注释衔接

    + 父元素font-size设置为0

    + 省略元素的闭合标签，只保留最后一个

        ```
        <div class="space">
            <a href="##">惆怅
            <a href="##">淡定
            <a href="##">热血</a>
        </div>
        ```

        