---
layout:     post
title:      '理解template类型的推导'
author:     boydfd
tags:       effective-mordern-C++ C++ template
subtitle:   'Item 1: 理解template类型的推导'
category:   effective-mordern-C++
date: 2016-01-01 00:00:00 +0800
---
> 本文翻译自《effective modern C++》，由于水平有限，故无法保证翻译完全正确，欢迎指出错误。谢谢！

一些用户对复杂的系统会忽略它怎么工作，怎么设计的，但是很高兴去知道它完成的一些事。通过这样的方式，c++中的template类型的推导取得了巨大的成功。数以万计的程序员曾传过参数给template函数，并得到了满意的结果。尽管很多那些程序员很难给出比朦胧的描述更多的东西，比如那些被推导的函数是怎么使用类型来推导的。

如果你也是其中的一员，我这有好消息和坏消息给你。好消息是template类型的推导是现代c++最令人惊叹特性之一（auto）的基础。如果你熟悉c++98的template类型推导，那么你也会熟悉c++怎么使用auto来做推导类型。而坏消息是当template类型推导规则应用在auto上时，比起应用在template中时，他们有时候看起来会比较难理解。由于这个原因，我们很有必要完全理解template类型推导的各个方面，因为auto是建立在这个基础上的。这个条款包含了你想知道的东西。

如果你愿意浏览少许伪代码，我们可以把函数模板看成这样子：

	template<typename T>
	void f(ParamType param);
对于函数的调用看起来是这样的：
	
	f(expr);
在整个编译期间，编译器用**expr**来推导两个类型：一个是**T** ，另一个是                          
**ParamType** 。这两个类型常常是不一样的，因为**ParamType**常常包含一些修饰符。（比如const或引用的限定）。比方说，如果一个template声明成这样：

	template<typename T>
	void f(const T& param);
然后我们这样使用它：

	int x = 0;
	f(x);

**T**被推导成int，但是**ParamType**被推导成const int&。
   
很自然会觉得**T**类型就是传入函数的实参类型，也就是**T** 是 **expr**的类型。
在上面的例子中，x是int，**T**被推导成int，但是它不总是这样工作的。 
对**T**类型的推导，不仅仅取决于**expr** ，同时也取决于**ParamType**。这里有三种情况：


 - **ParamType**是指针或引用，但不是一个universal引用（universal引用在#24中描述，现在，你要知道的就是，他们存在，并且左引用和右引用是不相同的）
 - **ParamType**是universal引用。
 - **ParamType**不是指针也不是引用

因此我们有三种类型的推导情况需要分析。每一个将建立在下面这个template的基础上，并如此调用:

	template<typename T>
	void f(ParamType param);
	
	f(expr);
### 情况1：参数是指针或引用，但不是一个universal引用
这种情况是最简单的情况，类型推导将这么工作：
 
1. 如果**expr**的类型是引用，忽略引用的部分。
2. 然后用**expr**的类型模式匹配**ParamType**来决定**T**。

比方说，下面的template：
   
	template<typename T>
	void f(T& param);

并且我们有这些变量声明：

	int x = 27;
	const int cx = x;
	const int& rx = x;

对于各种调用，**param**和**T**的类型推导是下面这用的：
	
	f(x);	//T是int， 		param的类型是 int&

	f(cx);	//T是const int，	param的类型是 cosnt int&

	f(rx);	//T是const int，	param的类型是 const int &

注意在第二个和第三个函数调用中，因为cx和rx是const变量，**T**被推导成cosnt int，因此**param**类型是const int&。这对调用者是很重要的。当他们传入const引用对象参数，他们希望对象是不可改动的。也就是，参数要是一个reference-to-const。这也是为什么传入一个const对象给使用**T**&参数的template是安全的：对象的const属性会被推导成**T**的一部分。	

注意在第三个例子中，即使rx的类型是引用，**T**还是被推导成非引用。这是因为第一点，在推导时，rx的引用属性被忽略了。

这些例子显示了左值引用，但是对右值引用的推导和左值引用是一样的。

如果我们把f的参数从**T&**改成 **const T&**，情况将发生小小的变化，但是不会出乎意料。cx和rx的const属性仍然存在，但是因为我们现在假设**param**是const引用，所以就没有必要把const属性推导到**T**上去了：

	f(x);	//T是int，	param的类型是 cosnt int&

	f(cx);	//T是int，	param的类型是 cosnt int&

	f(rx);	//T是int，	param的类型是 cosnt int&

