//
//  settingViewController.swift
//  Xproject MLB App
//
//  Created by Su, Xinya on 7/9/19.
//  Copyright © 2019 Thomas, William C. All rights reserved.
//

import Foundation
import UIKit
import os.log
import MessageUI
     
#if canImport(CryptoKit)
    import CryptoKit
#else
    import CommonCrypto
#endif

class settingViewController: UITableViewController, isAbleToReceiveData, MFMailComposeViewControllerDelegate{
    var userSettings:Settings = Settings()
    var passedData: String = String()
    var type: Int = Int()
    var mailComposeVC: MFMailComposeViewController = MFMailComposeViewController()
    
    let settingOptions = [
        ["Add Team", "Remove Team", "Edit Team Name"],
        ["Change Default Team/Location"],
        ["Export to CSV"],
        ["Change Admin Password"],
        ["Return to Debug Roster", "Wipe Rosters", "Load Saved Roster", "Overwrite Roster on Disk", "Spoof Hardware", "Auto-Adjust Player IDs"]
    ]
    
    let header = ["Adjust Rosters", "Default Roster", "Export Data","Security", "Debug"]
    
    var indexSelected:Int = 0
    var sectionSelected:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // title
        self.navigationItem.title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = true
        userSettings = userSettings.loadSettings()
        // table
        self.tableView!.register(UITableViewCell.self, forCellReuseIdentifier: "settingOptions")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        userSettings.saveSettings()
    }
    
    private func editTeams(input: Int, ip: IndexPath){
        print("In editteams")
        print("debugprint before load")
        self.userSettings.printDebug()
        self.userSettings = userSettings.loadSettings()
        print("debugprint after load")
        self.userSettings.printDebug()
        if input == 0{
            let alert = UIAlertController(title:"New Team", message: "Please enter the new team name", preferredStyle: .alert)
            alert.addTextField{
                (textField) in textField.placeholder = "Unchanged"
            }
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] //We force unwrap because we know that the text exists
                print("txtfield: ", textField!.text!)
                self.checkState(parent: "editTeams:addTeam", success: self.userSettings.addTeam(tm: textField!.text!))
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        } else if input == 1{ //User wants to Remove a team
            showPopOverBox(arg: 1, ip: ip)
        } else if input == 2{
            showPopOverBox(arg: 2, ip: ip)
        } else {
            os_log("Edit Teams index selected was not a valid and developed option", log: OSLog.default, type: .error)
        }
    }
    
    /*
     Abstraction for different debug options that require more code so that func didSelectRowAt is not huge
     leve is effectively a switch/case for the function
     Pull the lever Kronk!
    */
    public func debugRosters(lever: Int){
        if lever == 0{
            let state = userSettings.debugRoster()
            if(state == true){
                os_log("Roster has returned to default state.", log: OSLog.default, type: .debug)
                let alert = UIAlertController(title: "DEBUG", message: "Your Rosters Have Reverted for Debugging", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Debug Roster Succeeded", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                self.present(alert, animated: true, completion: nil)
            }else{
                os_log("Roster did not return properly! *FLAG*", log: OSLog.default, type: .debug)
                let alert = UIAlertController(title: "Error", message: "Something unexpected occurred: Your rosters were not reset!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Debug Roster Failed", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else if lever == 1 {
            let state = userSettings.emptyRoster()
            if(state == true){
                os_log("Roster has been wiped.", log: OSLog.default, type: .debug)
                let alert = UIAlertController(title: "DEBUG", message: "Your Rosters Have Been Wiped", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("Empty Roster Alert Success has Occured")
                }))
                self.present(alert, animated: true, completion: nil)
            }else{
                os_log("Roster did not return properly! *FLAG*", log: OSLog.default, type: .debug)
                let alert = UIAlertController(title: "Error", message: "Something unexpected occurred: Your rosters were not wiped!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("Empty Roster Alert Failure has Occured")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else if lever == 2 { //load saved Roster from disk
            userSettings.players = userSettings.loadBackupRoster()
            let state = userSettings.savePlayers()
            checkState(parent: "loadBackupRoster", success: state)
            if state{
                let alert = UIAlertController(title: "Success!", message: "Your backup roster has been properly loaded from disk!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("loadBackupRoster succeeded")
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Error!", message: "Your backup roster did not load correctly!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("loadbackupRoster failed")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else if lever == 3 { //save new roster to disk
            let state = userSettings.saveBackupRoster()
            checkState(parent: "saveBackupRoster", success: state)
            if state{
                let alert = UIAlertController(title: "Success!", message: "Your backup roster has been properly saved to disk!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("saveBackupRoster succeeded")
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Error!", message: "Your backup roster did not save correctly!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("saveBackupRoster failed")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else if lever == 4 { //Spoof hardware
            userSettings.spoofConnection = !userSettings.spoofConnection
            let state = userSettings.spoofConnection
            if state{
                let alert = UIAlertController(title: "Hardware Spoofed!", message: "Connection to hardware is fake. Fake values will be used.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("spoofConnection activated")
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Hardware Normal!", message: "Connection to hardware is real. Real values will be used.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("spoofConnection disabled")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        } else if lever == 5 { //Auto-adjust player ids
            let alert = UIAlertController(title: "Are you sure?", message: "Automatic Player ID Management will reassign player IDs for any duplicates.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "User engaged Automatic Player ID Management"), style: .default, handler: { _ in
                NSLog("Automatic ID activated")
                self.autoIDManagement()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "User decided not to rearrange IDs"), style: .default, handler: { _ in
                NSLog("Automatic ID not activated")
            }))
            self.present(alert, animated: true, completion: nil)
        } else if lever == 6 { //Manual change player ids
        
        }
    }
    
    public func autoIDManagement(){
        userSettings = userSettings.loadSettings()
        let newPlayers = userSettings.updatePlayersWithAutomaticIDs()
        userSettings.players = newPlayers
        _ = userSettings.savePlayers()
        os_log("Completed autoIDManagement")
    }
    

    //Runs when selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        sectionSelected = indexPath.section
        indexSelected = indexPath.row
        if(sectionSelected == 2){
            self.userSettings.players = self.userSettings.getAllPlayers()
            let CSV = self.userSettings.exportToCSV()
            print("in the CSV stuff")
            if CSV.count < 0{
                let alert = UIAlertController(title: "Failure!", message: "Something went wrong when saving the roster", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("CSV Failure State")
                }))
                self.present(alert, animated: true, completion: nil)
            } else if CSV.count == 0 {
                let alert = UIAlertController(title: "No Data to Save!", message: "You had no information to save", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("CSV Zero State")
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Save as...", message: "Please select the Destination to save the file to", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Save on Device", comment: "Hardcopy Action"), style: .default, handler: { _ in
                    NSLog("Save CSV to File")
                    self.userSettings.saveToFile(input: CSV)
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Attach to Email", comment: "Email action"), style: .default, handler: { _ in
                    NSLog("Send CSV to Email")
                    self.emailCSV()
                }))
                alert.addAction(UIAlertAction(title: NSLocalizedString("Nevermind", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("stop CSV")
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
        if(sectionSelected == 4){
            self.debugRosters(lever: indexSelected)
        } else if(sectionSelected == 3 && indexSelected == 0){
            let alert = UIAlertController(title:"Change Admin Password", message: "Please enter the new admin password", preferredStyle: .alert)
            alert.addTextField{
                (textField) in textField.text = "" //self.userSettings.adminPassword
            }
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] //We force unwrap because we know that the text exists
                print("txtfield: ", textField!.text!)
                self.userSettings.adminPassword = self.hashPassword(value: textField!.text ?? "4321")
                print("new password hashed: ", self.userSettings.adminPassword)
            }))
            self.present(alert, animated: true, completion: nil)
        } else if(sectionSelected == 1 && indexSelected == 0){ //Change Default Location
            showPopOverBox(arg: 0, ip: indexPath) //shows a list of the teams for the user, which will call pass with the type assigned by arg
        } else if(sectionSelected == 0){
            editTeams(input: indexSelected, ip: indexPath)
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //Gets a popover box of the below VC which presents a list of teams, self.type is assigned to arg so that we can deal with the data from pass accordingly
    func showPopOverBox(arg: Int, ip: IndexPath) {
        if let popoverViewController = self.storyboard?.instantiateViewController(withIdentifier: "FillWithListTableViewController") as!
            FillWithListTableViewController? {
            self.type = arg
            popoverViewController.modalPresentationStyle = .popover
            let popoverPresentationViewController = popoverViewController.popoverPresentationController
            popoverPresentationViewController?.permittedArrowDirections = UIPopoverArrowDirection.any
            popoverPresentationViewController?.sourceView = self.tableView
            popoverViewController.delegate = self
            //print(ip)
            //print(popoverPresentationViewController!.sourceRect)
            
            let rectOfCellInTableView = tableView.rectForRow(at: ip)
            let rectOfCellInSuperview = tableView.convert(rectOfCellInTableView, to: tableView.superview)
            //let cell = tableView.cellForRow(at: ip)
            //popoverPresentationViewController!.sourceRect = CGRect(x: cell!.bounds.midX, y: cell!.bounds.midY, width: 0, height: 0)
            popoverPresentationViewController!.sourceRect = CGRect(x: rectOfCellInSuperview.width/2, y: rectOfCellInSuperview.origin.y - (self.navigationController?.navigationBar.frame.size.height)!, width: 0, height: 0)
            //print(popoverPresentationViewController!.sourceRect)
            present(popoverViewController, animated: true, completion: nil)
        } else {
            print("ERROR ERROR ERROR")
        }
    }
    
    func pass(data: String){
        if self.type == 0 { //change home location for app boot
            userSettings.homeLocation = data
        } else if self.type == 1 { //remove a team and all its players
            let teamToDelete: String = data
            var allPlayers = userSettings.getAllPlayers()
            var i: Int = 0
            while i < allPlayers.count{
                if allPlayers[i].getTeam() == teamToDelete{
                    allPlayers.remove(at: i)
                } else {
                    i+=1
                }
            }
            userSettings.players = allPlayers; print(userSettings.savePlayers())
            print("team was removed through removeTeam(): ", userSettings.removeTeam(tm: teamToDelete))
            userSettings.players = userSettings.getAllPlayers()
        } else if self.type == 2 { //Edit a team's name and change all the players within that team to that new named team
            let originalTeamName: String = data
            var newTeamName: String = String()
            let alert = UIAlertController(title:"Rename Team", message: "Please enter the new name for the " + originalTeamName, preferredStyle: .alert)
            alert.addTextField{
                (textField) in textField.text = originalTeamName
            }
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] //We force unwrap because we know that the text exists
                print("txtfield: ", textField!.text!)
                newTeamName = textField!.text ?? "THE EMPIRE"
                self.userSettings.changeTeamName(oldName: originalTeamName, newName: newTeamName)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //returns number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        return settingOptions.count
    }
    
    //returns number of cells per section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingOptions[section].count
    }
    
    //creates individual cells
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingOptions", for: indexPath)
        let option = settingOptions[indexPath.section][indexPath.row]
        cell.textLabel?.text = option
        return cell
        
    }
    
    //create section header
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return header[section]
    }
    
     func checkState(parent: String, success: Bool){
        if success {
            print("Function: "+parent+" succeeded!")
        } else {
            print("Function: "+parent+" failed!")
        }
    }
    
    func hashPassword( value: String) -> String {
        let answer = value.sha256()
        print("given: " + value + " was hashed to: " + answer)
        return answer
    }
    
    func emailCSV() {
        mailComposeVC = MFMailComposeViewController()
        let hardStringData = NSKeyedArchiver.archivedData(withRootObject: userSettings.exportToCSV() as Any)
        
        let attachment: Data = userSettings.exportToCSV().data(using: String.Encoding.utf8, allowLossyConversion: false) ?? "Failed To Export".data(using: String.Encoding.utf8, allowLossyConversion: false)!
        mailComposeVC.mailComposeDelegate = self
        mailComposeVC.setToRecipients([])
        mailComposeVC.setSubject("Bat Testing Information")                                //change the text in this and the next 2 lines
        mailComposeVC.setMessageBody("Attached is a CSV for current tested Bats.", isHTML: false)
        mailComposeVC.addAttachmentData(attachment, mimeType: "text/csv", fileName: "batTesting.csv")
    
        if MFMailComposeViewController.canSendMail(){
            self.present(mailComposeVC, animated: true, completion: nil)
        }else{
            print("Can't send email")
        }
    }
    
    @objc(mailComposeController:didFinishWithResult:error:)
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
