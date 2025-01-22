# Table of Content
- [How It Works](#how-it-works)
- [Nodes](#nodes)
- [Conditional Abort](#conditional-abort)
- [Custom Nodes](#custom-nodes)
- [Your First Behavior Tree](#your-first-behavior-tree)
- [Debugging Tools](#debugging-tools)
- [Best Practices](#best-practices)
- [Limitations](#limitations)

# How It Works
## Setup
The first step in using a behavior tree is to setup its nodes, this works similar to any nodes hierarchy in godot.

<img src="https://imgur.com/nGM76CE.png" width="300"/>

Nodes will show editor warnings to help you set things up correctly.\
Other nodes that aren't part of this addon can be added anywhere in the tree and will simply be ignored.
## Tick
A "tick" is a single update to the tree, think of it like a single call to `_process` or `_physics_process` (can be customized). When a tick occures, the tree root will tick its child which either does a certain action if it's a Leaf node or in turn ticks one of its children as a Branch node and so on all the way down. Depending on the nodes along the way and their status the tree will dynamically make decisions on what task needs to be performed next, or if a task must be interrupted in favor of another.
## Status
Each node in the tree must set a status when it's ticked to determine its result. Specifically either `Status.success`, `Status.failure` or `Status.running`.
- success and failure signal that the node is done processing, prompting its parent to move on to the next child or succeed/fail itself.
- running indicates that the node is still processing, which prevents the flow from changing and ensurs that the parent continues to tick the same node.

An example of this is moving an agent from A to B, the agent will set its status to `running` in each tick as long as it's moving, and will set its status to `success` when it reaches the destination or `failure` if point B is unreachable.
## Blackboard
A blackboard is simply a Dictionary that holds data shared between all nodes in a behavior tree, it acts as a central storage for any node to access and modify. For example, a blackboard can store the current health of an agent, allowing other nodes to adapt their behavior so the agent is more likely to flee if its health is low or enter a death state if its health reches zero.\
There is also global blackboard, which is shared between all trees in the game. Note that the global blackboard is static meaning that it exists even when no instance of a behavior tree exists so the user is responsible for erasing variables that is no longer in use. An example use case is storing environmental information, such as the time of day or player location, which can then be accessed by multiple agents for different reasons.

# Nodes
All behavior tree nodes inherite from `BTNode`. These are all the built-in behavior nodes:
## Leaves
Leaves inherite from `BTLeaf`.\
The addon comes with a few built in leaves but they tend to be specific to each game and its implementation so you'll mostly have to create your own custom leaves (we will cover that below).\
A leaf node cannot have any children and is one of 2 types: actions and conditions.\
### Actions
Actions inherite from `BTAction`.\
An action leaf performs an action such as movement or attacking or playing an animation etc...
- **blackboard_modify**: Writes or erases a blackboard entry.
- **wait_for_time**: Returns running for a certain time before returning success.
- **extras/control_animation_player**: Calls different animation player functions and optionally waits for it to finish.
- **extras/control_sound**: Calls different audio stream player functions and optionally waits for it to finish.
- **extras/control_particles**: Sets particle node to emit/stop and optionally waits for it to finish.
### Conditions
Conditions inherite from `BTCondition`.\
A condition leaf acts as a boolean, checking some condition and returning either success or failure.
- **blackboard_check**: Checks a key against an expression using a specified condition type.

## Branches
Branches inherite from `BTBranch`.\
A branch is a node that can have children nodes.
- **behavior_tree**: The root of a behavior tree.
### Decorators
Decorators inherite from `BTDecorator`.\
Decorators can only have a single child which can be any other node.\
A decorator branch takes the status of its child node and modifies it.

- **cooldown**: If child returns success or failure the cooldown will start preventing child from ticking again until a certain number of ticks occures, while the cooldown is active it will return the last status that the child has returned before the cooldown.\
Example: Preventing an expensive condition check from running when it's not nessesary to recheck the result every tick.

- **force_status**: Forces success or failure to be returned.\
Example: Running a non-critical action that we don't care about its status. A scavenger runs a sequence: Enter House->Check Loot Chest->Exit. In this case we don't care if Check Loot Chest succeeds or fails so we can attach it to a Force Status node that always returns success.

- **inversion**: Inverts the status of its child.

| Child Status | Decorator Status |
| ---     | --- |
| success | failure |
| failure | success |
| running | running |

Example: Checking if a condition node is false without the need for 2 condition nodes for true and false. For example a condition "is hungry?" can be attached to an inverter to check if "is not hungry?".

- **repeat**: Ticks child a certain number of times, can optionally be set to return success if a certain status is returned. If child returns running, it will not count that tick.\
Example: A lumberjack NPC that hits a tree 3 times before it falls, the sequence would look like: Go To Tree->Repeat3(Hit Animation).

- **time_limit**: Fails if child fails to return success or failure before the timeout, otherwise returns child's status.

| Child Status | Decorator Status |
| ---     | --- |
| success | success |
| failure | failure |
| running | failure if timeout, else running |

### Composites
Composites inherite from `BTComposite`.\
Composites can have 2 of more children which are ticked in a certain order, typically from left to right.
- **fallback**: Ticks its children from left to right, if a child fails it ticks the next child, otherwise returns the child's status. Can be thought of as an "OR" node in that it only executes the next child if the previous child fails.

| Child Status | Composite Status |
| ---     | --- |
| success | success |
| failure | running, tick next child |
| running | running |

Example: An NPC that determines whether to work or go to sleep depending on the time of day: Fallback->Day Routine, Night Routine.

- **sequence**: Ticks its children from left to right, if a child succeeds it ticks the next child, otherwise returns the child's status. Can be thought of as an "AND" node in that it only executes the next child if the previous child succeeds.

| Child Status | Composite Status |
| ---     | --- |
| success | running, tick next child |
| failure | failure |
| running | running |

Example: An NPC that needs to open a door: Sequence->Has Key?, Go To Door, Open Door, Enter.

- **fallback_random**: Similar to the normal fallback except children are ticked in a random order, when a child fails this picks a random next child.

| Child Status | Composite Status |
| ---     | --- |
| success | success |
| failure | running, tick next random child |
| running | running |

Example: Boss that picks a random attack out of its attack patterns.

- **fallback_reactive**: Similar to the normal fallback except when a child returns running this will start over from the first child and return running. The fallback is reactive in the sense that it rechecks previous children if a long running child is active reacting to any previous child as soon as its status goes from failure to success.

| Child Status | Composite Status |
| ---     | --- |
| success | success |
| failure | running, tick next child |
| running | running, start over and tick first child |

Example: TODO

- **sequence_random**: Similar to the normal sequence except children are ticked in a random order, when a child succeeds this picks a random next child.

| Child Status | Composite Status |
| ---     | --- |
| success | running, tick next random child |
| failure | failure |
| running | running |

Example: Boss that picks a random attack out of its attack patterns.

- **sequence_reactive**: Similar to the normal sequence except when a child returns running this will start over from the first child and return running. The sequence is reactive in the sense that it rechecks previous children if a long running child is active reacting to any previous child as soon as its status goes from success to failure.

| Child Status | Composite Status |
| ---     | --- |
| success | running, tick next child |
| failure | failure |
| running | running, start over and tick first child |

Example: An NPC that deals with some fragile machinery in order. As soon as a previously active machine turns off the NPC drops what she's doing and goes back to activating that machine.

- **simple_parallel**: Runs exactly 2 nodes at the same time, the first is a leaf node and the second can be any tree node. When the first child returns success or failure the second child is interrupted and this returns first child status, unless delayed mode is active in which case this waits for the second child to finish after the first one has finished and returns the second child's status.

Example: Reactive AI that runs a long sequence like Patrolling while having a parallel Condition node checking if a threat is in range, in which case the Patrolling sequence is interrupted.

## Composite Attachments
Composite attachements can be added as children of composite nodes. Unlike other nodes they don't inherite from `BTNode` and therefore don't set a status but still have access to the behavior tree. Attachements are inspired by Services from the Unreal Engine behavior tree implementation.\
Composite attachments must be placed before any `BTNode` child. They will tick in parallel as long as the parent is ticking.

The main use case for attachment is to run parallel code while a long action is running to monitor some game state or update the blackboard.\
Composite attachments cannot interrupt other nodes.

Example: Keep track of player position in the blackboard while an enemy runs a "Chase Player" sequence instead of updating the position in each node of the sequence.

# Conditional Abort
Conditional aborts allow composite nodes to interrupt their children or interrupt other branches based on a condition. There are 3 types of conditional aborts:

- low priority conditional abort: Allows a composite to interrupt any lower-priority branch. Low priority branches are sibling branches that come after that composite plus all their offsprings. Since composites usually prioritize children in order from first child to last, children that come first tend to have more priority.\
A composite with this setting must have a condition or decorator node as its first child, as long as a lower priority branch is ticking, this composite will tick its condition node in parallel, if the node succeeds, the active branch will be interrupted and this branch will run instead. Low priority aborts are crucial for dynamic AI that can immediately react to significant changes in its environment.\
Examples:\
-Reactive NPC that can run different branches (Gather Resources, Buy Tools etc...) all while still being cautious of enemies by having a high priority branch check for enemy presence in parallel. As soon as an enemy is detected, any active task will be interrupted and escaping will be prioritized.\
-Boss that has different attack patterns and nested branches, that also has a "Dead" branch representing the boss in its dead state, as soon as the boss health reaches 0, whatever branch is active will be interrupted and the Dead branch will run instead.

- self conditional abort: Allows a composite to interrupt itself and start over when its first condition or decorator child fails. The composite must have a condition node as its first child that ticks in parallel while the parent ticks its other children.
Example: An enemy running an attack combo sequence with the self abort condition node checking in parallel that the enemy has enough energy left to continue the combo.

- both conditional abort: Does the same as both of the other types combined.

# Custom Nodes
While this addon comes with a bunch of built-in nodes, creating your own custom nodes is inevitable especially when it comes to custom leaves that tend to be game-specific.\
There are built-in script templates to make inheriting easier.\
<img src="https://imgur.com/0HYOrTi.png"/>

To create your own node add a Godot `Node` to the scene then attach a script to it and make sure it inherites the proper node.\
<img src="https://imgur.com/teDP7hk.png"/>

## Nodes
These are the node types that can be inherited:
- `BTAction`.
- `BTCondition`.
- `BTDecorator`.
- `BTComposite`.

Nodes should override the `tick` function for processing logic and can optionally override `enter` and `exit` for initialization and de-initialization.
```
func enter():
	super()
	# initialization

func exit(is_interrupted : bool):
	super(is_interrupted)
	# de-init

func tick(delta : float):
	super(delta)
	# processing...

	# status code
	_set_status(Status.running)
```
Each of the 3 functions must call `super()`.\
A status must be set in each call to `tick`.\
All behavior nodes have access to the behavior tree with the variable `behavior_tree` which can be used to retreive some data:
```
behavior_tree.agent # the agent assigned in the tree root
behavior_tree.blackboard # the tree blackboard
behavior_tree.global_blackboard # static blackboard shared between all behavior trees
```

Custom branch nodes (Composites and Decorators) additionally have access to `_active_child` which represents the currently ticking child.

## Composite Attachment
Inherite `BTCompositeAttachment`.

Similar to other nodes, composite attachments must override `tick` for processing, and optionally `parent_entered` and `parent_exiting` for initialization and de-initialization.

```
func parent_entered():
	super()
	# initialization

func parent_exiting(is_interrupted : bool):
	super(is_interrupted)
	# de-init

func tick(delta : float):
	super(delta)
	# processing
```
Attachments do not need to set a status code.\
Each of the 3 functions must call `super()`.\
Attachments also have access to the behavior tree with `behavior_tree`.

# Your First Behavior Tree
A beginner guide on making your first behavior tree can be found [here](./(3)%20your%20first%20behavior%20tree.md).

# Debugging Tools
The addon comes with a powerful debugger that displays the flow of every active tree in real-time, access to local blackboards and the global blackboard as well as providing debugging tools to affect the tree as it's running.\
The behavior tree debugger can be found in the bottom panel.

<img src="https://imgur.com/DQsOtrp.png" width="700"/>

As the project runs all behavior tree instances will appear in the trees menu.
Selecting a tree will show its graph, real-time flow and the status of each node.\
A Node's outline color indicates its last status and whether it's running in parallel or not.

The graph comes with some debugging tools.
### Graph Actions
Graph actions can be found in the graph tab and allow centering the tree to view as well as access to the global blackboard. Additionally the trees menu supports sorting both by Scene (instances of same .tscn) and by Instance Time (oldest instances first).

<img src="https://imgur.com/JZKNRI2.png" width="700"/>

### Node Actions
Nodes have their own actions that depend on the node type:
- `BTNode` nodes have a "force tick" action that forces the tree to redirect flow to that node for debugging.
- `BTBehaviorTree` nodes have a "open blackboard" action that open its local blackboard.

<img src="https://imgur.com/qh7o9B4.png" width="400"/>

The blackboard tab shows up when opening the local or global blackboard and displays its content.

<img src="https://imgur.com/re9J1qD.png" width="300"/>

# Best Practices
There are many ways to approach organizing a behavior tree overtime and sometimes more than 1 way to achieve the same result, how to organize you behavior tree is an art of its own, though here are some best practices that could help:
- Make sure action nodes are minimalistic. Instead of an action like "Attack" that causes an enemy to chase the player and shoot at them it's better to separate that into smaller scope actions like "Chase" and "Shoot". This way we minimize dependency between nodes and allow them to be reused and modified easily.
- Ensure that all condition nodes are truthy. That means condition nodes should check if a condition is true instead of false (is_damaged, has_weapon instead of is_not_damaged, has_no_weapon). This avoids having 2 versions of the same condition node, the Inverter decorator can be used to invert the node into a falsy checks.
- Rename behavior tree nodes in the editor so the tree is easier to read. Nodes also support an optional description that is visible in the debugger.
- Blackboards vs other classes. Depending on your game, you may have some data needed by the AI that is managed by another system, an autoload or the agent script, an example of this is a `World` autoload that keeps track of information like the time/weather. In this case it can be better to access data from such autoload instead of storing a duplicate in the blackboard to avoid duplications and out of sync issues.

- (Different ways to do the same thing (parallel node vs comp attachment, conditional abort vs reactive composite...))

# Limitations
While this addon covers a wide range of use cases and aims to cover features from various other implementations, it does have some limitations that you should be aware of:
- `await` is not supported in the `tick` function, when a node is ticked, it's expected to set a status immediately. This can be worked around by connecting the signal you wish to await to some function and check every tick if that function was called.
- Tree structure is static, meaning nodes cannot be added/removed at run-time. This isn't a problem for the vast majority of use cases but it means that using this addon for things like evolution simulations and procedural AI is not possible. The decision to keep the tree static was made to avoid the countless headaches, stability problems and missed optimizations that come with dynamic trees.
- The addon is implemented in GDScript, which is comparatively slower than other supported languages. This shouldn't matter for most use cases, but you might notice performance issues if you have hundreds of NPCs running complex logic. The node-based setup also carries some overhead. While there are some optimizations in place to help with this, I might switch to C# or C++ in the future.