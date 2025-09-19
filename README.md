# Demon Bluff Web Interface
This repository contains the web interface for the Demon Bluff Solver/Helper/Visualizer/etc. The web interface is built in Godot Engine and exported to HTML5 with WebAssembly (WASM).

## Projects
`StateExporter` is a MelonLoader mod that exports the game state to the clipboard. This can be pasted into the web interface importer to load the village state for visualization and solving.  
The exporter only exports known information. Characters that are not revealed show up as unknown and characters that bluff will show up as their bluff (unless executed).  
A compiled version of the mod can be found in [Releases](https://github.com/IngoHHacks/DemonBluffWebInterface/releases)

`WebInterface` is the Godot project that contains the web interface. It can be exported to HTML5 with WebAssembly (WASM) for use in a web browser.
The current production version is hosted at https://ingoh.net/dbwi

`pzl1000` is a folder with 1000 puzzles (village states) that can be used for testing and benchmarking.  
The first 500 were with all cards being revealed in clockwise order and no actions being taken. The second 500 were with all cards being revealed in clockwise order with all actionable characters being executed with random targets.
Note that one of the puzzles is already solved by sheer luck, so make sure you can handle that case if you're using these puzzles for your own solver. Format is `<id>.pzl` and `<id>.sol`, where `<id>` is a number from 1 to 1000. The `.pzl` file contains the puzzle and the `.sol` file contains the solution (in the custom formats described below).

## Features (Web Interface)
- Visualize Demon Bluff villages
- Solve Demon Bluff villages
- Import and export village states
- Add extra information (e.g. known bluffs, known roles, markers, etc.) to the village state

## Puzzle File Format
Puzzles use a custom text format that is easy to read and write. Metadata is stored in 'key: value' format and any other lines are treated as character definitions. Comments can be added with '#' at the start of a line.
Character definitions are considered in clockwise order starting from the game's #1 position.  
Example:
```
# Example puzzle
num_chars: 2,2,1,1
# -> 2 Villagers, 2 Outcasts, 1 Minion, 1 Demon
deck: hunter,architect,bishop,plague_doctor,wretch,bombardier,doppelganger,puppeteer,baa,puppet
# -> Deck composition (In-game names converted to snake_case)
1 plague_doctor
# -> Character 1 is a revealed Plague Doctor without a statement, reveal order 1.
2 bishop Between #2, #4, #8 there is: Villager, Minion and Outcast
# -> Character 2 is a revealed Bishop with a statement, reveal order 2.
4 hunter I am 1 card away from closest Evil
# -> Character 3 is a revealed Hunter with a statement, reveal order 4.
6 architect #dead #corrupted Right side is more Evil
# -> Character 4 is a revealed dead and corrupted Architect with a statement, reveal order 6 (5 is missing due to #6 being killed by Lilis).
3 architect Both sides are equally Evil
# -> Character 5 is a revealed Architect with a statement, reveal order 3.
[unknown] #killed_by_demon
# -> Character 6 is an unknown character killed by Lilis
```
### Metadata
Metadata keys:
- `num_chars`: Number of characters from each type. Format: `VILLAGERS,OUTCASTS,MINIONS,DEMONS`. Example: `2,2,1,1`
- `deck`: Comma-separated list of cards in the deck. Cards must be in snake_case format (e.g. `plague_doctor`, `bombardier`, `baa`, etc.). Example: `hunter,architect,bishop,plague_doctor,wretch,bombardier,doppelganger,puppeteer,baa,puppet`
- `num_evil`: Number of evil characters (minions + demons). Not used by the web interface solver.
- `num_revealed`: Number of revealed characters, including ones killed by Lilis. Not used by the web interface solver.
- `hp`: Current HP of the village. Not used by the web interface solver.

The order of metadata keys does not matter.  
When writing a parser, you must ignore unknown metadata keys to allow for future extensions.
`num_chars` and `deck` are required for the web interface importer to work.

### Tags
Characters can have the following tags:
- `#dead`: Character is dead
- `#killed_by_demon`: Character was killed by Lilis
- `#corrupted`: Character is Corrupted
- `#hidden_evil`: Character is [unknown] but is known to be Evil (e.g. due to being killed by Lilis)
- `#never_disguised`: The character's role is known to be real and not a bluff (not part of automatic exports, but can be added manually)
- `#never_corrupted`: The character is known to not be Corrupted (not part of automatic exports, but can be added manually)

The order of tags does not matter, but they must be directly after [unknown] or the character role.
When writing a parser, you must ignore unknown tags to allow for future extensions.

### Solution File Format
Solutions files are much simpler. They only contain a list of real character roles in clockwise order starting from the game's #1 position. If the real role is the same as the character's bluff, it is denoted as `[real]`. If a character is corrupted, it is tagged with `#corrupted`. Comments can be added with '#' at the start of a line.
Example:
```
# Example solution
[real]
[real] #corrupted
minion
[real]
doppelganger
counsellor
```
The order of characters must match the order in the puzzle file.  
No metadata or tags are allowed in solution files, and only the tag `#corrupted` is allowed.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request if you have any ideas or improvements.

## Credits
All code by IngoH (currently).  
Many assets are from the game Demon Bluff by UmiArt. Ownership of these assets remains with UmiArt or their respective owners as noted. The use of these assets is for non-commercial purposes only. If you are UmiArt and have any issues with the use of these assets, please contact me.  
Assets not from the game are public domain, creative commons, made by contributors, or otherwise free to use. If you are the owner of any assets used in this project and have any issues with their use, please contact me.

## License
CC0 (Public Domain)  
That means you can do whatever you want with this code and assets, including using it in commercial projects, without any restrictions, but please note the credits above regarding asset ownership.  
No warranty is provided. Use at your own risk.  
Full license in `LICENSE` file.

## Important Note
I am totally the best player of Demon Bluff ever and this tool is just to help you be as good as me lol :]  
Prove it? Okay:
- I have over 300 confirmed saved villages on Endless Mode.
- I once solved a village in under 5 minutes without any hints or tools.
- I have every single achievement in the game.
- I never lost a ranked match in Demon Bluff (Ranked matches aren't a thing because it's a singleplayer game, but if they were, I wouldn't lose).
- All my friends are jealous of my Demon Bluff skills (They don't say so, but I can tell).
- I am the reigning champion of my local Demon Bluff tournament (I made it up, but it sounds impressive).
- Rumor has it that the developers of Demon Bluff consulted me for game balance and design (Rumor has it).
- I once solved a village by accident by just clicking randomly (It's not luck, it's skill).
- Enough said.


## Contact
@ingoh on Discord or open an issue here on GitHub.
