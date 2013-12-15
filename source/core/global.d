module core.global;

template Property( Type, string name, string setterAccess = "private", string pureStr = "pure", string checkExpr = "true" ) {
	const char[] Property = 
		"private " ~ Type.stringof ~ " _" ~ name ~ ";\n" ~
		"public @property " ~ Type.stringof ~ " " ~ name ~ "() { return _" ~ name ~ "; } " ~ pureStr ~ "\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ Type.stringof ~ " val ) { if( " ~ checkExpr ~ " ) _" ~ name ~ " = val; }\n";
}

template BackedProperty( Type, alias field, string name, string setterAccess = "private", string pureStr = "pure", string checkExpr = "true" ) {
	const char[] BackedProperty = 
		"public @property " ~ Type.stringof ~ " " ~ name ~ "() { return " ~ field.stringof ~ "; } " ~ pureStr ~ "\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ Type.stringof ~ " val ) { if( " ~ checkExpr ~ " ) " ~ field.stringof ~ " = val; }\n";
}