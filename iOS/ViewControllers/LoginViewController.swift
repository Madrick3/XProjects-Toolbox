//
//  LoginViewController.swift
//  Xproject MLB App
//
//  Created by Thomas, William C on 6/12/19.
//  Copyright © 2019 Thomas, William C. All rights reserved.
//

import Foundation
import NetworkExtension
import UIKit
import os.log
import CoreLocation

#if canImport(CryptoKit)
import CryptoKit

#else
import CommonCrypto

#endif

class LoginViewController: UIViewController {
    var locationManager = CLLocationManager()
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var test_integer = 1
    var showed_popup = false
    
    //sets top bar to white text
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppUtility.lockOrientation(.portrait)
        activityIndicator.hidesWhenStopped = true
        
        print(test_integer)
        
        //Changes status bar style to light for whole app
        UIApplication.shared.statusBarStyle = .lightContent
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.navigationController?.isModalInPresentation = false
        
        
    }
    
    @IBAction func checkAdminPassword(_ sender: UIButton) {
        var userSettings = Settings()
        userSettings = userSettings.loadSettings()
        let alert = UIAlertController(title:"Enter Admin Password", message: "Please enter the administrator password", preferredStyle: .alert)
        alert.addTextField{
            (textField) in textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] //We force unwrap because we know that the text exists
            //print("txtfield: ", textField!.text!)
            //print("hashed input: " + self.hashPassword(value: textField!.text!))
            //print("passwords match?: " + textField!.text! + " - " + userSettings.adminPassword)
            if self.hashPassword(value: textField!.text!) != userSettings.adminPassword {
            //if false {
                //print("hashed input: " + self.hashPassword(value: textField!.text!))
                //print("passwords do not match: " + textField!.text! + userSettings.adminPassword)
                let badInputAlert = UIAlertController(title:"Password Not Recognized", message: "Please try again", preferredStyle: .alert)
                badInputAlert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(badInputAlert, animated: true, completion: nil)
            } else {
                os_log("User submitted the correct password", log: OSLog.default, type: .debug)
                self.performSegue(withIdentifier: "pushToAdminViewController", sender: alert )
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

        //Check to see if the user has done setup
        var userSettings = Settings()
        userSettings = userSettings.loadSettings()
        if (userSettings.initialSetup){ //Returns true if we want to do this initial setup
            let alert = UIAlertController(title:"First time setup", message: "Please enter the administrator password", preferredStyle: .alert)
            alert.addTextField{
                (textField) in textField.text = ""
            }
            alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] //We force unwrap because we know that the text exists and is at least ''
                let hashed = self.hashPassword(value: textField!.text!)
                userSettings.adminPassword = hashed
                userSettings.debugRoster()
                userSettings.initialSetup = false
                userSettings.saveSettings()
                
            }))
            self.present(alert, animated: true, completion: nil)
            
        

        }
        locationManager.requestAlwaysAuthorization()
        
        /*if(userSettings.spoofConnection){
            let alert = UIAlertController(title:"Spoof Connection Established", message: "Fake connection to hardware established!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
            os_log("Hardware Spoofing Is Active", log: OSLog.default, type: .debug)
        } else {
            let configuration = NEHotspotConfiguration.init(ssid: "PittXProject", passphrase: "Xproject19", isWEP: false)
            configuration.joinOnce = true
            print(self)
            //start the spinning wheel
            //activityIndicator.startAnimating()
            NEHotspotConfigurationManager.shared.apply(configuration) { (error) in
                if error != nil {
                    if error?.localizedDescription == "already associated."
                    {
                        os_log("User was already connected to the Raspberry Pi", log: OSLog.default, type: .debug)
                        self.showed_popup = false
                        //currentViewController.activityIndicator.stopAnimating()
                    }
                }else{
                        print(NEHotspotConfigurationError.userDenied)
                        //if(NEHotspotConfigurationError.userDenied){ //This may not have worked
                            let alert = UIAlertController(title:"Unable to connect to the WiFi network!", message: "Please restart the hardware and try again!", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            if !self.showed_popup {
                                 self.present(alert, animated: true, completion: nil)
                            }
                            os_log("User was unable to connect to the Raspberry Pi", log: OSLog.default, type: .debug)
                     //    }
                        //currentViewController.activityIndicator.stopAnimating()
                        self.showed_popup = true
                    }
            }
        }*/
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
    }
    
    func hashPassword( value: String) -> String {
        let answer = value.sha256()
        print("given: " + value + " was hashed to: " + answer)
        return answer

    }

}
