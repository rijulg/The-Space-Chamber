#rem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Setting variables and properties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#endrem
setfreq M32
symbol mainSwitch = b1
symbol modeSwitch = b2
symbol realVout = b3
symbol desiredFrequency = b4
symbol noiseLevel = b5
symbol feedbackFlag = b6
symbol expectedVout = b7
symbol diffVout = b8
symbol differenceFrequency = b9
symbol finalFrequency = b10
symbol mode = b11
symbol motorSetFlag = b12
symbol frequencyMin = b13
symbol frequencyMax = b14

mode=0
frequencyMin = 170
frequencyMax = 230

main:

	readadc B.1,b1
	readadc B.2,b2

	#rem
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	If switch is off
	set motor pwm at 50% => motor is off
	continue loop
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	#endrem
	if mainSwitch<50 then
	hpwm 1,0,0,79,159
	mode=0
	goto main
	endif

	gosub modeController

	gosub motor

goto main

#rem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
modeController
used for setting the mode to run the device in desired mode
sets feedbackflag to enable/disable feedback loopback mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#endrem
modeController:
	if modeSwitch < 60 then
		if mode != 1 then
			sertxd("Mode 1",cr,lf)
			desiredFrequency = 221
			finalFrequency = desiredFrequency
			mode = 1
			feedbackFlag = 1
			motorSetFlag = 0
		endif
	else if modeSwitch < 130 then
		if mode != 2 then
			sertxd("Mode 2",cr,lf)
			desiredFrequency = 211
			finalFrequency = desiredFrequency
			mode = 2
			feedbackFlag = 1
			motorSetFlag = 0
		endif
	else if modeSwitch < 220 then
		if mode != 3 then
			sertxd("Mode 3",cr,lf)
			desiredFrequency = 201
			finalFrequency = desiredFrequency
			mode = 3
			feedbackFlag = 1
			motorSetFlag = 0
		endif
	else 
		if mode != 4 then
			sertxd("Mode 4",cr,lf)
			finalFrequency = 80
			gosub motor
			pause 1000
			desiredFrequency = 120
			finalFrequency = desiredFrequency
			mode = 4
			feedbackFlag = 0
			motorSetFlag = 0
		endif
	endif
	
return

#rem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
motor
runs the motor at desired frequency
ensures speed if feedbackflag is set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#endrem
motor:
	
	if motorSetFlag = 0 then
		sertxd("final frequency for motor is ",finalFrequency,cr,lf)
		hpwm 1,0,0,79,finalFrequency
		motorSetFlag = 1
		if feedbackFlag=1 then
				gosub feedback
				motorSetFlag = 0
		endif
	endif
return


#rem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
feedback
makes sure that the motor is running
at desired speed within noise level
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#endrem
feedback:

	readadc B.3,b3
	
	noiseLevel = 3
	
	if mode = 1 then
		expectedVout = 20
	else if mode = 2 then
		expectedVout = 18
	else
		expectedVout = 15
	endif
		
	
	sertxd("realVout is ",realVout,cr,lf)
	
	
	if realVout > expectedVout then
		diffVout = realVout - expectedVout
		
		sertxd("diffVout is ",diffVout,cr,lf)
		if diffVout < noiseLevel then
			return
		else
			differenceFrequency = 100 * diffVout
			differenceFrequency = differenceFrequency / 24
			finalFrequency = finalFrequency - differenceFrequency
			if finalFrequency < frequencyMin then
				finalFrequency = frequencyMin
			endif
		endif
	else	
		sertxd("Diff vout is negative",cr,lf)
		diffVout = expectedVout - realVout
		sertxd("diffVout is ",diffVout,cr,lf)
		if diffVout < noiseLevel then
			return
		else
			differenceFrequency = 100 * diffVout
			differenceFrequency = differenceFrequency / 24
			finalFrequency = finalFrequency + differenceFrequency
			if finalFrequency > frequencyMax then
				finalFrequency = frequencyMax
			endif
		endif
	endif

	sertxd("desired frequency is ",desiredFrequency,cr,lf)
	sertxd("diffFrequency is ",differenceFrequency,cr,lf)
	sertxd("final frequency is ",finalFrequency,cr,lf)
	
return
