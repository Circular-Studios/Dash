/**
 * Defines template mixins for defining properties in classes.
 * 
 * Authors: Colden Cullen, ColdenCullen@gmail.com
 */
module core.properties;

public import std.traits;

mixin template Properties()
{
	public void delegate()[] onChanged;

	void changed() { foreach( ev; onChanged ) ev(); }
}

enum AccessModifier
{
	Public = "public",
	Protected = "protected",
	Private = "private",
}

template Property( alias field, string name = field.stringof[ 1..$ ], AccessModifier setterAccess = AccessModifier.Protected, AccessModifier getterAccess = AccessModifier.Public )
{
	enum Property = Getter!( field, name, getterAccess ) ~ Setter!( field, name, setterAccess );
}

template Getter( alias field, string name, AccessModifier access = AccessModifier.Protected )
{
	enum Getter = access ~ " @property " ~ typeof(field).stringof ~ " " ~ name ~ "(){ return " ~ field.stringof ~ ";}\n";
}

template DirtyGetter( string type, string name, string field, string update, AccessModifier access = AccessModifier.Protected )
{
	enum DirtyGetter =
		"public bool " ~ field ~ "IsDirty = true;\n" ~
		access ~ " @property " ~ type ~ " " ~ name ~ "(){" ~
			"if(" ~ field ~ "IsDirty)" ~
				update ~ "();"
			"return " ~ field ~ ";}";
}

template Setter( alias field, string name, AccessModifier access = AccessModifier.Protected )
{
	enum Setter = access ~ " @property void " ~ name ~ "(" ~ typeof(field).stringof ~ " newVal){ if( newVal !=" ~ field.stringof ~ ")" ~ field.stringof ~ " = newVal;}\n";
}
