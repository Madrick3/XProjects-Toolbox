#Websocket Server
#
#   Websocket server that can send and receive data to and from an iOS app with the appropriate code over WiFi.
#   
#   Below are the important messages sent or received by the websocket:
#       "1010" - Heartbeat Message - Send as opposed to 6666 or 5555 if everything is setup in hardware correctly
#       "0000" - Quit Message
#       "0202" - Begin Testing
#       "1212" - Instructions Completed - Denotes that everything should have been setup by the user
#       "9999" - Quit Tests
#       "8888" - initial connection code
#       "6666" - Gate not connected
#       "5555" - One or more scales missing

#Necessary Imports: Socket for websocket functionality, AtExit for clean closing of the processes
import socket, atexit

class WebsocketServerClass:
    global c #Global client (device connection) variable
    
    #init Function
    #   This function opens a new connection with a device. This will hang until a device is connected.
    #
    #   Returns:
    #       bool: True if the WebsocketServer recieves the message "0202", Fa
    def __init__(self):
        #Begin Initial Setup
        self.reopen()
        atexit.register(self.stop)
        #Done with initial Setup

    #send Function
    #   This function send the string to the connected device
    #   
    #   Params:
    #       self (WebsocketServerClass): neccessary param for functions in a class
    #       string (str): the string being sent to the device by the function
    def send(self, string):
        c.send(str(string))
        print("sent:",str(string))

    #receive Function
    #   This function receives a message from the connected device. This function will hang in the websocket until it receives a message.
    #   
    #   Params:
    #       self (WebsocketServerClass): neccessary param for functions in a class
    #   
    #   Returns:
    #       str: string received by the websocket from the connected device
    def receive(self):
        print("waiting for message")
        data = c.recv(1024) #Receive the message (up to 1024 bytes)
        data.replace("\r\n","") #Replace newlines because the above line will fill the empty space at the end of the message with these occassionaly
        print("got message: " + data)
        return data

    #stop Function
    #   This function stops the websocket and closes the connections to the device.
    #   
    #   Params:
    #       self (WebsocketServerClass): neccessary param for functions in a class
    def stop(self):
        #c.send("0000")
        print("Quitting server")
        c.close()
        s.close()
        isOpen = False
    
    #isOpen Function
    #   This function returns if there is an open connection to a device
    #   
    #   Params:
    #       self (WebsocketServerClass): neccessary param for functions in a class
    #
    #   Returns:
    #       bool: True if isOpen is True, False otherwise
    def isOpen(self):
        return isOpen
    
    #reopen Function
    #   This function opens a new connection to a device. This should not be run if a device is already connected. This function will hang in the websocket connects to a device.
    #   
    #   Params:
    #       string (str): the string being sent to the device by the function
    def reopen(self):
        isOpen = False
        
        s = socket.socket()
        host = socket.gethostbyname(socket.getfqdn())
        port = 9876
        
        if host == "127.0.1.1":
            import commands
            host = commands.getoutput("hostname -I")
        print("host =", host[0:-1])
        
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((host[0:-1],port))
        
        s.listen(5)
        global c
        c, addr = s.accept() #This is the line that attempts to find and connect to a device. This is also the line that will hang until a connection is established.
        
        print("Accepted Client: ", c)
        
        isOpen = True


