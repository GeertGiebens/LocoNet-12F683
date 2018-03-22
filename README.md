# LocoNet-12F683

(Under construction 22/mrt/2018)

!!! My native language is not English. I hope I made the explanation how it work clear enough. !!!

This device is a simple LocoNet receiver. It responds to one LocoNet address by opcode OPC_SW_REQ.  This device has three outputs. With two outputs you can control a relais board to switch turnouts. With one output you can switch a LED (or two LED’s). Other applications are also possible.

The hardware and software can only listen to LocoNet data.  This means that this device can not report anything on the net. In principle, this is not necessary, if the job is always executed.

We can then greatly simplify the device. A small PIC µC is sufficient. We also use the internal comparator of the µC. A PIC 12F683 µC, some resistors,  capacitor and connectors is all you need. See figure:

<img alt="open opps 1" src=https://github.com/GeertGiebens/LocoNet-12F683/blob/master/LocoNet%20OUT%20with%20PIC%2012F683%20%C2%B5C.png>

 

### What you need to know about this device:

- You can program a new address by temporarily placing a bridge at the specified location, and send the opcode with a new address.

- The device stores every change in the EEPROM. If the power supply is switched on the LED output assume the last position.

- The PCB can easily be reproduced yourself. As an example see photos:

- Important to know! There is a choice between how outputs  OUT2 and OUT3 react. Each output will be switched off by the corresponding LocoNet opcode (SW2:DIR=’1’or’0’ and ON=’0’). But there is a possibility that the device itself switches off the output after a time = 260ms. You can set this in the following way: If you set a new address, the device will look at the last received opcode before you removing the programming bridge. Is in opcode SW2:ON='1' then the device itself will switch off the output. This is for personal reasons (some devices do not send an opcode where SW2:ON=’0’). Actually, it is safer to use this option, because if the opcode for switching off does not arrive, the output will not switch off!


### How does the device react to the LocoNet opcode OPC_SW_REQ :

OPC_SW_REQ :OPCODE: REQ SWITCH function: 0xB0,SW1,SW2,CHK
- SW1 =0,A6,A5,A4- A3,A2,A1,A0
- SW2 =0,0,DIR,ON- A10,A9,A8,A7
- where ON='1'  for Output ON, ='0' FOR output OFF.
- where DIR='1' for Closed,/GREEN, ='0' for Thrown/RED.
         
 
 Device outputs OUT1, OUT2 and OUT3:
 
- SW2: DIR='1' AND ON='1' --> OUT1= GND
- SW2: DIR='0' AND ON='1' --> OUT1= +5V


- SW2: DIR='1' AND ON='1' --> OUT2= GND (active)  if option: OUTPUT_OFF_260ms='1' then OUT2 --> +5V after 260ms
- SW2: DIR='1' AND ON='0' --> OUT2= +5V
- SW2: DIR='0' AND ON='1' --> OUT3= GND (active)  if option: OUTPUT_OFF_260ms='1' then OUT3 --> +5V after 260ms
- SW2: DIR='0' AND ON='0' --> OUT3= +5V




### Other projects:

-[LocoNet IO](https://github.com/GeertGiebens/LocoNet_IO) (Under construction)
