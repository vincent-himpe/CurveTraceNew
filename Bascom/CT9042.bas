'------------------------------------------------------------------
'                    (c) 1995-2023 MCS
'                      TWI1-PCF8574A.bas
'purpose : test PCF8574A I2C chip with TWI1 interface
'Micro: 128db64
'------------------------------------------------------------------
$regfile = "mx4809.dat"                                ' the used chip
$crystal = 20000000                                         ' frequency used
$hwstack = 40
$swstack = 40
$framesize = 40


Dim LeftMarker as word
dim RightMarker as word
DECLARE SUB MarkerHandler()


Declare sub KeyHandler()


dim cooked as word
dim cookedstring as string * 6

DIM X AS Integer
DIM Y AS INTEGER
DIM ADCRESULTS(3) AS INTEGER

DIM ADCSTRING AS STRING * 4
Dim ADCLength As Byte
Dim ADCSpaces As Byte



$SIM

'----------------------------------------------
' CORE configuration
'----------------------------------------------

'Select oscillator and frequency
  Config Osc = Enabled ', Frequency = 20mhz

' Configure TCA timer
  config TCA0=normal, prescale=8, run=off, lupd=manual, compare0=disabled,compare1=disabled,compare2=disabled,cmp0_int = enabled,cmp1_int=enabled


'----------------------------------------------
' I/O port configuration
'----------------------------------------------

' DAC control port
'----------------------------------------------
  config PORTC = output
  config xpin = portc, pullup = pullup

' Input bank
'----------------------------------------------
' bank layout :
' PB0 : KEYINTB
' PB1 : KEYINTA
' PB2 : Sweepstart
' PB3 : ROTKEY
' PB4 : ROTPHA
' PB5 : ROTPHB
  config PORTB = input
  config xpin = PORTB, pullup = pullup
  KEYINTA ALIAS PORTB.0
  KEYINTB ALIAS PORTB.1
  SWEEPSTART ALIAS PORTB.2
  ROTKEY ALIAS PORTB.3
  ROTPHA ALIAS PORTB.4
  ROTPHB ALIAS PORTB.5

' Output Bank
'----------------------------------------------
' bank layout :
' PE0 : KEEPON
' PE1 : MARKER
' PE2 : MARKERENABLE
  config PORTE = output
  config xpin = porte, pullup=pullup



' SET UP LCD
'----------------------------------------------
' PortF is used for the LCD
' see if we can use the lcd4 library...

  CONFIG LCDPIN = PIN, DB4 = PORTF.0, DB5 = PORTF.1 , DB6 = PORTF.2, DB7 = PORTF.3, E= PORTF.4 , RS = PORTF.6
  config LCD = 40x2
  CURSOR OFF NOBLINK
  CLS
  HOME UPPER

' SET UP ADC
CONFIG ADC0 = SINGLE, RUNMODE=ENABLED, RESOLUTION = 10BIT,ADC=ENABLED,SAMPLE_ACCU=0,SAMPLE_CAP=ABOVE_1V,REFERENCE=INTERNAL
CONFIG VREF=DUMMY, ADC0= 2V5

'----------------------------------------------
'SET UP INTERRUPTS
'----------------------------------------------

' TIMER interrupts :

ON TCA0_CMP0 MarkerHandler nosave  ' compare0 handler
ON TCA0_CMP1 MarkerHandler nosave  ' compare1 handler (the same)

'ON  ADC0_RDY ADCREAD() NOSAVE

config LCD = 40x2
CURSOR OFF NOBLINK
CLS
HOME UPPER
LCD "CT9084 Curve Tracer"
LOWERLINE
LCD "V0.0 -ALPHA- . Initializing"




Do

  Y = GETADC(0)
  cooked = 0
  cooked = y
  cooked = cooked * 4
  LOCATE 1,30
  LCD format(cookedstring," 0.00")
  LOCATE 2,30
  'cooked = cooked \10
  cookedstring = str(cooked)
  LCD format(cookedstring,"0.000")


  Waitms 1
  X = X + 1
Loop
END


SUB MarkerHandler()
 porta.1 = 1
 !NOP
 !NOP
 !NOP
 !NOP
 !NOP
 !NOP
 porta.2 = 1
 !NOP
 !NOP
 !NOP
 !NOP
 !NOP
 !NOP
 porta.1=0
 porta.2=0
end sub

sub KeyHandler()
end sub