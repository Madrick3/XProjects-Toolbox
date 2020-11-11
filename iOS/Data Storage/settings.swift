/*
* Settings.swift
* Xproject MLB App
*
* Created by Patrick Flaherty on 7/14/19
* Copyright © 2019 Thomas, William C. All rights reserved.
*
* Purpose:
*  Settings.swift is an object used to store user settings. Its also used to interface with the encoding and decoding of player and bat
*  objects.
*
*/

import Foundation
import os.log

#if canImport(CryptoKit)
import CryptoKit
#endif

//MARK: CLASS DECLARATION
/*
 * Implements: NSCoding, NSObject - These interfaces allow the settings, players, and bats to be saved to disk.
 * Encoding: User settings parameters are saved to disk so that they persist between launches. Also allows for saving of other information
 * such as bats and players.
 */
class Settings: NSObject, NSCoding{
    
    //MARK: Archiving Paths
    //These are used to determine where the userSettings are saved within the device's file structure
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("settings")
    
    //MARK: Global Variables
    //Each of these variables are encoded and saved to disk. They are not optionals. All of these options must be decoded. This may be changed in the future to accomodate earlier versions.
    //adminPassword is specifically that string of numbers. This is the SHA256 encryption of a blank string (""). This is used to specify a simple default admin password.
    var defaultRoster: String
    var homeLocation: String
    var players = [Player]()
    var defaultPlayers = [Player]()
    var teams = [String]()
    var adminPassword = "65336230633434323938666331633134396166626634633839393666623932343237616534316534363439623933346361343935393931623738353262383535"
    var shownPlayers = [Player]()
    var initialSetup: Bool
    var spoofConnection: Bool
    let ErrorPlayer = Player(n: "ERROR", t: "New York Yankees", i: "999999")
    
    //MARK: NSCoding and NSObject
    //This propertyKey struct contains string keys used to encode and decode properties of our saved user settings.
    struct propertyKey{
        static let defaultRoster = "defaultRoster"
        static let teams = "teams"
        static let adminPassword = "adminPassword"
        static let homeLocation = "homeLocation"
        static let initialSetup = "initialSetup"
        static let spoofConnection = "spoofConnection"
    }
    
    //This function encodes the information stored within the settings object so that the NSCoding can save it to disk.
    //Returns: Nothing
    func encode(with aCoder: NSCoder){
        aCoder.encode(defaultRoster, forKey: propertyKey.defaultRoster)
        aCoder.encode(teams, forKey: propertyKey.teams)
        aCoder.encode(adminPassword, forKey: propertyKey.adminPassword)
        aCoder.encode(homeLocation, forKey: propertyKey.homeLocation)
        aCoder.encode(initialSetup, forKey: propertyKey.initialSetup)
        aCoder.encode(spoofConnection, forKey: propertyKey.spoofConnection)
    }
    
