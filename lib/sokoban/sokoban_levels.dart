// lib/sokoban/sokoban_levels.dart

/// Standard Sokoban level format:
/// # = wall, @ = player, $ = box, . = goal, * = box on goal,
/// + = player on goal, space = floor
class SokobanLevel {
  final String name;
  final List<String> data;

  const SokobanLevel({required this.name, required this.data});
}

enum SokobanDifficulty {
  easy('Easy', 0, 5),
  medium('Medium', 5, 5),
  hard('Hard', 10, 5),
  expert('Expert', 15, 5);

  final String label;
  final int startIndex;
  final int count;

  const SokobanDifficulty(this.label, this.startIndex, this.count);

  List<SokobanLevel> get levels =>
      sokobanLevels.skip(startIndex).take(count).toList();
}

const List<SokobanLevel> sokobanLevels = [
  // === Easy (1-5): 5x5 to 7x7, 1-2 boxes ===

  // Level 1: Simplest possible - 1 box, straight push
  SokobanLevel(name: 'Level 1', data: [
    '#####',
    '#. @#',
    '# \$ #',
    '#   #',
    '#####',
  ]),

  // Level 2: 1 box, L-shaped push
  SokobanLevel(name: 'Level 2', data: [
    '#####',
    '#   #',
    '# \$.#',
    '#  @#',
    '#####',
  ]),

  // Level 3: 1 box, slight navigation
  SokobanLevel(name: 'Level 3', data: [
    '######',
    '#    #',
    '# #\$ #',
    '# . @#',
    '#    #',
    '######',
  ]),

  // Level 4: 2 boxes, aligned goals
  SokobanLevel(name: 'Level 4', data: [
    '######',
    '#    #',
    '# \$\$ #',
    '# .. #',
    '#  @ #',
    '######',
  ]),

  // Level 5: 2 boxes, offset goals
  SokobanLevel(name: 'Level 5', data: [
    '#######',
    '#     #',
    '# .\$. #',
    '#  \$  #',
    '#  @  #',
    '#     #',
    '#######',
  ]),

  // === Medium (6-10): 7x7 to 8x8, 2-3 boxes ===

  // Level 6: 2 boxes with walls
  SokobanLevel(name: 'Level 6', data: [
    '#######',
    '#     #',
    '# # . #',
    '# \$#  #',
    '#  \$. #',
    '# @   #',
    '#######',
  ]),

  // Level 7: 2 boxes, narrow corridors
  SokobanLevel(name: 'Level 7', data: [
    '#######',
    '##   ##',
    '#  \$  #',
    '# #.# #',
    '#  \$  #',
    '# .@  #',
    '#######',
  ]),

  // Level 8: 3 boxes, open space
  SokobanLevel(name: 'Level 8', data: [
    '########',
    '#   #  #',
    '# \$  \$ #',
    '## .#  #',
    '# .\$   #',
    '#    . #',
    '#  @   #',
    '########',
  ]),

  // Level 9: 3 boxes, tricky layout
  SokobanLevel(name: 'Level 9', data: [
    '########',
    '#      #',
    '# \$#\$  #',
    '# .#.  #',
    '# \$#.  #',
    '#  #   #',
    '#  @ ###',
    '########',
  ]),

  // Level 10: 3 boxes, requires planning
  SokobanLevel(name: 'Level 10', data: [
    '########',
    '###   ##',
    '#  \$   #',
    '# .\$.  #',
    '##\$  ###',
    '##.@ ###',
    '## #####',
    '########',
  ]),

  // === Hard (11-15): 8x8 to 9x9, 3-4 boxes ===

  // Level 11: 3 boxes, complex walls
  SokobanLevel(name: 'Level 11', data: [
    '########',
    '##  ####',
    '# \$  . #',
    '#  ## .#',
    '# \$    #',
    '## #\$  #',
    '## @. ##',
    '########',
  ]),

  // Level 12: 4 boxes, room layout
  SokobanLevel(name: 'Level 12', data: [
    '#########',
    '#   ##  #',
    '# \$  \$  #',
    '## #.#  #',
    '# .  . ##',
    '#  \$  \$ #',
    '#   .@  #',
    '#   #   #',
    '#########',
  ]),

  // Level 13: 4 boxes, corridors
  SokobanLevel(name: 'Level 13', data: [
    '#########',
    '##  #   #',
    '#  \$\$   #',
    '# #.# # #',
    '# ..#.  #',
    '#  \$\$   #',
    '## @ # ##',
    '####   ##',
    '#########',
  ]),

  // Level 14: 3 boxes, twisty
  SokobanLevel(name: 'Level 14', data: [
    '#########',
    '##   #  #',
    '# \$  #  #',
    '#  ##.  #',
    '## \$  ###',
    '#  #.@  #',
    '#   \$  ##',
    '####. ##',
    '########',
  ]),

  // Level 15: 4 boxes, multi-room
  SokobanLevel(name: 'Level 15', data: [
    '#########',
    '#.  #   #',
    '# \$ # \$ #',
    '# # # #.#',
    '#   @   #',
    '#.# # #.#',
    '# \$ # \$ #',
    '#   #   #',
    '#########',
  ]),

  // === Expert (16-20): 9x9+, 4-5 boxes ===

  // Level 16: 4 boxes, large maze
  SokobanLevel(name: 'Level 16', data: [
    '##########',
    '#   ##   #',
    '# \$    \$ #',
    '#  .##.  #',
    '## #  # ##',
    '#  .##.  #',
    '# \$  @ \$ #',
    '#   ##   #',
    '##########',
  ]),

  // Level 17: 5 boxes, open
  SokobanLevel(name: 'Level 17', data: [
    '##########',
    '#        #',
    '# \$ .\$ . #',
    '# ##  ## #',
    '#  \$..   #',
    '#  ##  \$ #',
    '#  . @ \$ #',
    '#   ##   #',
    '##########',
  ]),

  // Level 18: 5 boxes, connected rooms
  SokobanLevel(name: 'Level 18', data: [
    '##########',
    '##  .   ##',
    '# \$ # \$  #',
    '#  .#.   #',
    '#  \$ # \$ #',
    '## .# .###',
    '#  \$@    #',
    '##      ##',
    '##########',
  ]),

  // Level 19: 5 boxes, tight
  SokobanLevel(name: 'Level 19', data: [
    '###########',
    '##   .  ###',
    '# \$  #\$   #',
    '#  .# # . #',
    '# \$  @\$ # #',
    '#  .#  \$. #',
    '##   #  ###',
    '###########',
  ]),

  // Level 20: 5 boxes, grand finale
  SokobanLevel(name: 'Level 20', data: [
    '###########',
    '##  .  .  #',
    '# \$ ## \$  #',
    '#  .# #   #',
    '## \$   \$ ##',
    '#  # @ #  #',
    '#   ## \$  #',
    '#  . #.   #',
    '###########',
  ]),
];
