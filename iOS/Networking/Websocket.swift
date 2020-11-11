//
//  Websocket.swift
//  Xproject MLB App
//
//  Created by Thomas, William C on 8/5/19.
//  Copyright © 2019 Thomas, William C. All rights reserved.
//
//	Purpose:
//	 Websocket.swift is an object that handles the websocket for sending and receiving messages to and from the hardware.
//

import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import os.log

let TSTATE_WIFI_CHECK = 1
let TSTATE_HW_CONNECT = 2
let TSTATE_HB_CHECK = 3
let TSTATE_STOP = 4
let TSTATE_ERROR = 5

//MARK: WEBSOCKET CLASS DECLARATION
/*
 * Implements: NSObject - This interface allows the class the be handled as an NSObject
 *			   StreamDelegate - This interface allows the object to use streams for sending and receiving messages
 */

class Websocket: NSObject, StreamDelegate {
    
    //MARK: Global Variables
    
    
    let addr = "192.168.4.1"    //Static ip on rpi personal network
    let port = 9876             //port set in server code
    var inStream: InputStream?
    var outStream: OutputStream?
    var status: String?
    
    var connected = false
    var connCodeRec = false
    var retry = false
    
    //Callback Vars - When used in another file they run when updated in this object with a new piece of data
    var changingMessageStr: ((String)->())?
    var changingConnection: ((Bool)->())?
    var socketStatus: ((String)->())? //Options 'gray' 'gold' 'blue'
    var wifiStatus: ((String)->())? //Options 'gray' 'gold' 'blue'
    var valuesDispatch: ((Bool)->())?
    var statusText: ((String)->())?
    
    let heartbeatCode = "1010"
    let quitCode = "0000"
    let hardwareSetupCode = "0202"
    let massRequest = "1212"
    let lengthRequest = "3434"
    let MOIRequest = "5656"
    let testComplete = "0303"
    let disconnectCode = "9999"
    let connectionCode = "8888"
    
    var errors:[String] = []
    var values:[String] = []
    
    var messageQueue:[String] = []
    
    var timer: Timer?
    var timerFirstRun = true
    var heartbeatReceived = true
    var timerState = TSTATE_WIFI_CHECK
    var failureCount: Int = 0
    var hasReceivedErrorCode = false
    var wifiConnectCounter: Int = 0
    
    //MARK: INIT AND CALLBACKS
    override init(){
        super.init()
        self.socketStatus = { str in
            if(str == "gold") {
                self.sendMessage(message: self.hardwareSetupCode)
            }
        }
        self.changingMessageStr = { str in
            print("Callback! Changing message string: Websocket")
            print("Next in queue:", str)
            let inputsStr = self.queueNextPeak()
            if(inputsStr != "1010"){ //should 1010 - 10
                let inputs = self.dequeue()?.components(separatedBy: ",")
                print(inputs!)
                print(self)
                
                var inputsplit = ""
                for input in inputs!{
                    inputsplit += input + ":"
                }
                
                
                if(inputs!.count > 0){
                    if(inputs![0] == "5555" || inputs![0] == "6666") {
                        print("Something not connected to the pi")
                        self.hasReceivedErrorCode = true
                        for element in inputs!{
                            if(element != ""){
                                self.errors.append(element)
                            } else {
                                //self.errors.removeFirst() //since first will always be ""
                            }
                        }
                    } else {
                        print("RX message for bat data")
                        self.values = []
                        for element in inputs!{
                            self.values.append(element)
                        }
                        DispatchQueue.main.async {
                            self.valuesDispatch?(true)
                        }
                        
                    }
                }
            } else {
                _ = self.dequeue()
                print("Heartbeat received")
                self.heartbeatReceived = true
            }
        }
    }
    
