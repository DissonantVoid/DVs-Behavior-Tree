## Roadmap
reachout to people after 1.4
- reddit/discord
- https://github.com/godotengine/awesome-godot
- youtubers: https://www.youtube.com/@mrelipteach, https://www.youtube.com/gamefromscratch, https://www.youtube.com/@dev-worm, https://www.youtube.com/@ThisIsVini/videos
- add to godotassetlibrary

1.5:\
[] move license and readme into the addon folder and include icon with the addon\
[..] finish space game example\
[] document "your first behavior tree"\
[] mark functions that are expected to be overridden\
[] additional nodes (in their own "extra" folder so we don't bloat the main folder):\
   -play animation (optional wait for finish)\
   -play sound (optional wait for finish)\
   -agent look at (2d/3d) (requires character2d)\
   -agent go to (2d/3d) (requires nav agent and nav mesh)\
   -play particles (optional wait for finish)\
[] script templates without comments\

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


## Self Reminders
- if a node emits an editor warning in _get_configuration_warnings, don't repeat the warning at runtime somewhere else
- avoid asserting, prefer throwing warnings and accounting for errors instead of crashing
- allow user to add non BT nodes under a branch, and just ignore them
- mark major and minor versions with git tags
- nodes should not have any children in local scene since users will be instancing with "add child node" which works similar to attaching the script to an empty node, same for connecting signals, do so in code
- color palette: primary af9dd9, secondary 4a4563
- icon file name should match scene file name of the same node
- use same node descriptions in code for docs node descriptions
- minimum supported version is 4.3

## Resources
https://nodecanvas.paradoxnotion.com/documentation/?section=bt-nodes-reference\
https://www.gamedeveloper.com/programming/behavior-trees-for-ai-how-they-work\
https://github.com/bitbrain/beehave\
https://github.com/draghan/behavior_tree\
https://dev.epicgames.com/documentation/en-us/unreal-engine/behavior-tree-in-unreal-engine---quick-start-guide?application_version=5.2\
https://www.behaviortree.dev/docs/\
https://www.gameaipro.com/GameAIPro/GameAIPro_Chapter06_The_Behavior_Tree_Starter_Kit.pdf\
https://github.com/aigamedev/btsk\