同样地，rx的引用属性被忽略了。

如果**param**是一个指针（或者指向const的指针）,情况和引用是一样的：
	
	template<typename T>
	void f(T* param);
	
	int x = 27;
	const int *px = &x;
	
	f(&x);	//T是int， 		param的类型是int*

	f(px);	//T是cosnt int，	param的类型是const int*

现在你可能觉得有些困了，因为对于引用和指针类型，c++的类型推导规则是如此的自然，把他们一个个写出来是如此枯燥，因为所有的事情显而易见，就和你想要的推导系统一样。

### 情况2：参数是一个universal引用
对于一个采用universal引用参数的template，情况变得复杂。这样的参数大多被声明成右值引用（比如在函数模板采用一个类型**T**，一个universal引用的声明类型是**T&&**），但是他们表现的和传入左值参数时不同。完整的情况将在**item** 24讨论，但是这里给出一些大概内容：
	
- 如果**expr**是一个左值，**T**和**param**会被推导成左值引用，这里有两个不寻常点。第一，这是唯一一种**T**被推导成引用的情况。第二，尽管**ParamType**在语法上被声明成一个右值引用，但是他的推导类型是一个左值引用。
- 如果**expr**是一个右值，适用情况1的规则

举个例子：
	
	template<typename T>
	void f(T&& param);

	int x = 27;
	const int cx = x;
	const int& rx = x;

	f(x);	//x是左值，所以T是int&， 
			//param的类型也是int&
	
	f(cx);	//cx是左值，所以T是const int&, 
			//param的类型也是const int&

	f(rx);	//rx是左值，所以T是const int&, 
			//param的类型也是const int&

	f(27);	//27是右值，所以T是int，
			//param的类型是int&&

**item** 24解释了为什么这个例子会这样工作。这里的关键点是universal引用的类型推导规则对左值和右值是不同的。尤其是，当universal引用在使用中，类型推导会根据传入的值是左值还是右值进行区分。non-universal引用永远不会发生这样的情况。

### 情况3：参数不是指针也不是引用
当**ParamType**不是指针也不是引用时，我们处理传值（by-value）情况：
	
	template<typename T>
	void f(T param);

这意味着，**param**将成为传入参数的一份拷贝，一个全新的对象。

1. 和以前一样，如果**expr**的类型是引用，忽略引用属性。
2. 如果，在忽略**expr**的引用属性后，**expr**是const，再忽略const属性。如果是volatile的，同样忽略。（volatile对象不常见，他们通常用来实现设备驱动，详细的情况，在**item**40中讨论）

因此：

	int x = 27；	
	cosnt int cx = x;
	const int& rx = x;

	f(x);	//T和param类型相同，int
	
	f(cx);	//T和param类型相同，int

	f(rx);	//T和param类型相同，int

记住，尽管cx和rx是const变量，**param**却不是const的。这是有意义的，**param**是一个完全独立于cx和rx的对象--来自拷贝。事实上，cx和rx能不能被改变和**param**能不能被改变没有联系，这也就是为什么在推导类型的时候，**expr**的const属性被忽略了。只是因为**expr**不能被改变不意味着他们的拷贝不能被改变。

很重要的是，你要知道const（和volatile）属性被忽略只适用于传值（by-value）参数。就像我们看到的，在推导类型的时候，传引用（references-to）或传指针（pointers-to）参数的const属性是会保留的。但是我们来考虑一下**expr**是cosnt指针指向const类型的情况，并且**expr**是传值（by-value）参数：

	template<typename T>
	void f(T param);

	cosnt char* cosnt ptr = "Fun with pointers";

	f(ptr);	//T是const char，param的类型是const char*

这里，星号右边的const声明ptr是const的：ptr不能指向别的地方，也不能设为空。（星号左边的const意味着ptr指向的一个---字符串---是const的，因此不能被修改）当ptr传入f，ptr会拷贝一份，赋给**param**，因此，指针本身（ptr）将以传值（by-value）形式传入。同样的类型推导规则，传值（by-value）参数ptr的const属性将会被忽略，所以**param**的类型会被推导成cosnt char*，一个指向const字符类型的可以改变指向的指针。

