module graphics.adapters.linux;
import graphics.graphics, graphics.adapters.adapter;

import x11.X, x11.Xlib;

class Linux : Adapter
{
	static @property Linux get() { return cast(Linux)Graphics.adapter; }

	override void initialize()
	{
		
	}
	
	override void shutdown()
	{
		
	}
	
	override void resize()
	{
		
	}
	
	override void reload()
	{
		
	}
	
	override void beginDraw()
	{
		
	}
	
	override void endDraw()
	{
		
	}
	
	override void openWindow()
	{
		
	}
	
	override void closeWindow()
	{
		
	}
	
	override void messageLoop()
	{
		
	}
} 
