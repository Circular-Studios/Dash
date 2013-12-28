module scripting.scripts;
import utility.config, utility.filepath, utility.output;

import core.runtime, core.demangle;
import std.array, std.conv;

version( Windows )
{
	import std.c.windows.windows;
}
else version( Posix )
{
	import core.sys.posix.dlfcn;
}

static class Scripts
{
static:
public:
	void initialize()
	{
		string dllpath = Config.getPath( "Scripts.FilePath" );

		version( Windows )
		{
			//auto handle = Runtime.loadLibrary( dllpath );
			scriptDll = cast(HMODULE)Runtime.loadLibrary( dllpath );
		}
		else version( Posix )
		{
			scriptDll = dlopen( dllpath, RTLD_LAZY );
		}

		if( scriptDll is null )
		{
			Output.printMessage( OutputType.Error, "Error loading dll file." );
			return;
		}

		auto object = callCtor!Object( "myclass.MyClass" );//ctor( new Object );

		auto testResults = callFunction!( float, int, float, Object )( "D7myclass7MyClass4testMFifZf", 2, 0.25, object );//test( 2, 0.25, object );

		Output.printValue( OutputType.Info, "I Made a thing", testResults );
	}

	void* getAddress( string mangledName )
	{
		version( Windows )
		{
			auto addr = GetProcAddress( scriptDll, mangledName.ptr );
			
			if( !addr && mangledName[ 0 ] != '_' )
				return getAddress( "_" ~ mangledName );
			else
				return addr;
		}
		else version( Posix )
		{
			return dlsym( lh, mangledName.ptr );
		}
	}

	T getValue( T )( string mangledName )
	{
		return *cast(T*)getAddress( mangledName );
	}

	TReturn callFunction( TReturn )( string mangledName )
	{
		return (*(cast(TReturn function())getAddress( mangledName )))();
	}

	TReturn callFunction( TReturn, TArgs... )( string mangledName, TArgs args )
	{
		return (*(cast(TReturn function(TArgs))getAddress( mangledName )))( args );
	}

	TReturn callCtor( TReturn )( string className )
	{
		// Generate mangled name
		string mangledClassName = "";
		foreach( name; className.split( "." ) )
			mangledClassName ~= name.length.to!string ~ name;
	
		string ctorName = "D" ~ mangledClassName ~ "6__ctorMFZC" ~ mangledClassName;

		return callFunction!( TReturn, Object )( ctorName, new Object );
	}

	void shutdown()
	{
		version( Windows )
		{
			Runtime.unloadLibrary( scriptDll );
		}
		else version( Posix )
		{
			dlclose( scriptDll );
		}
	}

private:
	version( Windows )	HMODULE	scriptDll;
	version( Posix )	void*	scriptDll;
}
