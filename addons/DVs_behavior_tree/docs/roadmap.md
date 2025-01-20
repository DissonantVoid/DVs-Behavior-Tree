## Roadmap
reachout to people after 1.5
- reddit/discord
- https://github.com/godotengine/awesome-godot
- youtubers: https://www.youtube.com/@mrelipteach, https://www.youtube.com/gamefromscratch, https://www.youtube.com/@dev-worm, https://www.youtube.com/@ThisIsVini/videos

1.5:\
[X] add license duplicate to addon folder\
[..] document "your first behavior tree"\
   - figure out best approach to have both project and its template in one repo without duplication\
[X] mark functions that are expected to be overridden\
[X] additional nodes (in their own "extra" folder so we don't bloat the main folder):\
   - [X] play animation (optional wait for finish)
   - [X] play sound (optional wait for finish)
   - [X] play particles (optional wait for finish)
   - [X] documentation
   - [X] icons
[X] script templates without comments (and update image about using templates)\

## Future
other nodes:
- parallel node (runs all children in parallel)
- placeholder leaf (holds desciption of what the branch is going to have)

unit tests: (see https://github.com/bitwes/Gut)

debugger real time display of export variables for each node, including custom nodes made by users

ability to modify blackboard values in debugger

tree stats in debugger:
- heatmap of the most visited nodes
- benchmarks for whole tree and individual nodes

make into gdextention plugin

## Resources
https://nodecanvas.paradoxnotion.com/documentation/?section=bt-nodes-reference

https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work

https://github.com/bitbrain/beehave

https://github.com/draghan/behavior_tree

https://dev.epicgames.com/documentation/en-us/unreal-engine/behavior-tree-in-unreal-engine---quick-start-guide?application_version=5.2

https://www.behaviortree.dev/docs/

https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter06_The_Behavior_Tree_Starter_Kit.pdf

https://github.com/aigamedev/btsk