    //MARK: TIMER STATE FUNCTION
    //Watchdog and Heartbeat timer function
    //Monitors the connection in parallel to rest of programming, function runs every 2 seconds and dispatches color codes to user
    public func setTimer(){
        self.dispatchStatusText(status: "Checking connections")
        self.hasReceivedErrorCode = false
        self.heartbeatReceived = false
        if(self.checkConnectiontoPittXProjectWifi()){
            self.timerState = TSTATE_HW_CONNECT
        } else {
            self.timerState = TSTATE_WIFI_CHECK
        }
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { timer in
            //MARK: TSTATE: WIFI CHECK
            print("TIMER STATE: " + String(self.timerState))
            if(self.hasReceivedErrorCode){
                self.timerState = TSTATE_ERROR
            }
            if(!self.checkConnectiontoPittXProjectWifi()){
                self.wifiConnectCounter += 1
                print("wificonnectcounter: " + String(self.wifiConnectCounter))
            } else {
                self.wifiConnectCounter = 0
                self.dispatchWifiStatus(status: "blue")
            }
            if(self.timerState == TSTATE_WIFI_CHECK) {
                let wifiConnected = self.checkConnectiontoPittXProjectWifi()
                self.dispatchSocketStatus(status: "gray")
                if(wifiConnected){
                    self.dispatchStatusText(status: "WiFi connection established, attempting to connect to hardware")
                    self.dispatchWifiStatus(status: "blue")
                    self.dispatchSocketStatus(status: "gray")
                    self.timerState = TSTATE_HW_CONNECT
                } else if(self.wifiConnectCounter >= 5){
                    self.dispatchWifiStatus(status: "gray") //dispatch gray wifi connection if 12 seconds pass with no wifi connection
                    self.dispatchSocketStatus(status: "gray")
                    self.dispatchStatusText(status: "Wireless network connection unsuccessful, restart the MOI rig and tap the WiFi icon to retry.")
                    self.timerState = TSTATE_STOP
                } else {
                    _ = self.connectToSocketNetwork()
                    self.dispatchStatusText(status: "Attempting to connect to WiFi network")
                    self.dispatchSocketStatus(status: "gray")
                    self.dispatchWifiStatus(status: "gold")
                }
            } else if(self.timerState == TSTATE_HW_CONNECT){
                let wifiConnected = self.checkConnectiontoPittXProjectWifi()
                if(wifiConnected){
                    self.dispatchWifiStatus(status: "blue")
                    if(!self.isConnected()){
                        self.connect()
                    }
                    self.dispatchStatusText(status: "Waiting for response from hardware")
                    self.dispatchSocketStatus(status: "gold")
                    self.timerState = TSTATE_HB_CHECK
                    self.sendHeartbeat()
                } else {
                    self.dispatchStatusText(status: "WiFi connection lost")
                    self.timerState = TSTATE_WIFI_CHECK
                    self.dispatchSocketStatus(status: "gray")
                    self.dispatchWifiStatus(status: "gray")
                }
            } else if(self.timerState == TSTATE_HB_CHECK){
                /* Timer State: Heartbeat Check
                 * Checks to see if a heartbeat was received.
                 *  1. Checks for WiFi prsenece, if no WiFi, return to WiFi Connect State, else, continue:
                 *  2. Checks for Hardware connection, if no connection, returns to HW_Con, else, continue
                 *  3. If a heartbeat was received, resets conditions and dispatches a blue socket. Stay.
                 *  4. If no heartbeat was received, resets conditions, dispatches gray, changes state: HW_CON
                 */
                let wifiConnected = self.checkConnectiontoPittXProjectWifi()
                if(!wifiConnected){ //1
                    self.connected = false
                    self.dispatchStatusText(status: "WiFi connection lost, attempting reconnect")
                    self.timerState = TSTATE_WIFI_CHECK
                    self.dispatchWifiStatus(status: "gray")
                    self.dispatchSocketStatus(status: "gray")
                } else {
                    self.dispatchWifiStatus(status: "blue")
                    if(!self.isConnected()){ //2
                        self.dispatchStatusText(status: "Hardware connection lost, attempting reconnect")
                        self.connected = false
                        self.heartbeatReceived = false
                        self.failureCount += 1
                        if(self.failureCount >= 5){
                            self.timerState = TSTATE_STOP
                        } else {
                            self.timerState = TSTATE_HW_CONNECT
                        }
                        self.dispatchSocketStatus(status: "gray")
                    } else {
                        if(self.heartbeatReceived){ //3
                            self.failureCount = 0
                            self.connected = true
                            self.heartbeatReceived = false
                            self.dispatchStatusText(status: "Hardware connection established")
                            self.dispatchSocketStatus(status: "blue")
                            self.sendHeartbeat()
                        } else { //4
                            self.connected = false
                            self.heartbeatReceived = false
                            self.dispatchStatusText(status: "Hardware connection lost, attempting reconnect")
                            self.dispatchSocketStatus(status: "gray")
                            self.failureCount += 1
                            if(self.failureCount >= 5){
                                self.timerState = TSTATE_STOP
                            } else {
                                self.timerState = TSTATE_HW_CONNECT
                            }
                        }
                    }
                }
            } else if(self.timerState == TSTATE_STOP) {
                self.failureCount = 0
                let wifiConnected = self.checkConnectiontoPittXProjectWifi()
                if(!wifiConnected){ //1
                    //self.timerState = TSTATE_WIFI_CHECK
                    self.dispatchSocketStatus(status: "gray")
                    self.dispatchWifiStatus(status: "gray")
                    let info = self.getConnectedWifiInfo() //this could fail if the user does not enable location 
                    if let s = info?["SSID"]{
                        //if (s as! String) != nil{
                            self.dispatchStatusText(status: s as! String)
                        //}
                    }
                } else {
                    self.dispatchSocketStatus(status: "gray")
                    self.dispatchWifiStatus(status: "blue")
                    self.dispatchStatusText(status: "Hardware failed to connect, restart the MOI rig and tap the rig icon to retry.")
                }
            } else if(self.timerState == TSTATE_ERROR){
                self.failureCount = 0
                let wifiConnected = self.checkConnectiontoPittXProjectWifi()
                self.dispatchSocketStatus(status: "red")
                self.dispatchStatusText(status: "Please verify that the hardware is correctly connected. Tap the rig icon when ready to retry")
                if(!wifiConnected){ //1
                    self.dispatchWifiStatus(status: "gray")
                } else {
                    if(self.heartbeatReceived){
                        self.sendHeartbeat()
                        self.heartbeatReceived = false
                    } else {
                        self.dispatchSocketStatus(status: "gray")
                        self.timerState = TSTATE_HW_CONNECT
                    }
                    self.dispatchWifiStatus(status: "blue")
                }
            }
        }
        
    }
    