    //This function attempts to decode the information for a Settings object from disk.
       //Returns: Nothing - Calls Settings Constructor if successful, returns 'nil' if failed.
    required convenience init?(coder aDecoder: NSCoder){
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let dr = aDecoder.decodeObject(forKey: propertyKey.defaultRoster) as? String else {
            os_log("Unable to decode the defualt roster setting.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let tms = aDecoder.decodeObject(forKey: propertyKey.teams) as? [String] else {
            os_log("Unable to decode the teams.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let admpass = aDecoder.decodeObject(forKey: propertyKey.adminPassword) as? String else {
            os_log("Unable to decode the adminpassword.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let home = aDecoder.decodeObject(forKey: propertyKey.homeLocation) as? String else {
            os_log("Unable to decode the home location.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let initialSetup = aDecoder.decodeBool(forKey: propertyKey.initialSetup) as Bool? else{ //primitives do not decode correctly
                os_log("Unable to decode initialsetup value.", log: OSLog.default, type: .debug)
                return nil
        }
        guard let spoofConnection = aDecoder.decodeBool(forKey: propertyKey.spoofConnection) as Bool? else {
            os_log("Unable to decode realData value.", log: OSLog.default, type: .debug)
            return nil
        }
        // Must call designated initializer.
        self.init(dr: dr, tms: tms, admpass: admpass, home: home, initialSetup: initialSetup, spoofConnection: spoofConnection)
    }
    
    //MARK: Save and Load Functions
    //This function attempts to save the Settings object to disk using the archive path descrived above.
    //Returns: Nothing
    public func saveSettings(){
        //self.savePlayers()
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self, toFile: Settings.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Settings successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save Settings...", log: OSLog.default, type: .error)
        }
    }
    
    //This function attempts to load the Settings object from disk using the archive path descrived above.
    //Returns: Settings object: Correctly loaded settings if successful, or default settings if not.
    public func loadSettings() -> Settings {
        os_log("Attempting to load settings", log: OSLog.default, type: .debug)
        return NSKeyedUnarchiver.unarchiveObject(withFile: Settings.ArchiveURL.path) as? Settings ?? Settings()
    }
    
    //This function attempts to save the players objects to disk using the archive path descrived above.Player classes archive path.
     //Returns: Boolean: True if successful, False if something fails to save.
    public func savePlayers()->Bool{
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(players, toFile: Player.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Players successfully saved.", log: OSLog.default, type: .debug)
            for p in players{
                print(p.toString())
            }
            return true
        } else {
            os_log("Failed to save Players...", log: OSLog.default, type: .error)
            return false
        }
    }
    
    //This function attempts to load a list of Players objects from disk using the archive path in Player.swift
    //Returns: Array of Players: Correctly loaded players if successful, does not return if failed.
    public func loadPlayers() -> [Player]? {
        os_log("Attempting to load players", log: OSLog.default, type: .debug)
        return NSKeyedUnarchiver.unarchiveObject(withFile: Player.ArchiveURL.path) as? [Player]
    }
    
    //This function attempts to save the players objects to disk using the archive path for backup players. This can be used to step back to a good list of players.
    //Returns: Boolean: True if successful, False if something fails to save.
    public func saveBackupRoster()->Bool{
        os_log("User has attempted to replace the backup team!")
        self.players = self.getAllPlayers()
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(players, toFile: Player.BackupURL.path)
        if isSuccessfulSave {
            os_log("Players successfully saved for backup roster.", log: OSLog.default, type: .debug)
            for p in players{
                print(p.toString())
            }
            return true
        } else {
            os_log("Failed to save backup  roster Players...", log: OSLog.default, type: .error)
            return false
        }
    }
    
    //This function attempts to load the backup roster players objects.
    //Returns: List of Players - Backup Roster
    public func loadBackupRoster() -> [Player] {
        os_log("Attempting to load settings", log: OSLog.default, type: .debug)
        return NSKeyedUnarchiver.unarchiveObject(withFile: Player.BackupURL.path) as? [Player] ?? [ErrorPlayer]
    }
    
    //MARK: Constructors
    
    //This function is the default constructor for the settings object. Does not specify all values.
    //Returns: Nothing - Constructs a Settings Object
    override init(){
        defaultRoster = "Slytherin"
        homeLocation = "Slytherin"
        initialSetup = true
        spoofConnection = false
    }
    
    //This function is the constructor for the settings object used when decoding from disk.
    //Returns: Nothing - Constructs a Settings Object given specific parameters
    init(dr: String, tms: [String], admpass: String, home: String, initialSetup: Bool, spoofConnection: Bool){
        self.defaultRoster = dr
        self.homeLocation = home
        self.teams = tms
        self.adminPassword = admpass
        self.initialSetup = initialSetup
        self.spoofConnection = spoofConnection
    }
    
    //MARK: Get Players or Teams
    //This function gets a list of all players from loadPlayers, it checks for errors and retursn the errorplayer if there is a mistake
    //Returns: List of Players from disk or a list of the Error Player
    public func getAllPlayers() -> [Player] {
        return self.loadPlayers() ?? [ErrorPlayer]
    }
    
    public func getPlayerByID(id: String) -> Player {
        let allPlayers = self.getAllPlayers()
        for p in allPlayers{
            if(p.id == id){
                return p
            }
        }
        return ErrorPlayer
    }
    
    public func getSortedListOfPlayerIDs() -> [Int] {
        let allPlayers = self.getAllPlayers()
        var IDList = [Int]()
        for p in allPlayers{
            IDList.append(Int(p.id) ?? 0)
        }
        IDList.sort()
        return IDList
    }
    
    public func standardizeID(id: String) -> String{
        let numberID = Int(id) ?? 0
        var newID = id
        if(numberID < 10){
            newID = "000" + String(newID)
        } else if(numberID < 100) {
            newID = "00" + String(newID)
        } else if(numberID < 1000) {
            newID = "0" + String(newID)
        } else {
            newID = String(newID)
        }
        return newID
    }
    
    /* This function will iterate through all players and adjust Player IDs so that they are all unique.
    * First this function collects a list of all Player IDs and orders them in a list from lowest to highest.
    * Then it will determine the lowest Player ID, and begin to replace duplicate IDs with unique IDs starting at the lowest player id.
    *
    */
    public func updatePlayersWithAutomaticIDs() -> [Player]{
        let allPlayers = getAllPlayers()
        var newID: Int = 1
        for player in allPlayers{
            player.id = self.standardizeID(id: String(newID))
            newID+=1
        }
        return allPlayers
    }
    
    //This function iterates through the list of players given, and checks for players that match with the given teams list.
    //Returns: List of Lists of Players - Each sublist pertains to a specific team and contains players for only that desired team
    public func filterPlayersForTeam(playersToFilter: [Player]?, teams: [String] ) -> [[Player]?]?{
        //print("SETTINGS.PLAYERS")
        for p in self.players{
            print(p.toString())
        }
        var playersFitToTeams = [[Player]]()
        //playerToFilter and teams must be non-nil objects for this to run
        let tcount = teams.count
        var t: Int = 0
        while t < tcount{
            var pfort = [Player]()
            var p: Int = 0
            while p < playersToFilter!.count{
                if playersToFilter![p].team == teams[t]{
                    pfort.append(playersToFilter![p])
                }
                p+=1
            }
            t+=1
            playersFitToTeams.append(pfort)
        }
        return playersFitToTeams
    }
    
    //This function is used to get a list of all the teams saved to disk. These are teams saved to disk through Settings.saveSettings(), and also teams who are listed by the players.team variable.
    //Returns: List of strings - all teams in the entire database, directly saved team strings and player.team strings
    public func getTeams() -> [String]{
        let result = removeTeam(tm: "viewTitle")
        if(!result){
            os_log("viewTitle is still present in teams list after remveTeam called")
        }
        os_log("Returning the names of the teams!")
        var tms: [String] = teams
        print("get team has found coded teams: ", teams)
        let allPlayers = loadPlayers() ?? []
        var c: Int = Int()
        for p in allPlayers{
            if p.team == "viewTitle" {
                continue
            }
            c = 0
            while c < tms.count{
                if p.team == tms[c]{
                    break
                } else {
                    c+=1
                }
            }
            if c == tms.count{
                tms.append(p.team)
            }
        }
        //check if the default is viewtitle, just in case
        if self.defaultRoster == "viewTitle" {
            if tms.count > 0 {
                changeDefaultRoster(s: tms[0])
                saveSettings()
            }
        }
        return tms
    }
    
    //MARK: Change Players/Teams
    //This function clears the list of players and the list of teams and saves these empty lists to disk.
    //Returns: Bool - True if successful save, false if failed to save
    public func emptyRoster() -> Bool{
        players = [Player]()
        teams = [String]()
        defaultRoster = "viewTitle"
        return savePlayers()
    }
    
    public func doesPlayerWithIDExist(id: String) -> Bool{
        let allPlayers = loadPlayers() ?? []
        for p in allPlayers{
            if p.getID() == id {
                return true
            }
        }
        return false
    }
    
    //This function takes a list of players and iterates through the current list of players stored within the settings object. It compares each of these players name variables, and replaces the settings.player with the given one
    //Returns: Nothing
    public func overwriteSomePlayers(p: [Player]){
        var i0 = 0;
        while i0 < p.count{
            var i1 = 0; var done = false
            while (i1 < players.count && !done){
                if players[i1].id == p[i0].id{
                    print("overwriting player: ", players[i1].name)
                    players[i1] = p[i0]
                    done = true
                }
                i1+=1
            }
            i0+=1
        }
    }
    
    //This function adds a team to the list of teams in the Settings object
    //Returns: Boolean: True if the string given is a valid name, False if the name is invalid (e.g. "")
    public func addTeam(tm: String) -> Bool{
        //returns true if the team is added properly, false if not
        print("In add team with tm: " + tm)
        if tm == "" {
            return false
        }
        self.players = self.getAllPlayers()
        self.teams = self.getTeams()
        self.teams.append(tm)
        _ = self.savePlayers()
        self.saveSettings()
        return true
    }
    
    //This function removes a team from the list of teams in the Settings object
    //Returns: Boolean: True if the string given is a valid name, False if the name is invalid (e.g. "")
    public func removeTeam(tm: String) -> Bool{
        //Returns true if the number of teams after removing is different, false if the number of teams remains constant
        self.players = self.getAllPlayers()
        let c0 = teams.count
        teams.removeAll { $0 == tm }
        let c1 = teams.count
        if c0 == c1{
            return false
        } else {
            _ = self.savePlayers()
            self.saveSettings()
            return true
        }
    }
    
    //This function changes a team name and the team variables for all players with the previous name
    //Returns: Nothing
    public func changeTeamName(oldName: String, newName: String){
        self.players = self.getAllPlayers()
        var i: Int = 0
        print("Starting changeteamname")
        while i < teams.count{
            print(teams[i])
            if teams[i] == oldName{
                teams[i] = newName
            }
            i+=1
        }
        for p in self.players{
            if p.team == oldName{
                p.team = newName
            }
        }
        let result = self.savePlayers()
        self.saveSettings()
        if(!result){
            os_log("Something went wrong with changing team name")
        }
    }
    
    //MARK: Change Settings
    //This function changes the default roster variable of the settings object
    //Returns: Nothing
    public func changeDefaultRoster(s: String){
        self.defaultRoster = s
    }
    
    //This function changes the roster completely. It removes all saved players and teams, it adds to the roster the below debug roster
    //Returns: Nothing
    public func debugRoster() -> Bool{
        teams = []
        
        var tm: String = "Gryffindor"
        players.append(Player(n: "Harry Potter", t: tm, i: "634726"))
        players.append(Player(n: "Hermione Granger", t: tm, i: "834874"))
        tm = "Hufflepuff"
        players.append(Player(n: "Newt Scamander", t: tm, i: "834189"))
        players.append(Player(n: "Cedric Diggory", t: tm, i: "447686"))
        tm = "Ravenclaw"
        players.append(Player(n: "Luna Lovegood", t: tm, i: "688373"))
        players.append(Player(n: "Gilderoy Lockhart", t: tm, i: "873833"))
        tm = "Slytherin"
        players.append(Player(n: "Severus Snape", t: tm, i: "883433"))
        players.append(Player(n: "Draco Malfoy", t: tm, i: "973537"))
        
        // test for image for minor league teams
        let five_teams = ["SWBRailers", "Trenton Thunder", "Tampa Tarpons", "Charleston RiverDogs", "Staten Island Yankees", "Pulaski Yankees"]
        players.append(Player(n: "player1 fromSWBRailers", t: five_teams[0], i: "11111111"))
        players.append(Player(n: "player1 fromTT", t: five_teams[1], i: "222222"))
        players.append(Player(n: "player1 fromTT", t: five_teams[2], i: "333333"))
        players.append(Player(n: "player1 fromCR", t: five_teams[3], i: "444444"))
        players.append(Player(n: "player1 fromSIY", t: five_teams[4], i: "555555"))
        players.append(Player(n: "player1 fromPY", t: five_teams[5], i: "666666"))
        
        self.changeDefaultRoster(s: tm)
        teams = getTeams()
        return savePlayers()
    }
    
    //MARK: CSV and File Saving
    //This function iterates through each player and creates one giant string to represent the data in a CSV format
    //Returns: String- CSV format of all players and bats with headers, uses commas as cell delimiters and newline characters as line delimiters
    public func exportToCSV() -> String{
        let t = getTeams()
        let pfort = filterPlayersForTeam(playersToFilter: self.players, teams: t)
        print("CSV.PLAYERS") //Debug statement
        var CSV: String = String()
        CSV.append("Team, Name, ID Number, Test Date, Identifier, Manufacturer, Wrap, Length, Total Weight, Handle Weight, Barrel Weight, MOI, Swing Period, Swing Deviation\n")
        for plist in pfort!{
            for p in plist!{
                let pString = p.getCSVString()
                if p.bats.count == 0{
                    CSV.append(pString)
                    CSV.append("\n")
                }else{
                    for b in p.bats{
                        CSV.append(pString + b.toCSVString())
                    }
                }
            }
        }
        return CSV
    }
    
    //This function accepts a string object as data and saves it to disk in a .csv file named "Bat_Testing_yyyy-mm-dd hh:mm.csv"
    //Returns: Nothing
    public func saveToFile(input: String){
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString = formatter.string(from: now)
        let name: String = "Bat_Testing_" + dateString + ".csv"
        
        _ = self.write(text: input, to: name, folder: "Bat Testing CSVs")
    }
    
    //MARK: Private Functions
    //This function accepts a string object as data and saves it to disk in a file to the given filename"
    //Returns: Bool - true if function completes.
    private func write(text: String, to fileNamed: String, folder: String) -> Bool{
        os_log("Attempting to write file ", log: OSLog.default, type: .debug)
        guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else { return false}
        guard let writePath = NSURL(fileURLWithPath: path).appendingPathComponent(folder) else { return false}
        try? FileManager.default.createDirectory(atPath: writePath.path, withIntermediateDirectories: true)
        let file = writePath.appendingPathComponent(fileNamed + ".txt")
        try? text.write(to: file, atomically: false, encoding: String.Encoding.utf8)
        return true
    }
    
    //This follows SHA256 encoding to hash the user's password. This uses stringExtension.swift
    //Returns: String - Encoded password
    private func hashPassword( value: String) -> String {
        let answer = value.sha256()
        return answer
    }
    
    public func printDebug(){
        let allPlayers = self.getAllPlayers()
        self.teams = self.getTeams()
        print(allPlayers.count)
        for tm in self.teams{
            print(tm)
            let pfort = self.filterPlayersForTeam(playersToFilter: allPlayers, teams: [tm])
            let players = pfort?[0]
            for p in players ?? [self.ErrorPlayer]{
                print(tm + " " + p.name)
            }
        }
    }
}
