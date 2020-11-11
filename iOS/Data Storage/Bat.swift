/*
 * Bat.swift
 * Xproject MLB App
 *
 * Created by Thomas, William C on 7/16/19.
 * Copyright © 2019 Thomas, William C. All rights reserved.
 *
 * Purpose:
 *  Bat.swift is an object that encompasses the characteristics of the bats that players and team administrators may test. These characteristics are saved and encoded to disk on the IOS Platform. (e.g. iPad or iPhone).
 *
 */

import Foundation

//MARK: CLASS DECLARATION
/*
 * Implements: NSCoding, NSObject - These interfaces allow the bats to be saved to disk.
 * Encoding: Bats are encoded to disk using the NSCoder built into the NSCoding interface.
 */
class Bat : NSObject, NSCoding {
    
    //MARK: Global Variables
    //Each of these variables are encoded and saved to disk for successfully tested bats. They are optionals due to NSCoding. Not all these parameters are required to create a bat, but certain iterations of the software may include some or more variables.
    var manufacturer:String? = nil
    var wrap:Bool? = nil
    var date:Calendar? = nil
    var identifier:String? = nil
    var length:Float? = nil
    var mass:Float? = nil
    var weight0:Float? = nil
    var weight1:Float? = nil
    var moi:Float? = nil
    var DateObj = Date()
    var period: Float? = nil
    var stdev: Float? = nil
    
    //MARK: NSObject/NSCoding
    //This propertyKey struct contains string keys used to encode and decode properties of our saved bats. These are also the properties presented to the user on the TestEpilogueViewController
    struct propertyKey{
        static let manufacturer = "manufacturer"
        static let wrap = "wrap"
        static let date = "date"
        static let identifier = "identifier"
        static let length = "length"
        static let mass = "mass"
        static let weight0 = "weight0"
        static let weight1 = "weight1"
        static let moi = "moi"
        static let DateObj = "DateObj"
        static let period = "period"
        static let stdev = "stdev"
    }
    
    //This function encodes the information stored within the bat object so that the Settings.Swift object can save it to disk.
    //Returns: Nothing
    func encode(with aCoder: NSCoder) {
        aCoder.encode(manufacturer, forKey: propertyKey.manufacturer)
        aCoder.encode(wrap, forKey: propertyKey.wrap)
        aCoder.encode(date, forKey: propertyKey.date)
        aCoder.encode(identifier, forKey: propertyKey.identifier)
        aCoder.encode(length, forKey: propertyKey.length)
        aCoder.encode(weight0, forKey: propertyKey.weight0)
        aCoder.encode(weight1, forKey: propertyKey.weight1)
        aCoder.encode(mass, forKey: propertyKey.mass)
        aCoder.encode(moi, forKey: propertyKey.moi)
        aCoder.encode(DateObj, forKey: propertyKey.DateObj)
        aCoder.encode(period, forKey: propertyKey.period)
        aCoder.encode(stdev, forKey: propertyKey.stdev)
    }
    
    //This function attempts to decode the information for a bat object from disk.
    //Returns: Nothing - Calls Bat Constructor if successful, returns 'nil' if failed.
    required convenience init?(coder aDecoder: NSCoder) {
        guard let manufacturer = aDecoder.decodeObject(forKey: propertyKey.manufacturer) as? String else {
            print("Error decoding bat object ", propertyKey.manufacturer)
            return nil
        }
        guard let wrap = aDecoder.decodeObject(forKey: propertyKey.wrap) as? Bool else {
            print("Error decoding bat object ", propertyKey.wrap)
            return nil
        }
        guard let date = aDecoder.decodeObject(forKey: propertyKey.date) as? Calendar else {
            print("Error decoding bat object ", propertyKey.date)
            return nil
        }
        guard let identifier = aDecoder.decodeObject(forKey: propertyKey.identifier) as? String else {
            print("Error decoding bat object ", propertyKey.identifier)
            return nil
        }
        guard let length = aDecoder.decodeObject(forKey: propertyKey.length) as? Float else {
            print("Error decoding bat object ", propertyKey.length)
            return nil
        }
        guard let mass = aDecoder.decodeObject(forKey: propertyKey.mass) as? Float else {
            print("Error decoding bat object ", propertyKey.mass)
            return nil
        }
        
        guard let weight0 = aDecoder.decodeObject(forKey: propertyKey.weight0) as? Float else {
            print("Error decoding bat object ", propertyKey.weight0)
            return nil
        }
        
        guard let weight1 = aDecoder.decodeObject(forKey: propertyKey.weight1) as? Float else {
            print("Error decoding bat object ", propertyKey.weight1)
            return nil
        }
        
        guard let moi = aDecoder.decodeObject(forKey: propertyKey.moi) as? Float else {
            print("Error decoding bat object ", propertyKey.moi)
            return nil
        }
        guard let stdev = aDecoder.decodeObject(forKey: propertyKey.stdev) as? Float else {
                   print("Error decoding bat object ", propertyKey.stdev)
                   return nil
               }
        guard let period = aDecoder.decodeObject(forKey: propertyKey.period) as? Float else {
                   print("Error decoding bat object ", propertyKey.period)
                   return nil
               }
        
        let DateObj = aDecoder.decodeObject(forKey: propertyKey.DateObj) as? Date
        self.init(manufacturer: manufacturer, wrap: wrap, date: date, identifier: identifier, length: length, mass: mass, weight0: weight0, weight1: weight1, moi: moi, period: period, stdev: stdev)
        self.DateObj = DateObj!
    }
    
