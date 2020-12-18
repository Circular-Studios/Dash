---
layout: default
title: Getting Started
section: guides/gettingstarted
---
# Getting Started
---

### Installation and Setup

The first step is to install the [*dmd*](http://dlang.org/download.html)
compiler toolchain and
 [*dub*](http://code.dlang.org/download), D's package manager.

The next thing to do is install the Dash Command Line Utility from
[GitHub](https://github.com/Circular-Studios/Dash-CLI/releases). On Windows,
simply run the installer. On other platforms extract the zip file, and link the
executable into somewhere in your path (**NOTE**: The `empty-game.zip` file must
remain alongside the executable).

That's it! You're ready to start making games with Dash.

### Creating Your First Project

Creating an empty project is as easy as running `dash create ./path/to/project`.
If you'll be committing the empty project, it is suggested that you add the `-k`
flag to the `create` command to add a `.gitkeep` file in each empty folder.
This will set you up with all of the folders you need to run the game, as well
as a blank game script. Here's what all the folders are for:

| Folder    | Description
|:----------|:-----------
| Binaries  | This is where the compiled executable for your project goes. You shouldn't need to change anything in here.
| Config    | This is where your config files go (`Config.yml` and `Input.yml`). `Config.yml` contains all of the settings for your game, and `Input.yml` contains all of the key bindings. You can learn more about key bindings [here](#).
| Materials | This is where your materials go. These are YAML objects which define what textures to place on objects for which role. You can learn about them [here](#).
| Meshes    | This is where all of your exported meshes go. You can find a list of supported formats [here](#).
| Objects   | This is where all of your object definitions go. These are YAML objects that place things in your world. You can learn more about them [here](#).
| Prefabs   | This is where all of your prefab definitions go. These are YAML objects that allow you to create `GameObject`s much more easily. You can learn more about them [here]({{ site.baseurl }}/guides/prefabs.html).
| Scripts   | This is where all of your scripts go. You should have one that manages the game itself, and then one for every component you define. You can learn more about them [here](#).
| Textures  | This is where all of your textures go. You can fine a list of supported formats [here](#).
| UI        | This is where all of your UI files go. You can learn more about UIs [here](#).
