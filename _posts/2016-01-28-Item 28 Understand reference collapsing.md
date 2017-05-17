---
layout:     post
title:      '理解引用折叠'
author:     boydfd
tags:       effective-mordern-C++ C++
subtitle:   'Item 28:理解引用折叠'
category:   effective-mordern-C++
date: 2016-01-01 00:00:00 +0800
---

> 本文翻译自《effective modern C++》，由于水平有限，故无法保证翻译完全正确，欢迎指出错误。谢谢！

Item 23说过，当一个参数被传给模板函数时，不管这个参数是左值还是右值，模板参数的类型推导都会对参数进行编码。那个Item没有解释这样的情况只在实参被用在初始化一个universal引用类型的型参时才会发生，但是它没有解释是有理由的：universal引用在Item24之前没有被介绍过。同时，这些关于universal引用以及左右值编码的观察报告说明了对于这个模板：

	template<typename T>
	void func(T&& param);

无论传给param的参数是左值还是右值，被推导出来的模板参数T将会被编码。

编码的机制很简单。当一个左值做为一个参数传入时，T被推导为一个左值引用。当一个右值被传入时，T被推导为没有引用。（记住这种不对称：左值被编码成左值引用，但是右值被编码成没有引用。）因此：

	Widget widgetFactory();		// 函数返回右值

	Widget w;					// 一个变量（一个左值）

	func(w);					// 用左值调用函数;
								// T被推导为Widget&

	func(widgetFactory());		// 用右值调用函数;
								// T被推导为Widget

两个对func的调用中，Widget都被传入了，但是因为一个Widget是左值，一个是右值，模板参数T被推导成了不同的类型。就像我们马上要看到的一样，这个特性就是能决定universal引用成为右值引用或左值引用的关键，它同时也是std::forward能完成其工作的底层机制。

在我们进一步观察std::forward和universal引用之前，我们必须注意到，在C++中对引用进行引用是非法的。也许你应该尝试去声明一个，你的编译器会谴责你：

	int x;
	...
	auto& &rx = x;				// 错误！不能声明引用的引用

但是想想当一个左值被传给以universal引用为参数的函数模板时发生了什么：

	template<typename T>
	void func(T&& param);		// 和之前一样

	func(w);					// 用左值调用func;
								// T被推导为Widget&

如果我们使用被推导出来的T类型（也就是Widget&）来实例化模板，我们得到了：

	void func(Widget& && param);

一个引用的引用！并且到目前为止，编译器并没有发出抗议。我们从Item 24中知道，这是因为universal引用param被一个左值初始化，param的类型应该是一个左值引用，但是编译器得到T的推导类型后是怎么用最终的签名来替换原来的签名的？最终的签名是这样的：

	void func(Wiget& param);

答案是引用折叠。是的，虽然通过你自己声明一个引用的引用是被禁止的，但是编译器可能在特定的环境下创造出引用的引用，模板实例化就是其中的一个场景。当编译器生成引用的引用时，引用折叠规定了接下来会发生什么。

我们有两种引用（左值和右值），所以引用的引用一共有4种可能的组合（左值到左值，左值到右值，右值到左值，右值到右值）。如果一个引用的引用在被允许的环境（比如，在模板实例化中）下出现了，引用会折叠成单个引用，并遵循以下规则：

	如果两个引用中有任何一个引用是左值引用，结果是一个左值引用。不然的话（也就是，两个引用都是右值引用），结果会是一个右值引用。

在我们上面的例子中，被推导Widget&类型让模板函数产生了一个右值引用的左值引用，做为其替代品，引用折叠告诉我们结果是一个左值引用。

引用折叠是让std::forward正常工作的关键部分。就像Item 25解释的那样，std::forward被用在universal引用的参数上，所以一个常见的使用情况看起来像是这样：

	template<typename T>
	void f(T&& fParan)
	{
		...										// 做了一些工作

		someFunc(std::forward<T>(fParam));		// 转发fParam给someFunc
	}

因为fParam是一个universal引用，我们知道无论被传给f的参数（也就是用来初始化fParam的表达式）是左值还是右值，类型参数T将被编码。所以只有当被传给f的参数是一个右值，T被编码成非引用类型时，std::forward函数会将fParam（一个左值）转化为右值。

这里给出std::forward怎么实现才能做到上面所说的工作：

	template<typename T>						// 在命名空间std中
	T&& forward(typename
				remove_reference<T>::type& param)
	{
		return static_cast<T&&>(param);
	}
	
这和标准形式没有完全一样（我省略了一些接口细节），但是它们之间的不同之处对于理解std::forward是怎么工作的影响不大。

假设传给f的参数是一个Widget类型的左值。T会被推导成Widget&，然后对std::forward的调用将被实例化成std::<Widget&>。将Widget&插入到std::forward的实现中，将会产生如下代码：

	Widget& && forward(typename
						remove_reference<Widget&>::type& param)
	{ return static_cast<Widget& &&}(param); }

type trait std::remove_reference<Widget&>::type 产生了Widget（看Item 9）类型，所以std::forward变成了：

	Widget& && forward(Widget& param)			// 还是在std命名空间中
	{ return static_cast<Widget&>(param); }

