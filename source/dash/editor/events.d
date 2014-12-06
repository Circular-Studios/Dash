module dash.editor.events;
import dash.editor.editor, dash.editor.websockets;
import dash.core, dash.components.component;

import vibe.data.json;
import std.typecons, std.functional;

package:
void registerGameEvents( Editor ed, DGame game )
{
    // Triggers an engine refresh
    ed.registerEventHandler( "dgame:refresh", ( Json _ ) {
        game.currentState = EngineState.Refresh;
    } );

    ed.registerEventHandler( "dgame:scene:get_objects", ( Json _ ) {
        return game.activeScene.root.children;
    } );
}

void registerObjectEvents( Editor ed, DGame game )
{
    // Refresh an object
    static struct RefreshRequest
    {
        string objectName;
        GameObject.Description description;
    }
    ed.registerEventHandler( "object:refresh", ( RefreshRequest req ) {
        if( auto obj = game.activeScene[ req.objectName ] )
        {
            obj.refresh( req.description );
        }
        else
        {
            throw new Exception( "Object " ~ req.objectName ~ " not found." );
        }
    } );

    // Refresh a component
    static struct ComponentRefreshRequest
    {
        string objectName;
        string componentName;
        Component.Description description;
    }
    ed.registerEventHandler( "object:component:refresh", ( ComponentRefreshRequest req ) {
        if( auto obj = game.activeScene[ req.objectName ] )
        {
            obj.refreshComponent( req.componentName, req.description );
        }
        else
        {
            throw new Exception( "Object " ~ req.objectName ~ " not found." );
        }
    } );

    // Refresh a transform
    static struct TransformRefreshRequest
    {
        string objectName;
        Transform.Description description;
    }
    ed.registerEventHandler( "object:transform:refresh", ( TransformRefreshRequest req ) {
        if( auto obj = game.activeScene[ req.objectName ] )
        {
            obj.transform.refresh( req.description );
        }
        else
        {
            throw new Exception( "Object " ~ req.objectName ~ " not found." );
        }
    } );
}
