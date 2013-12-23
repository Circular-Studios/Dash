module myclass;
/*
* MyDll demonstration of how to write D DLLs.
*/

export:
MyClass getDGame()
{
	return new MyClass();
}

class MyClass
{
	int x;

	this()
	{
		x = 42;
	}

	public int test()
	{
		return x;
	}
}
