//
//  Player.swift
//  Xproject MLB App
//
//  Created by Flaherty, Patrick Daniel on 6/17/19.
//  Copyright © 2019 Thomas, William C. All rights reserved.
//

import Foundation
import os.log
import UIKit

class Player: NSObject, NSCoding {
    
    //MARK: variables
    var name: String
    var team: String
    var id: String
    var bats: [Bat] = []
    var minorTeamNames: [String] = []

    
    // MARK: initialize variables
    init(n: String, t: String, i: String) {
        self.name = n
        self.team = t
        self.id = i
    }
    
    //MARK: Player functions
    
    /**
    Change name to the input string
    - Parameter n: the new player name
    - Throws: nil
    - Returns: nil
    */
    
    func setName(n: String){
        self.name = n
        if(n.elementsEqual(self.name)){ //Control statements for debug, prints to terminal specific messages on each case
            os_log("Changed to same name", log: OSLog.default, type: .debug)
        } else {
            os_log("changed name to new name", log: OSLog.default, type: .debug)
        }
    }
    
    /**
    Change team to the input string
    - Parameter t: the new team name
    - Throws: nil
    - Returns: nil
    */
    func setTeam(t: String){
        self.team = t
    }
    
    /**
    Get the player name
    - Parameter
    - Throws: nil
    - Returns: name of the player (String)
    */
    func getName()-> String{
        return self.name
    }
    
    /**
    Get the team name
    - Parameter
    - Throws: nil
    - Returns: name of the player's team (String)
    */
    func getTeam() -> String {
        return self.team
    }
    
    /**
    Get the team logo
    - Parameter
    - Throws: nil
    - Returns: UIImage of the team logo from assets
    */
    func getTeamImage() -> UIImage {

        let five_teams = ["SWBRailers", "Trenton Thunder", "Tampa Tarpons", "Charleston RiverDogs", "Staten Island Yankees", "Pulaski Yankees", "Gryffindor", "Hufflepuff", "Slytherin", "Ravenclaw"]
        if five_teams.contains(self.team) {
            return UIImage(named: self.team)!
        }
        return UIImage(named: "default yankees")!
    }
    
    /**
    Set the player ID
    - Parameter id: new id to be set
    - Throws: nil
    - Returns: nil
    */
    func setID(id: String){
        self.id = id
    }
    
    /**
    Get the player ID
    - Parameter
    - Throws: nil
    - Returns: player id (integer)
    */
    func getID() -> String{
        return id
    }
    
    /**
    Add bat to the database
    - Parameter bat: new bat object to be added
    - Throws: nil
    - Returns: nil
    */
    func addBat(bat: Bat) {
        bats.append(bat)
    }
    
    
    
    // MARK: helper fuctions
    public func toString() -> String{
        var str: String = self.name + ":" + self.team
        for b in bats{
            str.append("\n\t" + b.toString())
        }
        return str
    }
    
    public func getCSVString() -> String{
        var retVal: String = ""
        retVal.append(team + ",")
        retVal.append(name + ",")
        retVal.append(id + ",")
        
        return retVal
    }
    
    
    //MARK: Properties
    struct propertyKey{
        static let name = "name"
        static let team = "team"
        //static let numPTSessions = "numPTSessions"
        //static let scores = "scores"
        static let bats = "bats"
        static let id = "id"
    }
    
    //MARK: Archiving Paths
    //NB: static == belongs to class, not an instance of the class
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("players")
    static let BackupURL = DocumentsDirectory.appendingPathComponent("backupPlayers")
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder){
        aCoder.encode(name, forKey: propertyKey.name)
        aCoder.encode(team, forKey: propertyKey.team)
        aCoder.encode(id, forKey: propertyKey.id)
        aCoder.encode(bats, forKey: propertyKey.bats)
    }
    
    required convenience init?(coder aDecoder: NSCoder){
        // The name is required. If we cannot decode a name string, the initializer should fail.
        guard let name = aDecoder.decodeObject(forKey: propertyKey.name) as? String else {
            os_log("Unable to decode the name for a player object.", log: OSLog.default, type: .debug)
            return nil
        }
        guard let team = aDecoder.decodeObject(forKey: propertyKey.team) as? String else {
            os_log("Unable to decode the teaminfo for a player object.", log: OSLog.default, type: .debug)
            return nil
        }
        
        guard let id = aDecoder.decodeObject(forKey: propertyKey.id) as? String else {
            os_log("Unable to decode the player id for a player object.", log: OSLog.default, type: .debug)
            return nil
        }

        //Players may (and will) be saved without having tested in the PT app or with any bats so we can use optionals for these
        let bats = aDecoder.decodeObject(forKey: propertyKey.bats) as? [Bat]
        
        // Must call designated initializer.
        self.init(n: name, t: team, i: id)
        
        //Directly assign each of the other values of the player
        self.bats = bats ?? []
        
    }
    
    //MARK: debug method used for testing
    public func MARKERROR(){
        self.name = "ERROR: " + self.name
        print("ERROR HAS BEEN DETECTED IN PLAYER CREATION/LOADING")
    }
}

