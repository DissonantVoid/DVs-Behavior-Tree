## Roadmap
post 1.5:\
use github issues, tags and milestones to organize this

reachout to people
- reddit/discord
- https://github.com/godotengine/awesome-godot
- youtubers: https://www.youtube.com/@mrelipteach, https://www.youtube.com/gamefromscratch, https://www.youtube.com/@dev-worm, https://www.youtube.com/@ThisIsVini/videos

1.6:\
[] some placeholder node for prototyping that has its own debugger representation\
[] unit tests: (see https://github.com/bitwes/Gut)

## Future
Debugger real time display of export variables for each node, including custom nodes made by users. Might need to make it so you can only inspect the selected node to reduce debugger requests

Rename Decorators as Filters? more readable

ability to modify blackboard values in debugger

set default values for export variables, make sure it doesn't cause setter to not be called.

expose blackboard as export variable for initialization

add new signal emitter node that emits a signal defined in the agent script

add icons to each node name in [using addon](./(2)%20using%20addon.md) see [here](https://stackoverflow.com/questions/255170/markdown-and-image-alignment)

ability to display tree graph in a similar way to nodes in Nodes tab

tree stats in debugger:
- heatmap of the most visited nodes
- benchmarks for whole tree and individual nodes

## Resources
https://nodecanvas.paradoxnotion.com/documentation/?section=bt-nodes-reference

https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work

https://github.com/bitbrain/beehave

https://github.com/draghan/behavior_tree

https://dev.epicgames.com/documentation/en-us/unreal-engine/behavior-tree-in-unreal-engine---quick-start-guide?application_version=5.2

https://www.behaviortree.dev/docs/

https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter06_The_Behavior_Tree_Starter_Kit.pdf

https://github.com/aigamedev/btsk