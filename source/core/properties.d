/**
 * Defines template mixins for defining properties in classes.
 * 
 * Authors: Colden Cullen, ColdenCullen@gmail.com
 */
module core.properties;

public import std.traits;

enum AccessModifier : string
{
	Public = "public",
	Protected = "protected",
	Private = "private",
}

template Property( alias field, AccessModifier setterAccess = AccessModifier.Protected, AccessModifier getterAccess = AccessModifier.Public, string name = field.stringof[ 1..$ ] )
{
	enum Property = Getter!( field, getterAccess, name ) ~ Setter!( field, setterAccess, name );
}

template Getter( alias field, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
{
	enum Getter = "final " ~ access ~ " @property auto " ~ name ~ "() @safe pure nothrow { return " ~ field.stringof ~ ";}\n";
}

template DirtyGetter( alias field, string update, AccessModifier access = AccessModifier.Public, string name = field.stringof[ 1..$ ] )
{
	enum DirtyGetter =
		"public bool " ~ field.stringof ~ "IsDirty = true;\n" ~
		"final " ~ access ~ " @property auto " ~ name ~ "() @safe pure nothrow {" ~
			"if(" ~ field.stringof ~ "IsDirty)" ~
				update ~ "();"
			"return " ~ field.stringof ~ ";}\n";
}

void setDirty( alias field )()
{
	mixin( field.stringof ~ "IsDirty = true;" );
}

template Setter( alias field, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
{
	enum Setter = "final " ~ access ~ " @property void " ~ name ~ "(" ~ typeof(field).stringof ~ " newVal) @safe pure nothrow { " ~ field.stringof ~ " = newVal;}\n";
}

template DirtySetter( alias field, AccessModifier access = AccessModifier.Protected, string name = field.stringof[ 1..$ ] )
{
	enum Setter = "final " ~ access ~ " @property void " ~ name ~ "(" ~ typeof(field).stringof ~ " newVal) @safe pure nothrow { " ~ field.stringof ~ " = newVal; changed();}\n";
}
