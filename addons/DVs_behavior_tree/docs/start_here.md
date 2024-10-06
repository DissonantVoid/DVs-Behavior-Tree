# Start Here
This is a guide for developers that have **little to no experience** using behavior trees, it should get you started with general behavior tree concepts and terminology. We will also go through best practices and compare behavior trees to other approaches to get a better overall picture.

# What is a Behavior Tree?
A behavior tree is a hierarchical node-based tree that controls the decision making of an entity. Behavior trees are used in fields such as robotics and control systems but their most common use is in video games. The "tree" in behavior tree refers to the data structure used to organize its nodes in a hierarchy, similar to how Godot itself organizes nodes in the scene and their parent/child relationship.
The tree begins at the root node, evaluating each child node down the tree until it reaches the final node that represents a task such as moving the character from point A to B or shooting etc... how this flow (know as a Tick) reaches a certain node is determined by each node along the way. Typically behavior trees have 3 categories of nodes:
- Composite Nodes: ...
- Decorator Nodes: ...
- Leaf Nodes: ...
We will dive into each category and each node in more details later, this is just to provide an overview.
(image: simple tree example)

Behavior trees gained attention after being used in Halo 2's AI system which was an improvement from finite state machines that were commonly used at the time, and have gained significant attention in gaming over the years thanks to how modular and flexible they are.

(terminology: tick, node categories...)

# Why Use a Behavior Tree?
The main reason why behavior trees are so popular in video games is their high flexibility. They are modular in a sense that complex behaviors can arrise from combinations of simple tasks.
(images: behavior tree from The Division and other publicaly available examples)
Behavior tree logic can be separated into groups of nodes reducing dependency and minimizing potential for bugs ... this also means that behavior trees are easier to maintain and debug even as they grow in size overtime.
Nodes in behavior trees can be reused in more than one place, this not only applies to individual nodes but to sub-trees composed of many nodes and branches ...

If you have implemented AI in your games before, chances are you have used a Finite State Machine ...
(FSM limitations (dependency, parallel, fsm hell), difference, situations where FSM is better)

# Behavior Trees in Godot
-how that applies to godot (nodes system, save branch as scene etc...)
[How To Use](using_addon.md)

# External Resources
https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work
https://robohub.org/introduction-to-behavior-trees/
https://en.wikipedia.org/wiki/Behavior_tree_(artificial_intelligence,_robotics_and_control)