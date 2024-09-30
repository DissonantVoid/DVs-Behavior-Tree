# Start Here
This is a guide for developers that have **little to no experience** using behavior trees, this should get you started to make your own custom AI built on top of this addon. We will also go through best practices and compare behavior trees to other approaches to get a better overall picture.

# What is a Behavior Tree?
A behavior tree is a hierarchical node-based tree that controls the decision making of an entity, behavior trees are used in fields such as robotics and control systems but their most common use is in video games. The "tree" in behavior tree refers to the data structure used to organize its nodes in a hierarchy. similar to how Godot itself organizes nodes in the scene and their parent/child relationship.
The tree is traversed from the root node at the start, evaluating each child node down the tree until it reaches the final node that represents a task such as moving the character from point a to b or shooting etc... how this tick flows from the root to a certain node is determined by each node it passes by. Generally a behavior tree has 3 types of nodes ...
Behavior trees gained attention after being used in Halo 2's AI system which was an improvement from finite state machines that were commonly used at the time, and have gained significant attention in gaming over the years thanks to how modular and flexible they are.

# Why Use a Behavior Tree?
The main reason why behavior trees are so popular in video games is their high flexibility. They are modular in a sense that complex behaviors can arrise from combinations of simple tasks ...
(ease of debug, tasks priority, scalable)

If you have used AI in a game before you may have used a Finite State Machine before ...
(FSM limitations, situations where FSM is better)

# Behavior Trees in Godot
-how that applies to godot (nodes system etc...)
-addon
[How To Use](using_addon.md)

# External Resources
https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work
https://robohub.org/introduction-to-behavior-trees/
https://en.wikipedia.org/wiki/Behavior_tree_(artificial_intelligence,_robotics_and_control)