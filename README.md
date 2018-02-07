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

## Filtering

Versions of miniloaders with and without filtering are available once the
appropriate technology has been researched.  As you would expect, to build a
miniloader capable of filtering, you must use filter inserters as ingredients.

Note that filter miniloaders behave like filter inserters, and not like vanilla
loaders: if no filters are set then no items will be moved. You must set at
least one filter.

## Known Issues

* The power usage UI counts each miniloader multiple times, since it shows the
  power used by the inserters, not the miniloaders themselves.
* Miniloaders cannot be fast-replaced due to the invisible entities blocking
  placement of the new entity.
* Miniloader has some incompatibilities with Mooncat's Creative Mode mod:
    * Instant Deconstruction leaves behind hidden inserters (fix is WIP).
* Miniloaders don't necessarily appear correctly in blueprints.

## Ultimate Belts Caveats and Warnings

__Ultimate Belts support is in BETA state.__

There appear to be Factorio core engine limitations when inserters pull from
belts faster than 5x yellow speed.

Miniloaders at "Ultra fast" and faster speeds use vanilla loader entities
to give full throughput when interacting with chests and other containers.

They will _not_ give full throughput when loading cargo wagons.

Filter miniloaders for these speeds are disabled, and circuit control is broken.
Do not upgrade miniloaders to these speeds if you are using circuit control.

Use with due caution and at your own risk to your factory.

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
* 1.2.0 (2017-12-14):
    * Update to Factorio 0.16.
* 1.3.0 (2017-12-18):
    * Rebalance ingredient costs.
    * Make yellow miniloader accessible before oil.
* 1.4.0 (2018-01-07):
    * Redesign using 0.16 customized loader entities instead of underground belt to provide belt connectivity.
    * Add support for controlling miniloaders through the circuit network. 
    * Add optional filtering support for miniloaders.
* 1.4.1 (2018-01-09):
    * Fix crash when placing underground belt with a miniloader on the opposite side.
    * Fix migration issue from 1.2.0-1.3.0 causing belt items to spill on the ground.
* 1.4.2 (2018-01-09):
    * Fix broken migration of yellow miniloaders.
    * Fix broken localization of items in hand.
* 1.4.3 (2018-01-09):
    * Apply migration to saves with v1.4.1.
* 1.5.0 (2018-01-12):
    * Separate filter miniloaders into their own entities.
    * Fix crash when connecting miniloaders directly to arithmetic or decider combinators.
    * Existing miniloaders will lose their filtering capabilities. Sorry for the inconvenience!
* 1.5.1 (2018-01-14):
    * Enable filter inserter recipes when migrating from pre-1.5.0.
* 1.5.2 (2018-01-14):
    * Fix blueprints having duplicate overlapping miniloaders.  Any blueprints in your inventory should be fixed, but blueprints in chests may need to be cleared and re-created.
    * Fix building miniloaders with Nanorobots.
    * Disable PickerExtended's dolly feature, since it can only move parts of miniloaders, breaking them.
* 1.5.3 (2018-01-15):
    * Reenable PickerExtended dolly. Thanks to Nexela for the fix suggestion.
    * Fix setting a blueprint that includes no entities, only tiles.
* 1.5.4 (2018-01-17):
    * Fix crash when alt-selecting with blueprint.
    * Fix crash during blueprinting.
* 1.5.5 (2018-01-18):
    * Add compatibility with upgrade-planner.
    * Ghosts can now be placed over miniloaders marked for deconstruction.
* 1.5.6 (2018-01-19):
    * Change recipes to use lower tiers of miniloaders as ingredients.
    * Add BETA support for Ultimate Belts mod.  See caveats and warnings above.
* 1.5.7 (2018-01-22):
    * Make sure stack size override is reset on non-circuit-controlled inserters.
    * Potentional fix for reported Omnimatter mod incompatibility.
* 1.5.8 (2018-02-06):
    * Using Upgrade Planner on miniloaders now preserves complex items (configured blueprints, armor with inventory, etc.)
    * Fix building over an existing miniloader with a blueprint where that miniloader is connected to the circuit network.
* 1.5.9 (1028-02-06):
    * Remove stray debugging code.