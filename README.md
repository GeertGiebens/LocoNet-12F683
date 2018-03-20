# LocoNet-12F683

!!! My native language is not English. I hope I made the explanation how it work clear enough. !!!

This device is a simple LocoNet receiver. It responds to one LocoNet address by opcode OPC_SW_REQ.  This device has three outputs. With two outputs you can control a relais board to switch turnouts. With one output you can switch a LED (or two LED’s). Other applications are also possible.

The hardware and software can only listen to LocoNet data.  This means that this device can not report anything on the net. In principle, this is not necessary, if the job is always executed.

We can then greatly simplify the device. A small PIC µC is sufficient. We also use the internal comparator of the µC. A PIC 12F683 µC, some resistors,  capacitor and connectors is all you need. See figure:

<img alt="open opps 1" src=https://github.com/GeertGiebens/LocoNet-12F683/blob/master/LocoNet%20OUT%20with%20PIC%2012F683%20%C2%B5C.png>

 

What you need to know about this device:

- You can program a new address by temporarily placing a bridge at the specified location, and send the opcode with a new address.

- The device stores every change in the EEPROM. If the power supply is switched on the LED output assume the last position.

- The PCB can easily be reproduced yourself. As an example see photos:



Other projects:

-[LocoNet IO](https://github.com/GeertGiebens/LocoNet_IO) (Under construction)
