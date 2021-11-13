using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.Linq;
using CitizenFX.Core;
using CitizenFX.Core.Native;
using Newtonsoft.Json;

namespace FiveRace
{
    public class RaceServer : BaseScript
    {
        private List<dynamic> raceFiles = new List<dynamic>();
        private string resourceName = API.GetCurrentResourceName();
        enum ServerState
        {
            SETUP, // Players select skin, car, ...
            ONGOING, // Race ongoing
            POST // All players finished or DNF, showing scoreboard
        }

        //Current Race stuff
        private string current_race = String.Empty;
        private ServerState state = ServerState.SETUP;
        private string loadedMapXML;
        private List<Player> racers = new List<Player>();
        private int amount_of_checkpoints = 1;
        private int amount_of_laps = 1;
        private DateTime start_time;
        private int players_finished = 0;
        private DateTime first_finish_at;
        private Dictionary<Player, double> player_results = new Dictionary<Player, double>();
        private int players_ready = 0;
        public RaceServer()
        {
            #region MANAGEMENT_COMMANDS
            API.RegisterCommand("racelist", new Action<int, List<object>, string>((source, arguments, raw) =>
            {
                
                var count = 0;
                List<string> mapList = new List<string>();
                var numRes = API.GetNumResources();
                for (int i = 0; i < numRes; i++)
                {
                    var resource = API.GetResourceByFindIndex(i);
                    if (API.GetNumResourceMetadata(resource, "resource_type") > 0)
                    {
                        var type = API.GetResourceMetadata(resource, "resource_type", 0);
                        if (type == "map")
                        {
                            var json = API.GetResourceMetadata(resource, "resource_type_extra", 0);
                            var dict = JsonConvert.DeserializeObject<Dictionary<string, dynamic>>(json);
                            var gameTypes = dict["gameTypes"];
                            string wew = gameTypes.ToString();
                            if (wew.Contains("fivem-racing"))
                            {
                                count++;
                                mapList.Add(resource);
                            }
                            
                        }
                    }
                }
                Debug.WriteLine($"[racing] {count} races on this server:");
                foreach (var item in mapList)
                {
                    Debug.WriteLine(item);
                }

                foreach (var file in raceFiles)
                    Debug.WriteLine($"  {file}");
            }), false);
            API.RegisterCommand("loadrace", new Action<int, List<object>, string>(async (source, arguments, raw) =>
            {
                if (arguments.Count > 0)
                {
                    API.StartResource((string)arguments[0]);
                }
                else
                {
                    ScheduleNextRace();
                }
                
            }), false);
            API.RegisterCommand("startrace", new Action<int, List<object>, string>(async (source, arguments, raw) =>
            {
                if (current_race != String.Empty)
                {
                    await StartRace();
                }
                
            }), false);
            API.RegisterCommand("racestatus", new Action<int, List<object>, string>((source, arguments, raw) =>
            {
                Debug.WriteLine("Current race: " + current_race);
                Debug.WriteLine("Server state: " + state.ToString());
                Debug.Write("Racers:");
                foreach (Player racer in racers)
                {
                    Debug.WriteLine($"{racer.Handle} - {racer.Name}");
                }
            }), false);

            API.RegisterCommand("countdown", new Action<int, List<object>, string>((source, arguments, raw) =>
            {
                var countFrom_arg = (string)arguments[0];
                var countFrom = 3;
                if (int.TryParse(countFrom_arg, out countFrom) && countFrom > 0)
                {
                    string name;
                    if (source > 0)
                    {
                        name = API.GetPlayerName(source.ToString());
                    }
                    else
                    {
                        name = "server";
                    }
                    TriggerClientEvent("chatMessage", "[SYSTEM]", new[] { 0, 255, 0 }, $"{name} started a countdown");
                    TriggerClientEvent("racing:countdown", countFrom);
                }
                else
                {
                    Debug.WriteLine("Invalid countFrom arg");
                }
            }), false);
            #endregion
            EventHandlers["onMapStart"] += new Action<string>(OnMapStart);
            EventHandlers["racing:firstSpawn"] += new Action<Player>(OnPlayerFirstSpawn);
            EventHandlers["racing:readyForRace"] += new Action<Player>(OnPlayerReady);
            EventHandlers["racing:passedCP"] += new Action<Player, int>(OnPlayerPassedCP);
            EventHandlers["playerDropped"] += new Action<Player, string>(OnPlayerDropped);
            racers = Players.ToList();
            Tick += OnTick;
            
        }
        public void OnMapStart(string resourceName)
        {
            var numFiles = API.GetNumResourceMetadata(resourceName, "race");
            for (int fileIdx = 0; fileIdx < numFiles; fileIdx++)
            {
                var fileName = API.GetResourceMetadata(resourceName, "race", fileIdx);

                if (fileName.EndsWith(".xml"))
                {
                    LoadRace(resourceName, fileName);
                    return;
                }
            }

            Debug.WriteLine($"{resourceName} is invalid - it does not have any map .xml files!");
        }
        public void OnPlayerFirstSpawn([FromSource] Player p)
        {
            Debug.WriteLine($"[racing] sending game state ({state.ToString()}) to {p.Name}");
            switch (state)
            {
                case ServerState.SETUP:
                    //Load map
                    //Put player in car selector
                    racers.Add(p);
                    p.TriggerEvent("racing:loadrace", loadedMapXML, false);
                    break;
                case ServerState.ONGOING:
                    //Load map
                    //Put player in spectator mode
                    p.TriggerEvent("racing:loadrace", loadedMapXML, true);
                    break;
                case ServerState.POST:
                    //Show player the scoreboard
                    break;
                default:
                    break;
            }
        }

