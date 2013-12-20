module core.gameobjectcollection;
import core.gameobject;
import graphics.shaders.ishader;
import utility.filepath;

import yaml;

class GameObjectCollection
{
public:
	void loadObjects( string objectPath )
	{
		void addObject( Node object )
		{
			auto name = object[ "Name" ].as!string;

			objects[ name ] = new GameObject( object );
		}

		foreach( file; FilePath.scanDirectory( objectPath ) )
		{
			auto object = Loader( file.fullPath ).load();

			if( object.isSequence() )
				foreach( Node innerObj; object )
					addObject( innerObj );
			else
				addObject( object );
		}
	}

	GameObject opIndex( string name )
	{
		return objects[ name ];
	}

	void removeObject( string name )
	{
		objects.remove( name );
	}

	void clearObjects()
	{
		foreach( key; objects.keys )
			objects.remove( key );
	}

	void callFunction( void function( GameObject ) func )
	{
		foreach( value; objects.values )
			func( value );
	}

	void update()
	{
		callFunction( go => go.update() );
	}

	void draw()
	{
		callFunction( go => go.draw() );
	}

private:
	GameObject[string] objects;
}