    //MARK: CONNECT AND CHECK FUNCTIONS
    //This function establishes a connection with the websocket on the hardware.
    //This should be run when the hardware websocket reaches the server.accept() line in the Websocket file.
    //The function opens new in/out streams for receiving messages and opens them once a socket pair has been found.
    func connect(retry: Bool = false) {
        self.retry = retry
        print("Connect Function called starting")
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, addr as CFString, UInt32(port), &readStream, &writeStream)
        inStream = readStream!.takeRetainedValue()
        outStream = writeStream!.takeRetainedValue()
        
        inStream?.delegate = self
        inStream?.schedule(in: .current, forMode: .common)  //del
        
        outStream?.delegate = self
        outStream?.schedule(in: .current, forMode: .common) //del
        
        inStream?.open()
        outStream?.open()
        
        heartbeatReceived = true
        
    }
    
    //This function returns whether there is an open connection to the hardware.
    //Returns: Bool: True if the hardware is connected, False otherwise.
    func isConnected() -> Bool {
        print("iPad is checking to see if it is connected to the websocket")
        return connected || connCodeRec
    }
    
    //This function closes the connection to the hardware.
    //This should be run when a disconnect is desired (like if the app is exited).
    func disconnect() {
        print("iPad is choosing to disconnect from the websocket")
        connCodeRec = false;
        connected = false;
        
        self.sendMessage(message: disconnectCode)
        
        inStream?.close()
        outStream?.close()
    }
    
    //MARK: SENDMESSAGE FUNCTIONS
    public func sendSetupMessage(){
        self.sendMessage(message: hardwareSetupCode)
    }
    
    public func requestMassTest(){
        self.sendMessage(message: massRequest)
    }
    
    public func requestLengthTest(){
        self.sendMessage(message: lengthRequest)
    }
    
    public func requestMOITest(){
        self.sendMessage(message: MOIRequest)
    }
    
    public func sendHeartbeat(){
        self.sendMessage(message: heartbeatCode)
    }
    
    //This function sends a message to the connected hardware.
    //Params: message (String): The message that is sent to the hardware
    func sendMessage(message: String) {
        print("sending to server message: ", message)
        let data : Data = message.data(using: String.Encoding.utf8)! as Data
        _ = data.withUnsafeBytes { outStream?.write($0, maxLength: data.count) }
        
    }
    
    //MARK: STREAM
    //This function is essentially an event handler for all the default websocket messages (such as errors, connections , etc)
    //This function should never be called as it is called by backend code.
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.endEncountered: //Entered when a disconnect has been detected
            print("End Encountered")
            DispatchQueue.main.async {
                self.changingConnection?(false)
            }
            
            connected = false
            connCodeRec = false
            
            inStream?.close()
            inStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            
            outStream?.close()
            outStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            
        case Stream.Event.openCompleted: //Entered when a connection has been finalized
            print("Open Completed")
            DispatchQueue.main.async {
                self.changingConnection?(true)
                if(self.retry){
                    self.socketStatus?("bronze")
                } else {
                    self.socketStatus?("gold")
                }
            }
            connected = true
            
        case Stream.Event.hasBytesAvailable: //Entered when a message has been received and is ready to be handled
            print("stream has updated and has bytes available")
            if aStream == inStream {
                var buffer = [UInt8](repeating: 0, count: 200)
                
                inStream!.read(&buffer, maxLength: buffer.count)
                let bufferStr = NSString(bytes: &buffer, length: buffer.count, encoding: String.Encoding.utf8.rawValue)?.replacingOccurrences(of: "\0", with: "")
                
                print("Received:", bufferStr!)
                
                if(bufferStr! as String != connectionCode) { //Enqueue message so it can be read by other files elsewhere
                    enqueue(message: bufferStr! as String)
                    //print(bufferStr!)
                } else {
                    connCodeRec = true
                    //print("Making connCodeRec:",connCodeRec)
                }
                
            }
            
        case Stream.Event.errorOccurred: //Entered when an error has occured
            if(aStream.streamError.debugDescription.contains("Socket is not connected")){
                self.disconnect()
            }
            print("Error Occured:",eventCode.self, aStream.streamError as Any, aStream.streamStatus)
            let description = aStream.streamError.debugDescription
            var record: Bool = false
            self.status = ""
            for char in description{
                if char == "\"" { record = !record }
                if record  && char != "\""{
                    self.status?.append(char)
                }
            }
            
            
        default: //Entered when an unhandled case has been detected. There are others than are handled because some are auxillary and do not need a reaction for our purposes.
            print("if below is event 4, ignore! streamHasSpaceAvailable is not necessary to handle")
            print("Unhandled Event Code:",eventCode.self, aStream.streamError as Any, aStream.streamStatus.self)
            
        }
    }
    
    
    //MARK: WIFI CONNECTION
    //This function establishes a connection to the WiFi network hosted by the hardware for the purposes of sending messages with the websocket.
    //IMPORTANT: This should be run when the iOS device is not already connected to the network. This connection should be checked every time before using this function. To check use the checkConnectiontoPittXProjectWifi function below.
    //If the SSID or Passphrase for the network ever change the values in this function on the 4th line must be updated as well.
    //Returns: Bool: True if a connection has been established, False otherwise. If a connection already exists then this return can be unreliable and this function call can break that connection.
    func connectToSocketNetwork() -> Bool {
        var connectionstate: Bool = false
        
        let configuration = NEHotspotConfiguration.init(ssid: "PittXProject", passphrase: "Xproject19", isWEP: false)
        configuration.joinOnce = true
        self.dispatchWifiStatus(status: "gold")
        
        NEHotspotConfigurationManager.shared.apply(configuration) { (error) in
            if error != nil {
                if error?.localizedDescription == "already associated."
                {
                    print("Connected: already associated")
                    //self.dispatchWifiStatus(status: "blue")
                }
                else{
                    print("No Connected: can not connect")
                    connectionstate = true
                    //self.dispatchWifiStatus(status: "gray")
                }
            }
            else {
                print("Connected: Normal Operation")
            }
            _ = self.checkConnectiontoPittXProjectWifi()
        }
        
        return connectionstate
    }
    
    //This function returns a CFString holding information about the WiFi connection.
    //Returns: CFString: the string hold info about the connection and is status
    func getConnectedWifiInfo() -> [AnyHashable: Any]? {
        
        if let ifs = CFBridgingRetain( CNCopySupportedInterfaces()) as? [String],
            let ifName = ifs.first as CFString?,
            let info = CFBridgingRetain( CNCopyCurrentNetworkInfo((ifName))) as? [AnyHashable: Any] {
            
            return info
        }
        return nil
        
    }
    
    //This function checks if there is an existing connection to the WiFi.
    //This can not always confirm with 100% accuracy that there is not a connection if it returns false.
    //Returns: Bool: True if there is a connection, False if there is likely not a connection.
    func checkConnectiontoPittXProjectWifi() -> Bool{
        var userSettings: Settings = Settings()
        userSettings = userSettings.loadSettings()
        if(userSettings.spoofConnection){
            return true
        }
        let info = self.getConnectedWifiInfo()
        if let val = info?["SSID"] {
            if val as! String == "PittXProject"{
                print("IPad is connected to PittXProject Wifi")
                return true
            } else {
                print("Either not connected or forceUnwrap broke")
            }
        } else {
            print("maybe there is no key")
        }
        
        return false
    }
    
    
    
    //MARK: MESSAGE QUEUE
    //This function enqueues a message onto the messageQueue.
    //This should, for most purposes, never be called outside this file. The messageQueue is used to hold messages received from the hardware.
    //Params: message (String): the message to be enqueued.
    func enqueue(message: String) {
        messageQueue.append(message)
        
        //Enqueue message above and then update the callback var
        DispatchQueue.main.async {
            self.changingMessageStr?(message)
        }
        
    }
    
    //This function dequeues the message at the top of the messageQueue.
    //Returns: String: the message at the top of the queue. Will be nil if no messages in queue.
    func dequeue() -> String? {
        if (messageQueue.count > 0) {
            let message = messageQueue[0]
            messageQueue.remove(at: 0)
            return message
        } else {
            return nil
        }
    }
    
    //This function checks if there is an existing message in the messageQueue.
    //Returns: Bool: True if there is a message, False otherwise.
    func queueHasStatement() -> Bool {
        return messageQueue.count > 0 ? true : false
    }
    
    //This function peeks the message at the top of the queue and returns it.
    //Returns: String: the value of the string at the top of the messageQueue or "" if there is none.
    func queueNextPeak() -> String {
        return (self.queueHasStatement() ? messageQueue[0] : "")
    }
    
    
    //MARK: STATUS AND DISPATCH
    //This function returns the status of the socket connection.
    //Returns: String: contains the status of the socket connection or "Status Uncertain" if the status variable is uninitialized.
    func getSocketStatusString() -> String{
        return status ?? "Status Uncertain"
    }
    
    func dispatchWifiStatus(status: String){
        if(status != "gold" && status != "blue" && status != "gray"){
            print("status incorrect for wifi: ", status)
            return
        }
        DispatchQueue.main.async {
            self.wifiStatus?(status)
        }
    }
    
    func dispatchSocketStatus(status: String){
        if(status != "gold" && status != "blue" && status != "gray" && status != "red"){
            print("status incorrect for socket: ", status)
            return
        }
        DispatchQueue.main.async {
            self.socketStatus?(status)
        }
    }
    
    func dispatchStatusText(status: String){
        DispatchQueue.main.async {
            self.statusText?(status)
        }
    }
    
    
}
