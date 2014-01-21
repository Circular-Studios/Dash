module core.prefabs;
public import core.prefab;
import core.gameobject;
import utility.filepath, utility.config;

import yaml;

abstract final class Prefabs
{
public static:
	alias prefabs this;

	Prefab[string] prefabs;

	void initialize()
	{
		void addObject( Node object )
		{
			auto name = object[ "Name" ].as!string;

			prefabs[ name ] = new Prefab( object );
		}

		foreach( file; FilePath.scanDirectory( FilePath.Resources.Prefabs, "*.yml" ) )
		{
			auto object = Config.loadYaml( file.fullPath );

			if( object.isSequence() )
				foreach( Node innerObj; object )
					addObject( innerObj );
			else
				addObject( object );
		}
	}
}
