module scripting.scripts;
import utility.config, utility.filepath, utility.output;

import core.runtime, core.demangle;
import std.conv;

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
		string dllpath = FilePath.ResourceHome ~ Config.get!string( "Scripts.FilePath" );

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

		auto ctor = cast(Object function( Object ))getAddress( "D7myclass7MyClass6__ctorMFZC7myclass7MyClass" );
		auto object = ctor( new Object );

		auto test = cast( float function( int, float, Object ))getAddress( "D7myclass7MyClass4testMFifZf" );
		auto testResults = test( 2, 0.25, object );

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