        public void OnPlayerReady([FromSource] Player p)
        {
            switch (state)
            {
                case ServerState.SETUP:
                    players_ready += 1;
                    break;
                case ServerState.ONGOING:
                    //Only do something when TIME ATTACK type of race
                    break;
                case ServerState.POST:
                    break;
                default:
                    break;
            }
            Debug.WriteLine($"[racing] Received READY from {p.Name} ({players_ready}/{racers.Count})");

        }

        public void OnPlayerDropped([FromSource] Player p, string reason)
        {
            racers.RemoveAll(racer => racer.Handle == p.Handle); 
            Debug.WriteLine("DROPPED " + p.Name + ": " + reason);
            if (racers.Count() == 0)
            {
                Debug.WriteLine("[racing] Nobody racing. Setting up next map.");
                ScheduleNextRace();
            }
        }

        public async Task OnTick()
        {
            if (racers.Count > 0)
            {
                switch (state)
                {
                    case ServerState.SETUP:
                        if (players_ready >= racers.Count)
                        {
                            Debug.WriteLine("[racing] All players ready, putting them to starting positions.");
                            var shuffledRacers = racers.OrderBy(a => Guid.NewGuid()).ToList();
                            foreach (var racer in racers)
                            {
                                var index = racers.IndexOf(racer);
                                racer.TriggerEvent("racing:startingGrid", index); // We shuffle the racers to give them randomized starting positions
                            }
                            state = ServerState.ONGOING;

                            // Wait for everybody to be on the starting grid
                            var startTime = API.GetGameTimer();

                            while ((API.GetGameTimer() - startTime) < 15000)
                            {
                                await BaseScript.Delay(0);

                                if (state != ServerState.ONGOING)
                                {
                                    break;
                                }
                            }

                            if (state == ServerState.ONGOING)
                            {
                                await StartRace();
                            }
                        }
                        break;
                    case ServerState.ONGOING:
                        async Task PostRaceFinish()
                        {
                            Debug.WriteLine($"[racing] Going to POST-race.");
                            state = ServerState.POST;
                            string results = "";
                            var sortedDict = from entry in player_results orderby entry.Value ascending select entry;
                            List<KeyValuePair<string, double>> resultList = new List<KeyValuePair<string, double>>();
                            foreach (var item in sortedDict)
                            {
                                resultList.Add(new KeyValuePair<string, double>(item.Key.Name, item.Value));
                            }
                            results = JsonConvert.SerializeObject(resultList);
                            

                            //foreach (var racer_result in sortedDict)
                           // {
                               // Debug.WriteLine($"{racer_result.Key.Name} : {racer_result.Value}");
                                //results += $"{racer_result.Key.Name}:{racer_result.Value};";
                           // }
                            //foreach (var r in racers)
                            //{
                            //    if (!player_results.ContainsKey(r))
                            //    {
                            //        results += $"{r.Name}:DNF;";
                            //    }
                            //}
                            TriggerClientEvent("racing:POST", results);

                            var startTime = API.GetGameTimer();
                            while ((API.GetGameTimer() - startTime) < 15000)
                            {
                                await BaseScript.Delay(0);

                                if (state != ServerState.POST)
                                {
                                    break;
                                }
                            }

                            if (state == ServerState.POST)
                            {
                                ScheduleNextRace();
                            }
                        }

                        if (players_finished >= racers.Count)
                        {
                            await PostRaceFinish();
                        }
                        else if (players_finished > 0)
                        {
                            if (DateTime.Now > first_finish_at + new TimeSpan(0,1,0))
                            {
                                await PostRaceFinish();
                            }
                        }
                        else
                        {

                        }
                        break;
                    case ServerState.POST:
                        break;
                    default:
                        break;
                }
            }
            TriggerClientEvent("racing:serverState", state.ToString()); // DEBUG
            await BaseScript.Delay(1000);
        }

