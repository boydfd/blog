---
layout:     post
title:      '如何写一个好的测试'
subtitle:   ''
author:     boydfd
tags:       TDD test GWT 
category:   test
date: 2020-03-01 14:00:00 +0800
---

[博客原文地址]()

## 背景

在上一个项目上，由于项目成员大部分是新入职的同事，所以对于测试不是很熟悉，
这就导致了在项目前期，项目上的很多测试都不太make sense，虽然没有什么定量的东西来描述，
但是总结起来就2个点:

1. 测试的名字比较模糊。
2. 测试代码不易读。

## 深入剖析

### 测试名字比较模糊

对于这一个问题，是因为很多刚开始写测试的开发脑子里不会快就想到given、when、then这三个词，
一般我们写测试写得比较多的同事，都会使用`should_return_xxxx_when(if)_xxxx`。其实就是在脑子中
想到了given、when、then。而新同事照着模仿的时候，很可能就单纯地写了`should_xxx`。他们只考虑了结果，
但是没有考虑条件，这就导致了读名字还是get不到测试想要干什么。

对于这个问题，我想起了多年前在stackoverflow上面看到的一种写测试名字的模板，他是这样推荐的：
`GivenA_WhenB_C`，我觉得这中写法挺好的，所以在项目中用了起来，结合实际使用，我又对此提出了两个改进:
1. given when这两个词可以省略，当然前提是我们约定了最前面就是given，中间就是when，最后就是then。
通过施加规则限制来缩短测试名。
1. 测试名字常常很长，一大堆驼峰其实比较不容易阅读。所以可以使用蛇形命名法，但是这样就需要想一个符号来
分隔given、when、then了，我选择使用`___`(也就是3个`_`)，因为经过试验，发现2个`_`太短了不容易一眼看出分隔
4个则又没有必要。

最终的效果是这样的（这是一个例子，来自最近我参加的DDD进阶培训中的[训练题](https://github.com/boydfd/parking-lot)）：
```java
parking_order_is_natural_order___park_cars_by_parking_assistant___car_parked_to_correct_parking_lot_in_turn
car_is_already_took___take_back_car_with_used_receipt___exception_is_thrown
parking_lot_is_available___park_a_car_by_parking_assistant___receipt_returned
car_is_parked___take_back_car_with_invalid_receipt___exception_is_thrown
```

这里还有一个小技巧，如果一个测试真的没有given的时候，或given不重要的时候，可以省略，但是`___`不能省略：

`___xxx_xxx___xxx_xxx`

可以总结一下这种命名方式的优点：
1. 能制定一个规则的话，项目上的测试标题能更容易统一（可以说是统一语言了）。还可以加上静态检查，使得一些名字不规范的测试提前被发现
名字不规范，说明是新进项目的同事写的，确实要重点检查一下。
2. 强制规定出given、when、then，那么，我们在写测试的时候，就会被强迫想清楚我们的测试要做什么。
3. 结构化的东西更适合大脑阅读，读测试的时候更容易，我们不需要先读一遍测试名才能提取到given、when、then，可以一眼就定位出三个部分。

当然，也是有缺点的：
我用这种方式写出来的测试名字一般都比较长，这个有可能是我用词还不够精炼，在given、when的部分可能有时候是有一部分重复的
所以也需要刻意练习，学会精简用词。

最后，给这种命名方式命个名吧，就叫**GWT测试命名法**好了。

### 测试代码不易读

我在项目上发现，很多人习惯在构建fake数据的时候直接将所有信息屏蔽，就提供一个createX()的方法，
在createX的方法里面可能还要构建X的构成部分：

```java
X createX() {
Y yyy = new Y;
X xxx = new X(YYY, field1, field12);
return xxx;
}
```

除了createX外还有createAX、createBX，然后在不同的测试里面混合调用。
作为看测试的我，我就很难看到到底需要一个怎样的场景，field1到底是怎么设置的，field2到底是怎么设置
的，而且在想改一下createX的时候，还会牵扯到其他的测试莫名其妙就挂了。

我目前使用的解决方式是这样的：
1. 先要确定好测试要涉及到的重要信息，比如上面如果field1，field2都会对测试的逻辑起到作用，
那么，即使冗余，也一定要写在测试方法内。比如:

    ```java
    @Test
    void ___xxx___xxx() {
    Y y = createY();
    X x = createX(field1, field12, y)
    // do some thing
    // assert some thing
    }
    ```
    这么做的好处是，当我要看某一个测试的时候，它的前置数据我一眼就能看出来，不需要不停地command+b跟进去才知道需要什么。

2. 在应用第一条原则的时候，一定要记得，只罗列出这个测试所关心的数据。假如field3完全不参与这次
逻辑的处理，又必须要有值，那么，在createX内部给个默认值即可，不需要放在createX参数列表中。

####
为什么不适用builder？

其实之前也试过用builder，但是看起来太多了，适用create的方式能缩短要写得代码行数，更容易一眼看完测试。

