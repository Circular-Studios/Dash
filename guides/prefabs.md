---
layout: default
title: Prefabs
section: guides/prefabs
---
# Prefabs
~~~

### Writing a Prefab

Prefabs are YAML objects which allow you to easily create similar objects
without duplicating code. You can place as many prefabs in a file as you want,
as long as they are separated by a `---`. They must have a `Name` field,
and they may have any property that an object definition can have. An example
prefab file may look like this:

`prefab1.yml`
```yaml
---
Name: Prefab1
Material: Mat1
Mesh: MyMesh2
PointLight:
    Color: !Vector3 1 1 1
    FalloffRadius: 0.5
    Brightness: 1
---
Name: Prefab2
Mesh: MyMesh37
Material: Mat62
```

### Extending a Prefab from YAML

Any `GameObject` defined by YAML can extend a prefab. To do so, simply add an
`InstanceOf` field to your object definition. Any field defined
in a prefab and an object will be overridden by the object. An example may look
like this:

`object1.yml`
```yaml
---
Name: Object1
InstaceOf: Prefab1
---
Name: Object2
InstanceOf: Prefab2
Mesh: MyMesh8
```

### Instantiating a Prefab from Code

To create an instance of a prefab from inside your D scripts, import
`core.prefabs` (or just `core`), and call to
[`Prefab.createInstance`]({{ site.api }}/core/prefabs/Prefab.createInstance.html).
An example script may look like this:

```d
...
auto newObj = Prefabs["BaseObj"].createInstance();
newObj.addComponent( Assets.get!Mesh( "Mesh62" ) );
...
```
