module core.graphosglobal;

template Property( string type, string name, string setterAccess = "private", string checkExpr = "true" ) {
	const char[] Property = 
		"private " ~ type ~ " _" ~ name ~ ";\n" ~
		"public @property " ~ type ~ " " ~ name ~ "() { return _" ~ name ~ "; } pure\n" ~
		setterAccess ~ " @property void " ~ name ~ "( " ~ type ~ " val ) { if( " ~ checkExpr ~ " ) _" ~ name ~ " = val; }\n";
}