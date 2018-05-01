---
layout:     post
title:      '从Best Practice到Best Practice'
subtitle:   '如何看待Best Practice'
author:     boydfd
tags:       bestPractice thinking
category:   bestPractice
date: 2018-05-01 10:19:00 +0800
---

### 什么是Best Practice

> A best practice is a method or technique that has been generally accepted as superior to any alternatives because it produces results that are superior to those achieved by other means or because it has become a standard way of doing things, e.g., a standard way of complying with legal or ethical requirements.
--摘自wiki。

简单地来说，Best Practice就是被“普遍”接受的“最优”的技术或方法，或者说它就是标准。

### 接触Best Practice
相信很多人都曾搜索过Best Practice，比如说：

- 写Dockerfile的Best Practice说：
- Redux的Best Practice
- Hibernate的Best Practice
- RESTful设计的Best Practice
- 等等...

又或者，我们都曾在一个技术能力很强的团队待过，被熏陶了一些Best Practice，比如说：

- 我们要用CSS Modules或者CSS in JS来替换传统的全局CSS。
- 我们要充分利用Java8的Stream、Lambda、Method Reference来提升我们的代码质量

再或者，我们会遵守一些不需要人讲，我们已经默认为是Best Practice的东西：

- 我们要有代码检查
- 我们要注意Code smell
- 我们要小步提交

### 我与Best Practice
我和很多人一样，我也很喜欢Best Practice。在学习新技术的时候，大多数情况我喜欢去看看这个技术的Best Practice是什么，然后就严格遵守。

前几天，我也依旧保持着这个习惯，我看到项目（React）中所有的css用的都是全局的，也没有eslint，当然我内心的第一反应就是“小恶心”了一下。

然后我们就找了同事问，我们是不是可以加css module或styled component，是不是可以加eslint。然后同事说现在很多代码已经是这样的了，我们项目太紧，加组件或加lint会耽误进度，这些要不都先不加了。我的第一反应是“哈？这些不应该是写代码的前提么？”，这观点有点颠覆我的世界观，我应该再争取一下。然后我就又阐述了一遍我的观点，然后同事就问我，加eslint和css module有什么好处，为什么一定要加，我就照着我理解的好处讲了一下，这一刻我突然意识到了一点，我对于它们的好处理解得并不深刻。我所列举的好处，并不能打动别人（这些好处是不是能在当前的情景下，更好地match我们的目标--完成交付）。

其实相同的事情之前也发生过，比如我曾多次和同事讨论过要遵循RESTful标准，要将一切docker化，以及等等因为我觉得违反了Best Practice而产生的讨论。

但是，这几天我才注意到一件很恐怖的事情。对于很多Best Practice，我只知道去遵循它，却没去追寻过它背后的advantages，或者说没有去深入了解过。

### 反思Best Practice

在Best Practice上，我们是否曾盲目遵守过：

- 在设计API的时候，我们是否曾因为某个API不是RESTful而去质疑过，但是我们却不知道不遵守RESTful到底会发生什么，到底会打破什么。
- 我们在用Java8的Stream和Lambda的时候，有没有想过为什么要用？它们能给我们的代码带来什么好处。
- 我们为什么要有代码检查。
- 我们为什么小步提交。

这些看似真理的东西，如果我们都没有去仔细斟酌过背后支撑它们的依据，那么我们就落入了Best Practice的陷阱中去了。

因为Best Practice并不一定是Best Practice。有的Best Practice是需要分场景的。

### 不同的Best Practice

Best Practice也是分为类型的：

1. 显型Best Practice，如果我们不遵守这种类型的Best Practice，那么我们立即会有反馈，或者立即会break一些东西。比如：
    写Dockerfile的Best Practice。如果我们不遵守写Dockerfile的Best Practice，那么我们就一定会让我们的Image体积变大，或者让我们build docker时候变慢。
2. 隐形Best Practice，如果我们不遵守这种类型的Best Practice，那么我们一点点损失某些东西。比如：
    - 如果项目不做代码检查，就有可能增加阅读成本，也没法依靠检查提早发现问题或Bug:
        - 一行超过一个屏幕的代码，我还要靠键盘或触摸板才能读完。
        - 我们不小心把常量SOME_CONSTANT写someConstant时，看代码时需要先去翻看一下声明才知道这是个常量。
        - 因为运算符优先级导致代码写错了。
    这种类型的Best Practice带来的好处是隐形的，你无法说我遵守了，就一定能给我带了多少具体的好处，因为当你一直遵守的时候，你是没法体会Best Practice将痛苦剔除的那份快感的。除非你是先在没引入Best Practice时痛苦了很长一段时间，然后再引入Best Practice后，你感受到，啊~~~之前的痛苦都不见了。

### Best Practice要基于的场景

Best Practice一定是对的，但是说它的绝对正确是因为一个Best Practice的定义一定是基于一个给定场景的，当给定场景固定下来后，那么按照Best Practice做就不会错。

然而，现实总是多变的，我们在了解一个Best Practice的时候，一定要先去弄明白它的应用场景是什么，然后结合自己的场景，并结合Best Practice的advantages，或者说它能解决的痛点，我们才能大胆地说，我们现在要不要应用这个Best Practice。

#### 举个例子：

在写Dockerfile的时候，我们确实要遵循Best Practice，如果我们发现之前写的一个Dockerfile没有遵循Best 
Practice，比如说在apt-get 完之后没有清除下载的缓存，我们就会想要去更改它，并遵循Best 
Practice。

但是我给出一个真实的场景，之前我们在客户现场，网络特别糟糕，要下载东西需要很久，甚至因为网络不稳定，会出现突然中断没发下载的情况。这个时候，image
大小多个10m，20m什么的就不想去care了，因为如果遵循Best Practice有更让人窝心的问题存在。所以这一天只要还在客户现场，就只能先忍受着，回家后在优质的网络下再去表示我们对Best 
Practice的尊重。



### 总结

正如[德雷福斯模型](https://zh.wikipedia.org/wiki/%E5%BE%B7%E9%9B%B7%E7%A6%8F%E6%96%AF%E6%A8%A1%E5%9E%8B)的5个阶段所说：
作为新手，我们可以只去执行recipe，不去思考Best Practice背后的原理以及背后的原理。
但是要想从新手进阶为高级新手甚至胜任者，那么我们要更多地思考Best Practice背后的原理，尤其是隐形的Best Practice，多去考虑它们背后的依据是什么。

我们从只知道只执行Best Practice进阶到深入Best Practice并学会思考它的应用场景。
