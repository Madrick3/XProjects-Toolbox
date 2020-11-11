#!/usr/bin/python
#Interfacing Script
#
#   This file must be the one run first (or on startup if running the hardware on startup). The file handles the order of testing, controls the websocket file, and controls the hardware file.
#   
#   Below are the important messages sent or received by the websocket:
#       "1010" - Heartbeat Message - Send as opposed to 6666 or 5555 if everything is setup in hardware correctly
#       "0000" - Quit Message
#       "0202" - Begin Testing - instantiate hardware class and send errors if there are issues
#       "1212" - Mass Request
#       "3434" - Length Request
#       "5656" - MOI/Period Request
#       "9999" - Quit Tests
#       "8888" - initial connection code
#       "6666" - Gate not connected
#       "5555" - One or more scales missing
#       "0303" - Test end message
#   
#   Testing Order:
#       1. Length
#       2. Weight
#       3. Period/MOI

#Necessary Imports: Time for sleep, threading for asyncClose function
import time, threading
from HardwareClass import HardwareClass
from WebsocketServer import WebsocketServerClass
import os, atexit

#Initial Variable Setup
server = WebsocketServerClass() #This function will hang until a new device is connected.
weight = -1
length = -1
moi    = -1
interfacing = True
hardware = HardwareClass()
testingBegan = False
recHeartbeat = True
connCnt = 0 #A count held for the purposes of reconnecting. If this value reaches to high of a number, the reconnection attempts will cease.
disconnPrint = False
joinThread = False
heartbeatLive = True
initializing = True
serverReset = False
errorMsg = ""
log = open("/home/pi/Desktop/Code/MOI.log", "a")
log.write("Starting log\n")

def stopAsyncs():
    global terminalThread, heartbeatThread
    print("async stop")
    log.write("async stop\n")
    terminalThread.stop()
    heartbeatThread.stop()
    
#Starts the asyncClose function on another thread. This line must be run before anything else to run correctly.
def startAsyncs():
    global terminalThread, heartbeatThread
    terminalThread.start()
    heartbeatThread.start()

#asyncClose Function:
#   This function reads the cmd line and waits for a "q" or "Q" input. If received, the server will be disconnected, hardware and its connections closed, and the current process will be terminated
def asyncClose():
    global server, hardware
    print("terminalThread start")
    log.write("terminalThread start\n")
    while True:
        try:
            line = raw_input()
            if line == "q" or line == "Q":
                print("Quitting")
                log.write("Quitting\n")
                server.stop()
                hardware.close()
                exit()
        except:
            2+2

def heartbeatChecks():
    global joinThread, heartbeatLive, testingBegan, recHeartbeat, server
    print("heartbeatThread start")
    print("hbl: " + str(heartbeatLive))
    log.write("heartbeatThread start")
    recHeartbeat = True
    heartbeatCheck = True
    while(True):
        while(heartbeatLive):
            print("heartbeatcheck")
            log.write("heartbeatcheck\n")
            if joinThread:
                print("Heartbeat is joining")
                log.write("heartbeat is joining\n")
                heartbeatLive = False
                return
            if not testingBegan: #remove when we move heartbeats to all testing screens
                if recHeartbeat is True:
                    print("heartbeat pass!")
                    log.write("heartbeat pass\n")
                    recHeartbeat = False
                else:
                    #Disconnect Happened
                    print("heartbeat fail!")
                    log.write("heartbeat fail!\n")
                    heartbeatLive = False
                    #print("heartbeat close from fail")
                    #return
            time.sleep(9)
        print("heartbeat close from condition check")
        return
    
def hardwareRequest(request):
    global log, hardware, server 
    print("at start of hwrequest")
    print(request)
    if request == 0: #Weight request message
        print("HWThread: Weight Request Code: 1212 RX")
        weights = hardware.weightCode() #Get weight values from the hardware object
        server.send(str(weights[0])+","+str(weights[1])) #Format and pass weight values to the websocket

    elif request == 1: #Length request message
        print("HWThread: Length Request Code: 1212 RX")
        length = hardware.lengthCode() #Get length values from the hardware object
        server.send(length) #Pass weight values to the websocket

    elif request == 2:
        print("HWThread: MOI and Swing Request Code: 1212 RX")
        moi = hardware.moiCode() #Get MOI/Period values from the hardware object
        server.send(str(moi[0])+","+str(moi[1])) #Format and pass MOI/Period values to the websocket
    return

