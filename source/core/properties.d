/**
 * Defines template mixins for defining properties in classes.
 * 
 * Authors: Colden Cullen, ColdenCullen@gmail.com
 */
module core.properties;

public import std.traits;

template Properties()
{
	enum Properties = q{
		public void delegate()[] onChanged;

		void changed() { foreach( ev; onChanged ) ev(); }
	};
}

enum AccessModifier : string
{
	Public = "public",
	Protected = "protected",
	Private = "private",
}

template Property( alias field, string name = field.stringof[ 1..$ ], AccessModifier setterAccess = AccessModifier.Protected, AccessModifier getterAccess = AccessModifier.Public )
{
	enum Property = Getter!( field, name, getterAccess ) ~ Setter!( field, name, setterAccess );
}

template Getter( alias field, string name = field.stringof[ 1..$ ], AccessModifier access = AccessModifier.Protected )
{
	enum Getter = "final " ~ access ~ " @property auto " ~ name ~ "(){ return " ~ field.stringof ~ ";}\n";
}

template DirtyGetter( alias field, string update, string name = field.stringof[ 1..$ ], AccessModifier access = AccessModifier.Public )
{
	enum DirtyGetter =
		"public bool " ~ field.stringof ~ "IsDirty = true;\n" ~
		"final " ~ access ~ " @property auto " ~ name ~ "(){" ~
			"if(" ~ field.stringof ~ "IsDirty)" ~
				update ~ "();"
			"return " ~ field.stringof ~ ";}";
}

void setDirty( alias field )()
{
	mixin( field.stringof ~ "IsDirty = true;" );
}

template Setter( alias field, string name = field.stringof[ 1..$ ], AccessModifier access = AccessModifier.Protected )
{
	enum Setter = "final " ~ access ~ " @property void " ~ name ~ "(" ~ typeof(field).stringof ~ " newVal){ if( newVal !=" ~ field.stringof ~ ")" ~ field.stringof ~ " = newVal;}\n";
}

template DirtySetter( alias field, string name = field.stringof[ 1..$ ], AccessModifier access = AccessModifier.Protected )
{
	enum Setter = "final " ~ access ~ " @property void " ~ name ~ "(" ~ typeof(field).stringof ~ " newVal){ if( newVal !=" ~ field.stringof ~ "){" ~ field.stringof ~ " = newVal; changed();}\n";
}
