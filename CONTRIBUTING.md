# Contributing to Dash

First of all, thanks for choosing Dash! We really hope you enjoy your time working with our engine. To get setup with the engine, see our page on [setting up your environment](https://github.com/Circular-Studios/Dash/wiki/Setting-Up-Your-Environment).

## Communication

Most communication takes place as comments in issues and pull requests. When more immediate communication is required, we will use our [gitter.im room](https://gitter.im/Circular-Studios/Dash).

## Coding Standards

We here at Circular Studios loosely follow the [Official D Style](http://dlang.org/dstyle.html), however we do have some more specialized coding standards that you can read about [here](https://github.com/Circular-Studios/Dash/wiki/Coding-Standards).

## Git Workflow

Dash uses [Git Flow](http://nvie.com/posts/a-successful-git-branching-model/) as its branching model.

We use [semantic versioning](http://semver.org/). Each minor version gets a milestone, and release branches for them start when the milestone is complete. They are merged to master once it is decided that the release is stable. Patch versions are only created though hotfix branches, which do not need pull requests.

All major features or enhancements being added are done on feature branches, then merged to develop through Pull Requests. Pull requests should be named as `Type: Name`, where `Type` could be `Feature`, `Refactor`, `Cleanup`, etc.

## Issue Tracking

Now that you know how to contribute, you may be wondering what to work on.  In order to help all of our contributors work effectively on tasks, we will maintain a straightforward issue tracking strategy through Dash's [waffle.io page](https://waffle.io/circular-studios/dash).

If you are looking for something to work on, your first step should be to go to the **Ready** column, however here is an overview of the tracking strategy we've adopted:

* **New**: if you find a bug, want to suggest a feature, or see a need for optimization, feel free to create a new issue.  These issues will be tracked in the New column until we have had time to review them.
* **Accepted**: tracks issues that we have approved as relevant to the project.  For bugs, this means that we've reporduced the bug and accept that it's not as-intended. For features, this means we have reviewed that the feature fits with our vision of the Dash engine and is something we actually plan to support.
* **Ready**: tracks issues which we have determined are ready for implementation.  Sometimes features will be accepted, but the current state of the engine is not at a place where the issue is worth working on.  Once we feel the engine is ready to support a given issue, we will transition the issue to ready.
* **In Progress**: tracks issues which are currently being developed.  If you are beginning work on an issue, please comment on the issue with a relevant fork branch, and we will move the issue to this column.
* **Done**: closed issues end up here.
