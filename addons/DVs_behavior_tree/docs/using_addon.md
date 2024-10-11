# Table of Content (outdated)
- [How It Works](#how-it-works)
- [Your First Behavior Tree](#your-first-behavior-tree)
- [Blackboard](#blackboard)
- [Nodes](#nodes)
- [Debugging Tools](#debugging-tools)
- [Best Practices](#best-practices)
- [Custom Nodes](#custom-nodes)
- [Limitations](#limitations)

# How It Works
## Setup
The first step in using a behavior tree is to setup its nodes, this works similar to any nodes hierarchy in godot.
(image of bt hierarchy inside a character scene)
Nodes will show editor warnings to help you set things up correctly, some things to note as a beginner:
- The Behavior Tree node must be at the root.
- 
## Tick
...
## Status
Each node in the tree must set a status when it's ticked to determine its result using `_set_status(status)` where `status` is one of the enum values in the `Status` enum. Specifically either `success`, `failure` or `running`.
- success and failure signals that the node is done processing, prompting its parent to move on to the next child or take succeed/fail itself based on how it works.
- Running indicates that the node is still processing, which prevents the flow from changing and ensurs that the parent continue to tick the same node.
An example of this is moving an agent from A to B, the agent will set its status to `running` after each tick as long as it's moving, and will set its status to `success` when it reaches the destination or `failure` if point B is unreachable.
Note that other status values in the `Status` enum are used internally and not meant to be set by a node.

## Blackboard
A blackboard is simply a Dictionary that holds data shared between all nodes in a behavior tree, it acts as a central storage for any node to access and modify data for state keeping, and context-based information. For example, a blackboard can store the current health of an agent, allowing other nodes to adapt their behavior so the agent is more likely to flee if its health is low.
This addon also supports a global blackboard, which is a blackboard shared between all trees in the game. Note that the global blackboard is static meaning that it exists even when no instance of a behavior tree exists meaning that the user is responsible for cleaning data that is no longer in use. An example use case is storing environmental information, such as the time of day or player location, which can then be accessed by multiple agents for different reasons.

(docs for each category, every node and example use cases)
# Nodes
All behavior tree nodes inherite from `BTNode`.
## Branches
Branches inherite from `BTBranch`.
- Behavior Tree
### Decorators
Decorators inherite from `BTDecorator`.
- coodown
- force status
- inversion
- repeat
- time limit
### Composites
Composites inherite from `BTComposite`.
- fallback
- sequence
- fallback random
- fallback reactive
- sequence random
- sequence reactive
- simple parallel
### Composite Attachment
...

## Leaves
Leaves inherite from `BTLeaf`.
### Actions
Actions inherite from `BTAction`.
- blackboard modify
- wait for time
### Conditions
Conditions inherite from `BTCondition`.
- blackboard check

# Your First Behavior Tree
The best way to learn something is to do it yourself! Now that you know the essentials, let's make our own simple AI using this addon. We'll be making an agent that ...

# Debugging Tools
The addon comes with a powerful debugger that displays the flow of every active tree in real-time, access to local blackboards and the global blackboard as well as providing debugging tools to affect the tree as it's running.
The behavior tree debugger can be found in the bottom panel.
(image of debugger in bottom panel)
As the project runs any behavior tree instance will appear in the trees menu.
(image of trees in the trees menu, or have that as part of the earlier image)
Clicking a tree will reveil its real-time flow where it's easier to tell which branch or behavior is running and what other nodes that have succeeded/failed in the past ...
(sorting, graph node actions, graph actions, blackboards)
# Best Practices
-minimalist actions and truthy conditions
-jerky movement if action node doesn't return running
-different ways to do things (parallel node vs service, conditional abort vs reactive composite...)
# Custom Nodes
The most common case for wanting your own behavior node is custom actions...
(what to inherite/override, templates etc...)
# Limitations
While this addon covers a wide range of use cases and aims to cover features from various implementations, it does have some limitations that you should be aware of:
- `await` is not supported in the `tick` function, when a node is ticked, it's expected to set a status immediately. This can be worked arroud by connecting the signal you wish to await to some function and check every tick if that function was called.
- The addon is implemented in GDScript, which is comparatively slower than other supported languages. This shouldn't matter for small-medium sized projects, but you might notice performance issues if you have hundreds of NPCs running complex actions at once. The the node-based setup also carries some overhead. While there are some optimizations in place to help with this, we will adress this in the future.