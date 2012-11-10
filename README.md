AVR-Remote-Robot
================
OSU 

AVR Assembly program to control a robot from a remote control over IR

Remote control and robot that uses the USART Interfaces on an AVR ATMega128. USART1 is connected to an IR device that is used to transmit a botID followed by a command. The bot ID has a 7th bit of 0, while the command has a 7th bit of 1.
 
Remote.asm:
-----------
Polls the buttons until one is pressed, once pressed it sends the botID followed by the command corresponding to the button. 

Robot.asm:
----------
Recieves the signal from the remote. When it recieves a signal, checks against its botID. If the botID matches, sends command to the motors. Also has limited bumpbot capability: checks input from PORTD bumpers and back's up, turn's away from the bumper that was hit, then continue's moving forward.

TestTransmitter.asm:
--------------------
Practice using the transmitter and reciever. Transmits a signal, then uses the loopback feature to recieve the signal. When the it recieves the signal, it flashes the light 3 times.

TestReciever.asm:
-----------------
Practice recieving foreign signals. When it recieves any signals, it display's it using the LEDs on board. The last signal recieved will be displayed until a new signal is recieved.