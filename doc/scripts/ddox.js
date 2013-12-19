function setupDdox()
{
	$(".tree-view").children(".package").click(toggleTree);
	$(".tree-view.collapsed").children("ul").hide();
}

function toggleTree()
{
	node = $(this).parent();
	node.toggleClass("collapsed");
	if( node.hasClass("collapsed") ){
		node.children("ul").hide();
	} else {
		node.children("ul").show();
	}
	return false;
}