        public void LoadRace(string resource, string fileName)
        {
            Debug.WriteLine("[racing] Loading " + resource);
            string race_xml = API.LoadResourceFile(resource, fileName);
            
            if (race_xml != null)
            {
                current_race = resource;
                loadedMapXML = race_xml;
                //Parse XML for serverside data setting
                XElement wew = XElement.Parse(loadedMapXML);
                amount_of_checkpoints = wew.Element("Checkpoints").Elements().Count();
                Int32.TryParse(wew.Element("Laps").Value, out amount_of_laps);
                if (amount_of_laps == 0)
                {
                    amount_of_laps = 1;
                }
                var name = wew.Element("Map").Element("Name").Value;
                Debug.WriteLine($"[racing] Loaded race! Name:{name}, cps: {amount_of_checkpoints}, laps: {amount_of_laps}");
                API.SetMapName(name);
                players_finished = 0;
                player_results = new Dictionary<Player, double>();
                players_ready = 0;
                racers.Clear();
                state = ServerState.SETUP;
            }
            else
            {
                Debug.WriteLine("[racing] Error: Could not load that race");
            }
        }
        public async Task StartRace()
        {
            if (current_race != String.Empty)
            {
                //Take all racers, give them random starting position and put them there
                Debug.WriteLine("[racing] Starting countdown for race: " + current_race);
                var countdownSeconds = 3;
                TriggerClientEvent("racing:countdown", countdownSeconds);
                List<string> racer_ids = new List<string>();
                foreach (var r in racers)
                {
                    racer_ids.Add(r.Handle);
                }
                TriggerClientEvent("racing:setParticipants", racer_ids);
                await BaseScript.Delay(countdownSeconds * 1000);
                TriggerClientEvent("racing:GO");
                start_time = DateTime.Now;
                Debug.WriteLine($"[racing] RACE STARTED at " + start_time);
                state = ServerState.ONGOING;
            }
            else
            {
                Debug.WriteLine("[racing] Error: no race loaded");
            }

        }
        public void OnPlayerPassedCP([FromSource] Player p, int cp_id)
        {
            switch (state)
            {
                case ServerState.ONGOING:
                    // check if this CP is correct, eg ANTICHEAT
                    TriggerClientEvent("racing:playerCP", p.Handle, cp_id); // announce to all that this player has passed that CP
                    Debug.WriteLine($"[racing] {p.Name} just passed checkpoint {cp_id}/{amount_of_checkpoints*amount_of_laps}");
                    if (cp_id == amount_of_checkpoints*amount_of_laps) // finished
                    {
                        players_finished += 1;
                        var finished_time = DateTime.Now;
                        if (players_finished == 1)
                        {
                            first_finish_at = finished_time;
                        }
                        var elapsed_time = finished_time - start_time;
                        Debug.WriteLine($"[racing] {p.Name} finished in {elapsed_time} ({players_finished}/{racers.Count})");
                        var racer = racers.Where(player => player.Handle == p.Handle).First();
                        player_results.Add(racer, elapsed_time.TotalMilliseconds);
                        TriggerClientEvent("racing:playerFINISHED", p.Handle, players_finished, elapsed_time.TotalMilliseconds); // announce that this player has finished
                        //TriggerClientEvent("chatMessage", "[RACE] ", new[] { 0, 255, 0 }, p.Name + " finished in position "+players_finished);
                    }
                    break;
                default:
                    break;
            }           
        }

        private void ScheduleNextRace()
        {
            //Exports["mapmanager"].roundEnded(); //Why does this not work, even with the latest mapmanager?
            TriggerEvent("mapmanager:roundEnded");
        }

    }

}