    //MARK: Constructors
    //This constructor is used when we load a bat from disk. It is created with all available parameters.
    //Returns: Nothing - Constructs Bat object
    init(manufacturer:String, wrap:Bool, date:Calendar, identifier:String, length:Float, mass:Float, weight0:Float, weight1:Float, moi:Float, period: Float, stdev: Float) {
        self.manufacturer = manufacturer
        self.wrap = wrap
        self.date = date
        self.identifier = identifier
        self.length = length
        self.mass = mass
        self.weight0 = weight0
        self.weight1 = weight1
        self.moi = moi
        self.period = period
        self.stdev = stdev
    }
    
    //This constructor is used when we create a bat object at the start of testing.
    //Returns: Nothing - Constructs Bat object with limited information
    init(manufacturer:String, wrap:Bool, date:Calendar, identifier:String) {
        self.manufacturer = manufacturer
        self.wrap = wrap
        self.date = date
        self.identifier = identifier
    }
    
    //MARK: Member Functions
    //This function creates a short string representation of the bat. Used in debugging to determine existence.
    //Returns: String: Short description of the bat object.
    public func toString() -> String{
        return self.manufacturer! + ": " + self.identifier!
    }
    
    //This function creates a long string representation of the bat to be attached to a csv.
    //It creates the string object stringRep, and appends information to that string until ready for the CSV.
    //The stringRep variable is ended with a newline character '\n'. This implies that each row of the CSV will contain a bat.
    //Returns: String: CSV representation of the bat.
    public func toCSVString() -> String {
        var stringRep: String = getDateString() + ","
        stringRep.append((identifier ?? "") + ",")
        stringRep.append((manufacturer ?? "") + ",")
        stringRep.append(getWrapString() + ",")
        stringRep.append(String(length ?? 0) + ",")
        stringRep.append(String(mass ?? 0) + ",")
        stringRep.append(String(weight0 ?? 0) + ",")
        stringRep.append(String(weight1 ?? 0) + ",")
        stringRep.append(String(moi ?? 0) + ",")
        stringRep.append(String(period ?? 0) + ",")
        stringRep.append(String(stdev ?? 0) + "\n")
        return(stringRep)
    }
    
    //MARK: Getters and Setters
    func setManufacturer(manufacturer:String) {
        self.manufacturer = manufacturer
    }
    
    func setWrap(wrap:Bool) {
        self.wrap = wrap
    }
    
    func setDate(date:Calendar) {
        self.date = date
    }
    
    func setIdentifier(identifier:String) {
        self.identifier = identifier
    }
    
    func setLength(length:Float) {
        self.length = length
    }
    
    func setMass(mass:Float) {
        self.mass = mass
    }
    
    func setWeight0(weight0:Float){
        self.weight0 = weight0
    }
    
    func setWeight1(weight1:Float){
        self.weight1 = weight1
    }
    
    //Takes both weights (handle and barrel) as floats. Assigns handle weight (smaller weight) to weight0, assigns barrel weight to weight1.
    //Also sets self.mass to sum of weights.
    func setWeights(weight0: Float, weight1: Float){
        let smallWeight = min(weight0, weight1)
        let bigweight = max(weight0, weight1)
        self.weight0 = smallWeight
        self.weight1 = bigweight
        self.mass = weight0 + weight1
    }
    
    //Takes both period and swing standard deviation. Assigns these values. Assumes weight0 and weight1 have already been set.
    //Calculates moi using standard baseball equation found here: https://www.acs.psu.edu/drussell/bats/bat-moi-details.html
    func setMoi(period: Float, stdev: Float){
        self.period = period
        self.stdev = stdev
        var bp = (6*self.weight0! + 24*self.weight1!)
        bp /= (self.weight0! + self.weight1!)
        self.moi = (period * period)
        self.moi! *= ((self.weight0! + self.weight1!) * 386.2205 * (bp-6)) //386.2205 is g (9.81 m/s^2) in inches/(s^2)
        self.moi! /= (4 * 3.1415926 * 3.1415926)
    }
    
    func getManufacturer() -> String {
        return manufacturer!
    }
    
    func getWrap() -> Bool {
        return wrap!
    }
    
    //if the bat has a wrap, returns the string "Wrap", otherwise returns "No Wrap"
    func getWrapString() -> String {
        if self.wrap ?? false{
            return "Wrap"
        }else{
            return "No Wrap"
        }
    }
    
    func getDate() -> Calendar {
        return date!
    }
    
    func getIdentifier() -> String {
        return identifier!
    }
    
    func getLength() -> Float {
        return length!
    }
    
    func getMass() -> Float {
        return mass!
    }
    
    func getWeight0() -> Float {
        return weight0!
    }
    
    func getWeight1() -> Float {
        return weight1!
    }
    
    func getMoi() -> Float {
        return moi!
    }
    
    func getStdev() -> Float {
        return stdev!
    }
    
    func getPeriod() -> Float {
        return period!
    }
    
    //Returns a string representation of the dat object in "Month/DD/Year"
    func getDateString() -> String {
        let components = self.getDate().dateComponents([.month, .day, .year], from: DateObj)
        return (components.month?.description)! + "/" + (components.day?.description)! + "/" + (components.year?.description)!
    }
    
    
}
