# Contributing to Dash

First of all, thanks for choosing Dash! We really hope you enjoy your time working with our engine. To get setup with the engine, see our page on [setting up your environment](https://github.com/Circular-Studios/Dash/wiki/Setting-Up-Your-Environment-(Engine\)).

## Communication

Most communication takes place as comments in issues and pull requests. When more immediate communication is required, we will use our [gitter.im room](https://gitter.im/Circular-Studios/Dash).

## Coding Standards

We here at Circular Studios loosely follow the [Official D Style](http://dlang.org/dstyle.html), however we do have some more specialized coding standards that you can read about [here](https://github.com/Circular-Studios/Dash/wiki/Coding-Standards).

## Git Workflow

Dash uses [Git Flow](http://nvie.com/posts/a-successful-git-branching-model/) as its branching model.

We use [semantic versioning](http://semver.org/). Each minor version gets a milestone, and release branches for them start when the milestone is complete. They are merged to master once it is decided that the release is stable. Patch versions are only created though hotfix branches, which do not need pull requests.

All major features or enhancements being added are done on feature branches, then merged to develop through Pull Requests. Pull requests should be named as `Type: Name`, where `Type` could be `Feature`, `Refactor`, `Cleanup`, etc.

Issues should be created for all tasks and bugs. Issues should be assigned to a milestone, and then claimed by a developer.

## What to Work On

Now that you know how to contribute, you may be wondering what to work on.

If you're looking for a large task, the first place to look would be on the [Planned Features](https://github.com/Circular-Studios/Dash/wiki/Planned-Features) page. This is where the list of all of the big things we want lives.

If you're looking for an intro to the code base, or only really have time for little things, check out the "Ready" column of our [waffle.io board](https://waffle.io/Circular-Studios/Dash). Things here could range from adding support for loading YAML arrays to fixing a bug in the linux build.
