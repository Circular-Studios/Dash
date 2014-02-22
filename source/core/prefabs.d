module core.prefabs;
import core.gameobject;
import components;
import utility.filepath, utility.config;

import yaml;
import gl3n.linalg;
import std.variant;

final abstract class Prefabs
{
public static:
	alias prefabs this;

	Prefab[string] prefabs;

	void initialize()
	{
		foreach( key; prefabs.keys )
			prefabs.remove( key );

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

final class Prefab
{
public:
	this( Node yml )
	{
		transform = new Transform;
		Variant prop;
		Node innerNode;

		// Try to get from script
		if( Config.tryGet!string( "Script.ClassName", prop, yml ) )
			scriptClass = ClassInfo.find( prop.get!string );
		else
			scriptClass = null;

		if( Config.tryGet!string( "Camera", prop, yml ) )
		{
			//TODO: Setup camera
		}

		if( Config.tryGet!string( "Material", prop, yml ) )
			componentReferences ~= Assets.get!Material( prop.get!string );

		if( Config.tryGet!string( "AwesomiumView", prop, yml ) )
		{
			//TODO: Initialize Awesomium view
		}

		if( Config.tryGet!string( "Mesh", prop, yml ) )
			componentReferences ~= Assets.get!Mesh( prop.get!string );

		if( Config.tryGet( "Transform", innerNode, yml ) )
		{
			vec3 transVec;
			if( Config.tryGet( "Scale", transVec, innerNode ) )
				transform.scale = transVec;
			if( Config.tryGet( "Position", transVec, innerNode ) )
				transform.position = transVec;
			if( Config.tryGet( "Rotation", transVec, innerNode ) )
				transform.rotation = quat.euler_rotation( transVec.y, transVec.z, transVec.x );
		}

		if( Config.tryGet!Light( "Light", prop, innerNode ) )
		{
			componentReferences ~= prop.get!Light;
		}
	}

	this()
	{
		transform = new Transform;
		scriptClass = null;
	}

	final GameObject createInstance( const ClassInfo overrideScript = null )
	{
		GameObject result;

		auto script = overrideScript is null ? scriptClass : overrideScript;

		if( script )
			result = cast(GameObject)script.create();
		else
			result = new GameObject;

		result.transform.scale.vector[ 0..3 ] = transform.scale.vector[ 0..3 ];
		result.transform.position.vector[ 0..3 ] = transform.position.vector[ 0..3 ];
		result.transform.rotation.x = transform.rotation.x;
		result.transform.rotation.y = transform.rotation.y;
		result.transform.rotation.z = transform.rotation.z;
		//result.transform.rotation.w = transform.rotation.w;

		foreach( cpn; componentReferences )
			result.addComponent( cpn );

		foreach( cpncls; componentCreations )
		{
			auto inst = cast(Component)cpncls.create();
			result.addComponent( inst );
			inst.owner = result;
		}

		result.transform.updateMatrix();

		return result;
	}

private:
	const ClassInfo scriptClass;
	Transform transform;
	Component[] componentReferences;
	ClassInfo[] componentCreations;
}