terminalThread = threading.Thread(target=asyncClose)
heartbeatThread = threading.Thread(target=heartbeatChecks)
hardwareThread = threading.Thread(target=hardwareRequest,args=(0,))
terminalThread.start()
heartbeatThread.start()

      
def receiveMessage():
    global server, recHeartbeat
    log.write("Waiting for Message\n")
    print("Waiting for Message")
    rx = server.receive()
    #rx = "10101212"
    log.write("Server received message:\n")
    print("RX message")
    print(rx)
    log.write(rx)
    if(len(rx) > 4):
        print("received a request longer than four characters. Checking for heartbeat and returning other")
        print(len(rx))
        if(len(rx) == 8):
            data1 = rx[0:4]
            data2 = rx[4:8]
            print(data1)
            print(data2)
            if data1 == "1010":
                recHeartbeat = True
                rx = data2
                print("heartbeat joined with:" + data2)
            elif data2 == "1010":
                recHeartbeat = True
                rx = data1
                print("heartbeat joined with:" + data1)
    return rx
    
#resetTests Function
#   This function will set all the initial variables (aside from the server variable) back to their original state for a new test to begin.
def resetTests():
    global joinThread, heartbeatLive, heartbeatThread, weight, length, moi, hardware, testingBegan
    print("Requesting Heartbeat Join")
    log.write("Requesting Heartbeat join\n")
    joinThread = True
    heartbeatThread.join()
    joinThread = False #stop the join so that a new thread created is not killed immediately
    print("resetting tests")
    log.write("Resetting Tests\n")
    weight = -1
    length = -1
    moi    = -1
    hardware = HardwareClass()
    testingBegan = False
    heartbeatLive = True #set heartbeat to live since we have a connection and also want to check for timing
    heartbeatThread = threading.Thread(target=heartbeatChecks) #find a place to close these at some point in final stages
    heartbeatThread.start()
    
def hardwareSetup():
    global hardware, server, errorMsg
    log.write("Hardware being initialized\n")
    print("hardware initializing")
    hardware = HardwareClass() #Open a new hardware object. We reopen here to ensure there is still a valid connection to the hardware.

    #If both parts of the hardware are connected, send the heartbeat message to the iOS device to indicate that the hardware is ready to progress.
    if hardware.gatesConnected() and hardware.scalesConnected():
        server.send("1010")

    else:
        #If one or both components are not connected or not found, send the error messages to the iOS device to inform the user.
        errorMsg = ""
        if not hardware.gatesConnected():
            print("Server has determined that the gates are not connected")
            #log.write("Server has determined that the gates are not connected\n")
            errorMsg += "6666,"

        if not hardware.scalesConnected():
            print("Server has determined that the scales are not connected")
            #log.write("Server has determined that the scales are not connected\n")
            errorMsg += "5555,"
        server.send(errorMsg)
    
#atexit.register(stop) 

print("Interfacing Init")
log.write("Server Start. Interfacing Init.")
while interfacing:
    log.flush()
    os.fsync(log.fileno())
    #print("Wait")
    if(not initializing and not heartbeatLive):
        print("triggering reset due to heartbeat failure")
        resetTests()
    message = receiveMessage()
    print("RX: " + message)
    #print("HBL set to true")
    initializing = False
    heartbeatLive = True
    if message == "1010":
        log.write("Heartbeat Code: 1010 RX")
        disconnPrint = False
        recHeartbeat = True
        server.send("1010")
        if not hardware.gatesConnected() or not hardware.scalesConnected():
            server.send(errorMsg)
    
    elif message == "0202": #Hardware setup message
        log.write("Hardware Setup Code: 0202 RX")
        hardwareSetup()
        #testingBegan = True

    elif message == "1212": #Weight request message
        print("RX 1212: hwthread start with 0")
        hardwareThread = threading.Thread(target=hardwareRequest,args=(0,))
        hardwareThread.start()

    elif message == "3434": #Length request message
        print("RX 3434: hwthread start with 1")
        hardwareThread = threading.Thread(target=hardwareRequest,args=(1,))
        hardwareThread.start()

    elif message == "5656":
        print("RX 5656: hwthread start with 2")
        hardwareThread = threading.Thread(target=hardwareRequest,args=(2,))
        hardwareThread.start()

    elif message == "0000":
        
        log.write("Quit Code: 0000 RX")
        server.stop()
        #server.reopen()
        
    elif message == "1111":
        print("timeout for message retreival, triggering resetTest, setting rechb to True, restarting server")
        resetTests()
        recHeartbeat = True
        server.stop()
        server.reopen()
    
    elif message == "9999":
        log.write("Disconnect Code: 9999 RX")
        resetTests()
        recHeartbeat = True
        server.stop()
        server.reopen()

    elif message == "":
        log.write("Weight Request Code: _ Blank RX")
        resetTests()
        recHeartbeat = True
        server.stop()
        server.reopen()
        if not disconnPrint:
            print("This is a temp debug. We likely disconnected.")
            #log.write("This is a temp debug. We likely disconnected\n")
            disconnPrint = True