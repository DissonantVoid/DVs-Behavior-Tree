# Start Here
This is a guide for developers that have **little to no experience** using behavior trees or those seeking to **refrensh** their knowledge, it should get you started with general behavior tree concepts and terminology.

# What is a Behavior Tree?
A behavior tree is a hierarchical node-based tree that controls the decision making of an entity. Behavior trees are used in fields such as robotics and control systems but their most common use is in video games. The "tree" in behavior tree refers to the data structure used to organize its nodes in a hierarchy, similar to how Godot itself organizes nodes in the scene and their parent/child relationship.\
The tree begins at the root node, evaluating each child node down the tree until it reaches a node that represents a single task such as moving the agent from point A to B or checking if a condition is true. How this flow (known as a Tick) reaches a certain node is determined by each node along the way and by the status of each child node, a status is simply a way for a node to inform its parent that it has succeeded/failed to do its task.\
(image: abstract tree diagram)
Typically behavior tree nodes are categorized into 3 types:
- Leaf Nodes: Nodes at the end of branches, meaning they can't have any further children, their role is to execute an action like shooting a gun or check a condition like "Is the target in range?".
- Decorator Nodes: Branch nodes that take a single leaf node and do something with its status, a common example is an Inverter, which takes the result of its child and inverts it (success->failure, failure->success).
- Composite Nodes: Branch nodes that can have multiple children and are responsible for determining the order of execution, they control the decision making aspect of a behavior tree. An example is the Sequence composite, which runs its children nodes in a sequence (is agent hungry? -> look for food -> eat food).\
We will dive into each category and each node in more details later, this is just an overview.
(image: simple tree example with each category highlighted)

Behavior trees gained attention after their use in Halo 2's AI system which was an improvement from Finite State Machines that were commonly used at the time, and have gained significant attention in gaming over the years to become the most common approach to game AI.

# Why Use a Behavior Tree?
## Advantages
The main reason the popularity of behavior trees is their high flexibility. They are modular in a sense that complex behaviors can arrise from combinations of simple tasks.\
(images: behavior tree from The Division and other publicaly available examples)
Behavior tree logic can be separated into sub-trees reducing dependency and minimizing potential for bugs, this also means that behavior trees are easier to maintain and debug even as they grow in size overtime.\
Nodes in behavior trees can be reused in multiple situations, this not only applies to individual nodes but to sub-trees, a combat decision branch for example can be reused across multiple enemy types, or a navigation sub-tree can be used in different places in the same tree.

## Finite State Machines
If you have implemented AI in your games before, you might've used a Finite State Machine. FSM is an approach that uses a number of states and conditions that dictate how to transition from one state to another, FSMs are generally simple and easy to implement (although there are more complex variations like Hierarchical State Machines), they are great for simple behaviors like switching between "idle", "attack" and "patrol" states but they have some drawbacks.\
The most problematic is that a FSM doesn't scale well. As it becomes more complex, managing all states and transitions can get messy, leading to tight coupling and code duplication in what's known as State Machine Hell.\
<img src="https://imgur.com/VocnUZm"/>
FSMs also lack support for parallel execution.

This isn't to say that Finite State Machines are inherently bad. They are perfect for simple implementations and small to medium scoped projects, like transitioning between few simple states. They are easy to setup and require less overhead, so for simple AI, prototyping or game jams etc... A FSM might be a better option.

Note that there are other approaches to AI implementations like GOAP (Goal-Oriented Action Planning), Utility AI, or even hybrids of different techniques and custom solutions. For the sake of this guide, and also my limited knowledge on other techniques, we will not discuss them.

# Addon Documentation
Documentation of this addon and its features [can be found here](using_addon.md).

# External Resources
https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work
https://robohub.org/introduction-to-behavior-trees/
https://en.wikipedia.org/wiki/Behavior_tree_(artificial_intelligence,_robotics_and_control)
https://www.youtube.com/channel/UCov_51F0betb6hJ6Gumxg3Q