---
layout: default
title: Objects Schema
section: schemas/objects
---
# Game Object Schema
---

| Field      | Type           | Optional | Description
|:-----------|:--------------:|:--------:|:-----------
| Name       | `string`       | `false`  | The name of the object.
| Transform  | `Transform`    | `true`   | The initial transform of the object.
| InstanceOf | `string`       | `true`   | The name of the prefab to extend.
| Children   | `GameObject[]` | `true`   | The objects which are parented to this object.
