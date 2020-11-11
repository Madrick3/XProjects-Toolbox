# -*- coding: utf-8 -*-
"""
This program is run on the Raspberry Pi to control the MOI test rig.
A command is sent to the Feather to trigger it to do a task (either run the swing period test or retrieve
the bat length) or the code retrieves bat weights from the scales.
Once done, the Raspberry continues looping and waiting for another instruction.
"""

#Necessary Imports
import serial, time
from re import sub

class HardwareClass:
    #Initial Variable Setup
    scaleConnected = True
    gateConnected = True
    ser_arduino = serial.Serial()#Open port with baud rate 9600
    ser_scale_1 = serial.Serial()
    ser_scale_2 = serial.Serial()
 
    #weightCode Function
    #   This function receives the weight values from the scales through serial connection and returns them.
    #   
    #   Params:
    #       self (HardwareClass): neccessary param for functions in a class
    #
    #   Returns:
    #       float[]: [Weight from scale 1, Weight from scale 2]
    def weightCode(self): 
        print("Retrieving bat weights...")
        if self.scaleConnected:
            print("")
            # The scale prints two lines when Print is pressed.  The result looks something like: "4.075 oz"
            # The first line always has the weight reading and the second line is always blank

            data = self.ser_scale_1.readline() # capture the string from the first line\
            junk = self.ser_scale_1.readline() # trash the second line
            weight_1 = float(sub(r'[^\d.]', '', data.decode())) # this pulls only the
            #numbers out of the string read from the scale. The string is encoded as a byte value, so the number is
            #pulled from it and convered to a float.  Therefore if the scale sends b'3.030 oz' we get the 3.030.  

            print("    weight 1 = ", weight_1, " oz")
            print("")

            # repeat for the second scale
            scale_reading = self.ser_scale_2.readline()  # capture the string from the first line\
            junk = self.ser_scale_2.readline() # trash the second line
            weight_2 = float(sub(r'[^\d.]', '', scale_reading.decode()))

            return [weight_1, weight_2]
        else:
            return [0,0]
            
    #moiCode Function
    #   This function receives the MOI/period values from the arduino through serial connection and returns them.
    #   
    #   Params:
    #       self (HardwareClass): neccessary param for functions in a class
    #
    #   Returns:
    #       float[]: [period, standard deviation]
    def moiCode(self):
        print("Running swing period timer...")
        print("")
        self.ser_arduino.write(str('p')) # 'p' = period Send 'g' as Go signal to Arduino.  Any other character is ignored.
        data = self.ser_arduino.readline() ## we now wait for the arduino to return the value of the period, which it will do after 15 swings.
        #print(data)
        period = float(sub(r'[^\d.]', '', data.decode()))
        print("    Period = ", period, " seconds")
        print("")
        data = self.ser_arduino.readline() ## we now wait for the arduino to return the value of the standard deviation of swings
        stdev = float(sub(r'[^\d.]', '', data.decode()))
        print("    Standard deviation = ", stdev, " seconds")#print(period)
        print("")
        return [period, stdev]
    
    #lengthCode Function
    #   This function receives the length values from the arduino through serial connection and returns them.
    #   
    #   Params:
    #       self (HardwareClass): neccessary param for functions in a class
    #
    #   Returns:
    #       float: length of the bat
    def lengthCode(self): 
        print("Measuring bat length...")
        print("ser_arduino: ")
        print(self.ser_arduino)
        self.ser_arduino.write(str('l')) # 'l' = length as Go signal to Arduino.
        data = self.ser_arduino.readline() ## we now wait for the arduino to return the value of the length
        #print(data)
        length = float(sub(r'[^\d.]', '', data.decode()))
        print("    Bat length = ", length, " inches")
        print("")
        return length
    
    #close Function
    #   This function closes the serial connections.
    def close():
        print("closing serial com ports")
        self.ser_arduino.close()
        self.ser_scale_1.close()
        self.ser_scale_2.close()
    
    #scalesConnected Function
    #   This function indicates if there is an open connection to the scales.
    #   
    #   Params:
    #       self (HardwareClass): neccessary param for functions in a class
    #
    #   Returns:
    #       bool: True if scaleConnected is True, False otherwise
    def scalesConnected(self):
        return self.scaleConnected
    
    #gatesConnected Function
    #   This function indicates if there is an open connection to the arduino.
    #   
    #   Params:
    #       self (HardwareClass): neccessary param for functions in a class
    #
    #   Returns:
    #       bool: True if gateConnected is True, False otherwise
    def gatesConnected(self):
        return self.gateConnected
    

    #init Function
    #   This function initializes the serial connections to prepare for testing.
    #   
    #   Params:
    #       self (HardwareClass): neccessary param for functions in a class
    #
    def __init__(self):
        # Establish serial communication with the Feather that runs the swing timer and the bat lentgh sensor (must try all the combinations of possible ones with an RPI3)
        self.ser_arduino = serial.Serial()
        try:
            print("Checking ACMI1")
            self.ser_arduino = serial.Serial('/dev/ttyACM0', 9600)    #Open port with baud rate 9600
            print(self.ser_arduino)
        except Exception, e:
            print e
            try:
                print("Checking ACM1")
                self.ser_arduino = serial.Serial('/dev/ttyACM1', 9600)    #Open port with baud rate 9600
                print(ser_arduino)
            except:
                try:
                    print("Checking ACM2")
                    self.ser_arduino = serial.Serial('/dev/ttyACM2', 9600)    #Open port with baud rate 9600
                    print(ser_arduino)
                except:
                        try:
                            print("Checking AMA0")
                            self.ser_arduino = serial.Serial('/dev/ttyAMA0', 9600)    #Open port with baud rate 9600
                            print(ser_arduino)
                        except:
                            print("Looks like the arduino is not plugged into the Raspberry Pi")
                            self.gateConnected = False
                
        # Establish serial communication with the scales (must try all the combinations of possible ones with an RPI3)
        try:
            self.ser_scale_1 = serial.Serial('/dev/ttyUSB0',9600)
            self.ser_scale_2 = serial.Serial('/dev/ttyUSB1',9600)
        except:
            try:
                self.ser_scale_1 = serial.Serial('/dev/ttyUSB1',9600)
                self.ser_scale_2 = serial.Serial('/dev/ttyUSB2',9600)
            except:
                try:
                    self.ser_scale_1 = serial.Serial('/dev/ttyUSB0',9600)
                    self.ser_scale_2 = serial.Serial('/dev/ttyUSB2',9600)
                except:
                    try:
                        self.ser_scale_1 = serial.Serial('/dev/ttyUSB0',9600)
                        self.ser_scale_2 = serial.Serial('/dev/ttyUSB3',9600)
                    except:
                        try:
                            self.ser_scale_1 = serial.Serial('/dev/ttyUSB1',9600)
                            self.ser_scale_2 = serial.Serial('/dev/ttyUSB3',9600)
                        except:
                            try:
                                self.ser_scale_1 = serial.Serial('/dev/ttyUSB2',9600)
                                self.ser_scale_2 = serial.Serial('/dev/ttyUSB3',9600)
                            except:
                                print("Looks like one or both scales is/are not plugged into the Raspberry Pi")
                                self.scaleConnected = False
                
        time.sleep(1) # Add a delay after opening serial port with Arduino because this action 
        # resets the Arduino and causes it to miss characters if sent too soon