### 数组参数
之前的那些已经设计到大多数主流的template参数推导了，但是，这里还有一些小部分的情况直的我们去了解。数组类型不同于指针类型，尽管有时候它们看起来可以相互替换。这个错觉主要来自于：在很多时候，一个数组可以退化成（decays）一个指向其第一个元素的指针。这个退化允许代码写成这样：
	
	const char name[] = "J.P.Briggs";
	
	const char* ptrToName = name;

这里，一个const char* 指针**ptrToname**用const char[13]的数组**name**来初始化。这些类型（cosnt char* 和 const char[13]）不一样，但是由于array-to-point的退化规则，代码可以编译。

但是，当把数组传值（by-value）传入函数时会发生什么：
	
	template<typename T>
	void f(T param);
	
	f(name);

我们从函数没有数组参数开始，是的，是的，这样的语法是合法的：
	
	void myFunc(int param[]);

但是数组的声明会被当成指针的声明，这意味着myFunc能等价地声明成：
	
	void myFunc(int* param);

这种对于数组和指针参数的等价情况是从C那边来的，并且这增加了数组和指针相同的错觉。

因为数组参数声明被对待成指针参数，通过传值（by-value）传入template函数的数组被推导成指针类型。这意味着上面的参数**T**被推导成const char*：

	f(name);	//name是数组，但是T被推导成cosnt char*

但是，现在有个问题，尽管函数不能声明真正的数组参数，但是他们可以声明指向数组的引用参数！所以，如果我们修改函数为传引用（by-references）：

	template<typename T>
	void f(T& param);

并且我们传入一个数组：
	
	f(name);

对**T**的类型推导将是真正的数组类型！这个类型包含了数组的大小，所以在这个例子中，**T**被推导成cosnt char[13]，并且**param**的类型（一个引用指向这个数组）是cosnt char(&)[13]。是的，这语法看起来有毒，但是知道这个规则会让你了解到别人很少注意的点。

有趣的是，声明指向数组的引用使我们能创造一个template来推导数组的大小：

	//在编译期返回数组大小（数组参数没有名字，因为我们仅仅为了知道数组的大小）
	template<typename T, std::size_t N>
	cosntexpr std::size_t arraySize(T(&)[N]) noexcept
	{
		return N;
	}
在**item15**中解释声明这样的constexpr的函数可以让结果在编译期返回。这使我们可以用一个数组的大小做为另一个新数组的大小来初始化新数组：

	int keyVals[] = { 1, 3, 7, 9, 11, 22, 35};

	int mappedVals[arraySize(keyVals)];

当然了，作为一个现代C++开发者，你可能更喜欢一个std::array来建立一个数组：
	
	std::array<int, arraySize(keyVals)> mappedValsl;

对于arraySize被声明为noexcept，这能帮助编译器产生更好的代码。想知道细节，可以看**item** 14。

### 函数参数

在C++中，数组不是唯一的退化成指针的情况，函数类型也会退化成函数指针，并且所有的我们对数组的推导的讨论适用于函数类型推导：
	
	void someFunc(int, double);

	template<typename T>
	void f1(T param);

	template<typename T>
	void f2(T& param);

	f1(someFunc);	//T是void (*)(int, double)

	f2(someFunc);	//T是 void ()(int, double)

这看起来几乎没有任何不同，但是，如果你已经知道了array-to-pointer的退化，你也会同样知道function-to-pointer的退化。

现在你明白了吧：函数类型推导的规则，我在开始就说他们相当简单，并且大多数情况下是这样的。对于universal引用，左值当推导的类型时需要特别对待，这使我们有点晕晕的，然而退化成指针（decay-to-pointer）的规则使得我们更加晕了。有时，你简单地想抓住你的编译器和并渴望：“告诉我你推导的类型是什么”。当发生这样的事时，转到**item** 4，因为这条款专注于让编译器去做你想它做的事（显式类型）。

##### 　　　　　　　　　　　　你要记住的事

- 在template类型推导的时候，references类型的参数被当成non-references。也就是说引用属性会被忽略。
- 当推导universal类型的引用参数时，左值参数被特殊对待。
- 当推导传值（by-value）类型参数时，cosnt 和/或 volatile 参数被当成 non-const 和 non-volatile。
- 当推导类型是数组或函数时会退化成指针，除非形参是引用。
