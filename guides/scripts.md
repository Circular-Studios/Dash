---
layout: default
title: Scripts
section: guides/scripts
---
# Scripts
---

### The Game Script

You should always have a game script, or a script that is not attached to an
object that controls game state. The class should extend
[`DGame`]({{ site.api }}/core/dgame/DGame.html), and extend any or all
of the following:

* [`title`]({{ site.api }}/core/dgame/DGame.title.html): The title of the window (for the title bar and taskbar).
* [`onInitialize`]({{ site.api }}/core/dgame/DGame.onInitialize.html): Called when the game is starting.
* [`onUpdate`]({{ site.api }}/core/dgame/DGame.onUpdate.html): Called every frame on the update cycle.
* [`onDraw`]({{ site.api }}/core/dgame/DGame.onDraw.html): Called every frame before rendering.
* [`onShutdown`]({{ site.api }}/core/dgame/DGame.onShutdown.html): Called on shutdown.
* [`onRefresh`]({{ site.api }}/core/dgame/DGame.onRefresh.html): Called when assets are refreshing.

### Component Scripts

Component scripts are any scripts you would want to attach to an object. The
class extend the [`Component`]({{ site.api }}/components/component/Component.html)
class. If you want them to be addable through YAML, you should annotate the class
with [`@yamlComponent()`]({{ site.api }}/components/component/yamlComponent.html).
You should also add a mixin of
[`registerComponents`]({{ site.api }}/components/component/registerComponents.html)
(with the template parameter being the name of the current module) anywhere in
your scripts, but it is recommended to add it in the module you're registering.
You should also annotate each member with
[`@field()`]({{ site.api }}/components/component/field.html), with an
optional parameter that is what you want the name of the field to be in the YAML.
The template parameter is the [loader](#loaders) you want to use for the parameter,
which overrides the loader (if there is one) for the type of the field.

An example script might look like this:

```d
import dash.components, dash.utility;

@yamlComponent()
class MyComponent : Component
{
    @field()
    float x;
    @field( "Y" )
    float y;

    override void initialize()
    {
        logNotice( "Initializing!" );
    }
}
```

An object definition that uses it might look like this:

```yaml
---
Name: Object3
Mesh: MeshX
Material: MaterialY
MyComponent:
    x: 1.0
    Y: 10.2
```

<div id="loaders" />
### Loaders

Loaders can be specified on subclasses of `YamlObject` and
[`@field()`]({{ site.api }}/components/component/field.html)s. They
exist so that you may add a field or component to an object that has already
been created. A good example is [`Meshes`]({{ site.api }}/components/mesh/Mesh.html),
which rely on loaders because they are not created from YAML, but instead from
files. They're annotation looks something like this:

```d
@yamlComponent!( q{name => Assets.get!Mesh( name )} )()
class Mesh : Asset { ... }
```
