module core.global;

template Property( string type, string name, string setterAccess = "private", string pureStr = "pure", string checkExpr = "true" ) {
	const char[] Property = 
		"private " ~ type ~ " _" ~ name ~ ";\n" ~
		"public @property " ~ type ~ " " ~ name ~ "() { return _" ~ name ~ "; } " ~ pureStr ~ "\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ type ~ " val ) { if( " ~ checkExpr ~ " ) _" ~ name ~ " = val; }\n";
}

template BackedProperty( string type, string fieldName, string name, string setterAccess = "private", string pureStr = "pure", string checkExpr = "true" ) {
	const char[] BackedProperty = 
		"public @property " ~ type ~ " " ~ name ~ "() { return " ~ fieldName ~ "; } " ~ pureStr ~ "\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ type ~ " val ) { if( " ~ checkExpr ~ " ) " ~ fieldName ~ " = val; }\n";
}