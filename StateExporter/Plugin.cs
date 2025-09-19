using DemonBluffStateExporter;
using MelonLoader;
using HarmonyLib;
using Il2Cpp;
using MelonLoader.Utils;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[assembly: MelonInfo(typeof(Plugin), "Demon Bluff State Exporter", "1.0.0", "IngoH")]
[assembly: MelonGame("UmiArt", "Demon Bluff")]

namespace DemonBluffStateExporter
{

    [HarmonyPatch]
    public class Plugin : MelonMod
    {
        private int lastId = 0;
        private MelonPreferences_Category settings;
        private MelonPreferences_Entry<bool> writeToFile;
        private MelonPreferences_Entry<bool> writeHealth;
        private MelonPreferences_Entry<bool> writeSolution;
        
        public override void OnInitializeMelon()
        {
            MelonLogger.Msg("Demon Bluff State Exporter initialized!");
            MelonLogger.Msg("Press F1 to copy village state to clipboard (and log).");
            MelonLogger.Msg("Press F2 to reveal all cards in clockwise order starting from #1 (if possible).");
            
            settings = MelonPreferences.CreateCategory("DemonBluffStateExporter");
            writeToFile = settings.CreateEntry("WriteToFile", false, "Write puzzles to file (Puzzles/#id#.pzl)");
            writeHealth = settings.CreateEntry("WriteHealth", false, "Write health info to output (might break with obfuscation)");
            writeSolution = settings.CreateEntry("WriteSolution", false, "Write the solution (hidden roles) to output (to file only; #id#.sol). Ignored if WriteToFile is false");
            settings.SetFilePath("UserData/DemonBluffStateExporter.cfg");
            settings.SaveToFile();
        }

        public override void OnUpdate()
        {
            if (Input.GetKeyDown(KeyCode.F1))
            {
                var game = Gameplay.Instance;
                var characters = game.characters.characters;
                var chars = characters.ToArray().OrderBy(c => c.id).ToArray();
                var script = Gameplay.CurrentScript;
                var counts = new[] { script.town, script.outs, script.minion, script.demon };

                var deck = game.currentTownsfolks.ToArray().Select(c => c.name.Replace(" ", "_").ToLower())
                    .Concat(game.currentOutsiders.ToArray().Select(c => c.name.Replace(" ", "_").ToLower()))
                    .Concat(game.currentMinions.ToArray().Select(c => c.name.Replace(" ", "_").ToLower()))
                    .Concat(game.currentDemons.ToArray().Select(c => c.name.Replace(" ", "_").ToLower()))
                    .Distinct().ToList();

                var outStr = "# Village Data:";
                outStr += $"\nnum_chars: {string.Join(",", counts)}";
                var totalEvil = 0;
                foreach (var c in chars)
                {
                    var name = c.dataRef.name.Replace(" ", "_").ToLower();
                    if (c.dataRef.startingAlignment == EAlignment.Evil)
                    {
                        totalEvil++;
                    }

                    if (!deck.Contains(name))
                    {
                        deck.Add(name);
                    }
                }

                outStr += $"\nnum_evil: {totalEvil}";
                outStr += $"\nnum_revealed: {Gameplay.CurrentReveal}"; // n % 4 for night state
                outStr += $"\ndeck: {string.Join(",", deck)}";
                if (writeHealth.Value)
                {
                    var hp = (CurrentMaxValue)PlayerController.PlayerInfo.health.value;
                    outStr += $"\nhp: {hp.current}/{hp.max}";
                }
                foreach (var c in chars)
                {
                    outStr += "\n";
                    var state = c.state;
                    if (state == ECharacterState.Alive || (state == ECharacterState.Dead && !c.killedByDemon))
                    {
                        var labels = new List<string>();
                        var dead = false;
                        if (state == ECharacterState.Dead)
                        {
                            dead = true;
                            labels.Add("#dead");
                            if (c.statuses.statuses.Contains(ECharacterStatus.Corrupted))
                            {
                                labels.Add("#corrupted");
                            }
                        }
                        var info = c.bluff != null ? c.bluff.name.Replace(" ", "_").ToLower() : c.dataRef.name.Replace(" ", "_").ToLower();
                        if (dead && c.bluff != null)
                        {
                             info = c.dataRef.name.Replace(" ", "_").ToLower() + "|" + info;
                        }
                        var lblstr = string.Join(" ", labels);
                        if (!string.IsNullOrEmpty(lblstr))
                        {
                            lblstr += " ";
                        }
                        outStr += $"{c.order} {lblstr}{info}";
                        var ainfo = c.actedInfos.ToArray().LastOrDefault();
                        if (ainfo != null)
                        {
                            outStr += $" {ainfo.desc.Replace("\n", " ")}";
                        }
                    }
                    else
                    {
                        outStr += "[unknown]";
                        if (state == ECharacterState.Dead && c.killedByDemon)
                        {
                            outStr += " #killed_by_demon";
                            if (c.dataRef.startingAlignment == EAlignment.Evil)
                            {
                                outStr += " #hidden_evil";
                            }
                        }
                    }
                    if (writeToFile.Value)
                    {
                        WritePuzzleToFile(outStr);
                    }
                }
                if (writeSolution.Value)
                {
                    var solStr = "# Solution:";
                    foreach (var c in chars)
                    {
                        if (c.bluff == null)
                        {
                            if (c.statuses.statuses.Contains(ECharacterStatus.Corrupted))
                            {
                                solStr += "\n[real] #corrupted";
                            }
                            else
                            {
                                solStr += "\n[real]";
                            }
                        }
                        else
                        {
                            if (c.statuses.statuses.Contains(ECharacterStatus.Corrupted))
                            {
                                solStr += $"\n{c.dataRef.name.Replace(" ", "_").ToLower()} #corrupted";
                            }
                            else
                            {
                                solStr += $"\n{c.dataRef.name.Replace(" ", "_").ToLower()}";
                            }
                        }
                    }
                    if (writeToFile.Value)
                    {
                        WriteSolutionToFile(solStr);
                    }
                }
                GUIUtility.systemCopyBuffer = outStr;
                MelonLogger.Msg(outStr);
            }

            if (Input.GetKeyDown(KeyCode.F2))
            {
                var game = Gameplay.Instance;
                var characters = game.characters.characters;
                foreach (var character in characters.ToArray().Reverse())
                {
                    if (character.state == ECharacterState.Hidden)
                    {
                        character.OnClick();
                    }
                }
            }
        }
        
        private void WritePuzzleToFile(string content)
        {
            
            var root = System.IO.Path.Combine(MelonEnvironment.GameRootDirectory, "Puzzles");
            if (!System.IO.Directory.Exists(root))
            {
                System.IO.Directory.CreateDirectory(root);
            }
            lastId += 1;
            var file = System.IO.Path.Combine(root, $"{lastId}.pzl");
            while (System.IO.File.Exists(file))
            {
                lastId++;
                file = System.IO.Path.Combine(root, $"{lastId}.pzl");
            }
            System.IO.File.WriteAllText(file, content);
        }
        
        private void WriteSolutionToFile(string content)
        {
            var root = System.IO.Path.Combine(MelonEnvironment.GameRootDirectory, "Puzzles");
            if (!System.IO.Directory.Exists(root))
            {
                System.IO.Directory.CreateDirectory(root);
            }
            var file = System.IO.Path.Combine(root, $"{lastId}.sol");
            System.IO.File.WriteAllText(file, content);
        }
    }
}