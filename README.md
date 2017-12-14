# Miniloaders

This mod introduces miniloaders, 1x1 entities that efficiently transfer a full
belt worth of items into and out of containers, including train cargo wagons.

![Miniloaders in action with cargo wagons](https://github.com/mspielberg/factorio-miniloader/raw/master/cargo_unload.gif)

They use no Lua when running, keeping your factory's UPS healthy.

![Miniloader UPS usage](https://github.com/mspielberg/factorio-miniloader/raw/master/ups_cost.png)

You can use them to feed your high-speed assemblers,

![Miniloader assembler feed](https://github.com/mspielberg/factorio-miniloader/raw/master/assemblerdemo.png)

put them in your bus as compact priority splitters,

![Miniloader priority splitter](https://github.com/mspielberg/factorio-miniloader/raw/master/priority_split.gif)

or single-belt lane rebalancers.

![Miniloaders lane balancer](https://github.com/mspielberg/factorio-miniloader/raw/master/lane_rebalance.png)

Green and purple belts from Bob's Logistics are fully supported.

## Balancing

Miniloaders require stack inserter research, are relatively expensive to build,
and consume approximately the power of two fully-upgraded stack inserters.

## How it works

Each miniloader hides a set of very fast invisible inserters, one for each lane
of the belt.  Lua scripting adjusts pickup and drop points accordingly when the
direction of the miniloader is changed.

Since item movement is handled by inserters, there is no on_tick handler, no Lua
impact on UPS, and miniloaders will benefit from any future improvements to belt
and inserter performance made by Wube in the Factorio core.

## Known Issues

* Items currently held in the hand of the invisible inserters can still be seen,
  leading to odd graphical artifacts.  A mod
  [API change in 0.16](https://forums.factorio.com/viewtopic.php?f=65&t=54345)
  will fix this.
* The power usage UI counts each miniloader multiple times, since it shows the
  power used by the invisible inserters, not the miniloaders themselves.
* Miniloaders cannot be fast-replaced due to the invisible inserters blocking
  placement of the new entity.
* Miniloader has some incompatibilities with Mooncat's Creative Mode mod:
  * Instant Deconstruction leaves behind hidden inserters (fix is WIP).


## Acknowledgements

* Arch666Angel &mdash; for the original 2x1 loader graphics, cut down to 1x1 here
  with permission.
* Articulating &mdash; for the original Loader Snapping.
* Optera &mdash; for Loader Redux's revised and improved loader snapping code, adopted
  here for Miniloaders with permission.

## Version History

* 1.0.0 (2017-12-01):
    * Initial release.
* 1.1.0 (2017-12-03):
    * Add graphics and loader snapping.
* 1.1.1 (2017-12-05):
    * Fix some snapping issues (laying belts to the side of a miniloader, trying to snap to a player, sometimes snapping to the wrong direction when next to a large entities like assemblers).
* 1.1.2 (2017-12-06):
    * Fix critical crash bug when rotating miniloaders.
* 1.1.3 (2017-12-06):
    * Fix basic yellow miniloaders.  Oops.
    * Fix a case where items could be spilled onto adjacent tiles when snapping a miniloader to a belt.
* 1.1.4 (2017-12-11):
    * Remove orphan inserters left behind by yellow miniloaders if removed while 1.1.0-1.1.2 was installed.
    * Make snapping less aggressive.  Miniloaders should only turn 180 degrees, not 90 degrees, to better match behavior from Loader Redux.
* 1.1.5 (2017-12-14):
    * Remove the problematic separate force for miniloader inserters, and set a stack size override instead.