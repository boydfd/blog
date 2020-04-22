---
layout:     post
title:      'Floyd–Warshall算法'
subtitle:   'O(n^3)的求解全源最短路径方法'
author:     boydfd
tags:       algorithm
category:   algorithm
date: 2018-04-01 20:19:00 +0800
---

最近看作业的时候，发现候选人用了Floyd–Warshall算法，这燃起了我失联N久的算法之心，由这个算法入手，重新再学习学习算法。

# 阅读前提

首先这个算法会涉及到[动态规划](https://zh.wikipedia.org/wiki/%E5%8A%A8%E6%80%81%E8%A7%84%E5%88%92)
，wiki上有说明，我就不详细讲了。

# 算法简介

直接摘自wiki：

![principle](https://gitlab.aboydfd.com/boydfd/pictures/-/raw/master/Floyd%E2%80%93Warshall/principle.png)

# 算法解析

乍一看，感觉这算法很简单，就只有一个规则，然后就能找出所有节点的最短路径，其实这短短的公式中蕴含了足够的知识量。

### 动态规划
Floyd–Warshall算法的动态规划思路着眼于"中间点"，公式中的k就是这样一个中间点。

首先，假设图G的所有节点为V={1,2...,n}，我们取一个子集{1,2...k}，这里k<n，对于任意的i,j属于V，它们的中间节点都取自{1,2...k}，并且设p是最短路径。

1. 如果k不是路径p上的点，那么p上的所有节点属于集合{1,2...,k-1}，显然由{1,2...,k-1}组成的最短路径p也是{1,2...,k}的最短路径p。

2. 如果k是路径p上的点，那么我们先从{1,2...,k-1}中找到p的两条子路径p1：i->...->k,p2：k->...->j，（注意，我们让k成为了端点，所以这两条子路径才可以以{1,2...,k-1}为中间点）
我们就可以得知p=p1+p2,这里我们利用一个公理（最短路径的子路径也是最短路径）得知p1和p2必须是最短路径。

3. 考虑到如果没有中间点的情况，我们的最短路径就定义为Wij也就是i到j的权重。

4. 所以最后我们就得到了:
	
![formula](https://gitlab.aboydfd.com/boydfd/pictures/-/raw/master/Floyd%E2%80%93Warshall/formula.png)

5. 当k>=1时的情况，我们之所以能这么写，是因为，最短路径只有一条，要么是通过k的，要么是不通过k的，短的那一条，必定是最短路径了。

### 伪代码
	let dist be a |V| × |V| array of minimum distances initialized to ∞ (infinity)
     for each vertex v
        dist[v][v] ← 0
     for each edge (u,v)
        dist[u][v] ← w(u,v)  // the weight of the edge (u,v)
     for k from 1 to |V|
        for i from 1 to |V|
           for j from 1 to |V|
              if dist[i][j] > dist[i][k] + dist[k][j] 
                 dist[i][j] ← dist[i][k] + dist[k][j]
             end if

这里为了节约空间，直接在原来空间上进行迭代，其实:

	if dist[i][j] > dist[i][k] + dist[k][j] 
       dist[i][j] ← dist[i][k] + dist[k][j]
可以理解为:

	if dist[k-1][i][j] > dist[k-1][i][k] + dist[k-1][k][j] 
        dist[k][i][j] ← dist[k-1][i][k] + dist[k-1][k][j]
    else
        dist[k][i][j] ← dist[k-1][i][j]
                                     
这里k是我们选择的中间节点，k的选择会从0开始，然后一直到n。由上面的推导，很容易能得出有d(k)ij就是：以{1,2...k}为中间点，从i到j的最短路径。那么d(n)ij就是我们要的最终结果，全图的最短路径都包含在这里面了。
ij都存下来，我们就得到了最终结果。

### 重点

这里的关键就是先理解由上而下的推论，也就是：
1. k如果属于最短路径上的中间节点，那么最短路径就是{1,2,...k-1}中间节点组成的最短路径i->...->j。
2. k如果不属于最短路径上的中间节点，那么最短路径就是{1,2,...k-1}中间节点组成的最短路径p1：i->...->k和p2： k->...->j。
3. 这里k的最短路径总是能由"{1,2,...k-1}中间节点组成的最短路径"来决定，是很重要的！！

然后我们由下而上地组建我们的d(k)ij：由{1,2...k}中间节点组成的最短路径ij，最后完成我们的d(n)ij。

### 一个栗子

![process](https://gitlab.aboydfd.com/boydfd/pictures/-/raw/master/Floyd%E2%80%93Warshall/process.png)
