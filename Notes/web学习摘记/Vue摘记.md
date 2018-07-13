## Vue摘记

### Vue项目创建

https://cn.vuejs.org/v2/guide/installation.html

1、必须要安装nodejs

2、搭建vue的开发环境 ，安装vue的脚手架工具   官方命令行工具

npm install --global vue-cli  /   cnpm install --global vue-cli         （此命令只需要执行一次）

3、创建项目   必须cd到对应的一个项目里面
vue init webpack vue-demo01

cd  vue-demo01 

cnpm install   /  npm install          如果创建项目的时候没有报错，这一步可以省略。如果报错了  cd到项目里面运行  cnpm install   /  npm install

npm run dev	

4、另一种创建项目的方式   （推荐）

vue init webpack-simple vuedemo02

 cd  vuedemo02

 cnpm install   /  npm install       

 npm run dev	

#### 淘宝镜像 cnpm

cnpm  下载包的速度更快一些。

地址：http://npm.taobao.org/

安装cnpm:

npm install -g cnpm --registry=https://registry.npm.taobao.org



###使用vue-resource

#### 安装

  npm install vue-resource --save /  cnpm install vue-resource --save  

#### 引入（一般在main.js）

​    import VueResource from 'vue-resource'

​    Vue.use(VueResource);

#### 使用（请求数据）

   this.$http.get(地址).then(function(){

​    })

### 使用vue-routor

#### 安装

npm install vue-router  --save   / cnpm install vue-router  --save

#### 引入（一般在main.js）

import VueRouter from 'vue-router'

Vue.use(VueRouter)

	#### 使用（路由配置）

1、创建组件 引入组件
2、定义路由  （建议复制s）

	const routes = [
	  { path: '/foo', component: Foo },
	  { path: '/bar', component: Bar },
	  { path: '*', redirect: '/home' }   /*默认跳转路由*/
	]

3、实例化VueRouter

	const router = new VueRouter({
	  routes // （缩写）相当于 routes: routes
	})

4、挂载
	new Vue({
  el: '#app',
  router，
  render: h => h(App)
})
5 、根组件的模板里面放上这句话   <router-view></router-view>   
6、路由跳转
<router-link to="/foo">Go to Foo</router-link>
 <router-link to="/bar">Go to Bar</router-link>

### 传值问题

#### 1.父组件给子组件传值

##### 父组件给子组件传值

​    1.父组件调用子组件的时候 绑定动态属性

​        <v-header :title="title"></v-header> 

​    2、在子组件里面通过 props接收父组件传过来的数据

​        props:['title']  //这种不校验正确性

​        props:{

​            'title':String      

​        } //这种校验数据正确性

##### 直接在子组件里面使用

父组件主动获取子组件的数据和方法： 

​    1.调用子组件的时候定义一个ref

​         <v-header ref="header"></v-header>

​    2.在父组件里面通过

​        this.$refs.header.属性

​        this.$refs.header.方法

子组件主动获取父组件的数据和方法：  

​        this.$parent.数据

​        this.$parent.方法

#### 2.非父子组件传值(广播)

 1、新建一个js文件   然后引入vue  实例化vue  最后暴露这个实例

​      import Vue from 'vue';

​      var VueEvent = new Vue()

​      export default VueEvent;

  2、在要广播的地方引入刚才定义的实例

  3、通过 VueEmit.$emit('名称','数据')

  4、在接收收数据的地方通过 $om接收广播的数据

​    VueEmit.$on('名称',function(){

​    })