就像你看到的那样，当一个左值参数被传给临时函数f，实例化后的std::foward的参数和返回值都成了左值引用。在std::forward的中的转换没有做任何事情，因为参数的类型已经是Widget&了，所以将它转换成Widget&是没有效果的。因此一个左值类型的参数被传给std::forward后将会返回一左值引用。根据定义，左值引用是左值，所以传入一个左值给std::forward酱让一个左值被返回，就和我们期望的一样。

现在假设被传给f的参数是一个Widget类型的右值。这种情况下，f的类型参数T将被推导成Widget。因此，在f的函数调用中，std::forward将被推导成std::<Widget>。在std::forward中用Widget来代替T就能得到这样的实现：

	Widget&& forward(typename 
						remove_reference<Widget>::type& param)
	{ return static_cast<Widget&&>(param); }

对一个非引用类型的Widget使用std::remove_reference将产生Widget一开始的类型（也就是Widget），所以std::forward成了下面这个样子：
	
	Widget&& forward(Widget& param)
	{ return static_cast<Widget&&>(param); }

这里没有引用的引用，所以这里没有引用折叠，并且这是std::forward调用的最后一个实例化版本。

从一个函数返回的右值引用被定义成右值，所以这种情况下，std::forward将会把f的参数fParam(一个左值)变成一个右值。最后的结果就是，一个被传给f的右值参数将被当成一个右值转发给别的函数，这完全就是我们想要它发生的。

在C++14中，由于std::remove_reference_t的存在，使得我们能将std::forward实现得更加简洁一些：

	template<typename T>						// C++14; 还是在std的
	T&& forward(remove_reference_t<T>& param)	// 命名空间中
	{
		return static_cast<T&&>(param);
	}

引用重叠会在4中情况下发生。第一种也是最常见的情况是模板的实例化。第二种auto变量的类型推导。它的实现细节在本质上和模板的类型推导是一样的，因为对auto变量的类型推导以及对模板参数的类型推导在本质上是一样的。再次考虑来自本Item前面的例子:

	template<typename T>
	void func(T&& param);

	Widget widgetFactory();			// 返回右值的函数

	Widget w;						// 一个变量（是一个左值）

	func(w);						// 使用左值调用func；T被推导
									// 成了Widget&

	func(widgetFactory());			// 使用右值调用func；T被推导
									// 成了Widget

同样的形势也出现在auto中。这个声明：

	auto&& w1 = w;

用一个左值来初始化w1，所以auto会被推导成Widget&类型。将Widget&插入到w1
的auto声明式中会产生出这样的引用到引用的代码，

	Widget& && w1 = w;

经过引用折叠之后，会变成：

	Widget& w1 = w;

最后，w1就是一个左值引用了。

另一方面，这个声明式，

	auto&& w2 = widgetFactory();

用右值来初始化w2，使得auto会被推导成非引用的Widget类型。将auto替换成Widget会使我们得到这样的代码：

	Widget&& w2 = widgetFactory();

这里没有引用的引用，所以我们已经做完了；w2是一个右值引用。

我们现在能够完全理解在Item 24被引入的universal引用了。一个universal引用不是一个新的引用，实际上，当满足两种条件的时候，它是一个右值引用：

	- 类型推导将会区分左值和右值。左值类型的T被推导成T&，右值类型的T将产生T作为它们的推导类型。
	- 发生了引用折叠。

universal引用的概念很有用，因为它能将你从折叠的存在中解放出来，使得你只用在心里用左值或右值推导不同的类型??????????????????????????

我说过这里有4种情况，但是我们还只讨论了两种：模板实例化和auto类型推导。第三种情况是使用typedef和别名声明的。如果在创造或评估typedef的时候，引用的引用出现了，引用折叠会介入来消除它们。举个例子，假设我们有一个Widget类模板，并且在其中潜入一个右值引用类型的typedef，

	template<typename T>
	calss Widget {
	public:
		typedef T&& RvalueTefToT;
		...
	};

并且假设我们使用一个lvalue引用类型来实例化了一个Widget：

	Widget<int&> w;

在Widget模板种用int&来替换T让我们得到如下的typedef：

	typedef int& && RvalueRefToT;

引用折叠将它变成了这个样子，

	typedef int& RvalueRefToT;

它很清晰地描绘了一个场景，就是我们给typedef的命名并没有描述出我们想要的东西：当使用一个左值引用来实例化Widget的时候，RvalueRefToT是一个左值引用。

最后一种引用折叠的情况就是在decltype中。如果在调用decltype并进行类型分析的时候，引用的引用出现了，那么引用折叠就是介入来消除它。（关于decltype的信息，请看Item 3。）

##### 　　　　　　　　　　　　你要记住的事
- 重载universal引用常常导致universal引用版本的重载被调用的频率超过你的预期。
- 完美转发构造函数是最有问题的，因为比起非const左值，它们常常是更好的匹配，并且它们会劫持派生类调用基类的拷贝和move构造函数。