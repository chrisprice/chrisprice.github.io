
bit-web-bluetooth


**Even if you are running the default firmware or ultimately want to run your own firmware, follow this step!** Flashing the default firmware via USB has a [number of ~confusing and cryptic~ interesting and useful side-effects](#why-was-the-first-step-to-flash-the-default-firmware-onto-the-microbit-via-usb). Don't worry, we'll come back to running your own custom firmware once we've got a working connection.

First up, we're going to flash the default firmware onto the micro:bit via USB. Download the [default firmware](https://lancaster-university.github.io/microbit-docs/resources/BBC_MICROBIT_OOB_FINAL.zip) and unzip it. Connect your micro:bit via USB, find the mounted drive and drag the `BBC_MICROBIT_OOB_FINAL.hex` onto it. After restarting, your micro:bit screen should be alternating between a `←` and an `A`

*To be on the safe side, if you've ever tried to connect to the micro:bit from the device you're running the browser on, you should additionally clear any saved bluetooth pairing information for the micro:bit. I've also found it doesn't hurt to restart your browser once you've cleared the pairing information. If you've never tried to connect before, you can safely skip this.*

Now, if you go to the Device Information service example and click connect you should be presented with a popup listing local BLE devices advertising with a prefix of `BBC micro:bit`.

Great, so it's working?

## It doesn't work

Assuming the only micro:bit in range is the one you flashed in the previous step, you may be surprised that there isn't anything listed...

The problem is that in order for a device to be listed it must be advertising its availability and either be generally discoverable or previously paired. In our case (a micro:bit configured for `Just Works` pairing with an empty list of paired devices), not only is is not generally discoverable, [it isn't even advertising](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L422).

We can rectify this by reseting the micro:bit into Pairing Mode. This is done by holding down the A + B buttons, pressing the reset button and then releasing A + B when the screen [starts scrolling](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L676) ["Pairing Mode!"](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L644). The screen will then [show a histogram](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L678) of the micro:bit's device ID until either pairing [completes successfully](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L737) or [times out](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L763).

Whilst showing "Pairing Mode!" or the histogram, the micro:bit is advertising and generally discoverable. That means if you go back to the device information example and click connect, you should find your micro:bit listed as `BBC micro:bit [xxxx]` (where `xxxx` is the device name). Connect to it and the example should then interogate the Device Information service (`0000180A00001000800000805F9B34FB`), retrieve the Model Number characteristic (`00002A2400001000800000805F9B34FB`) then display it ([it should be `BBC micro:bit`](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L76)).

Great, so **now** it's working?

## It still doesn't work

If you were to reset the device now (or even just wait for the Pairing Mode timeout), go to the Device Information service example and click connect you would be presented with an empty list again...

This time the problem is that we didn't actually pair with the micro:bit, all we did is enter Pairing Mode and then leave it. Outside of Pairing Mode, the micro:bit has reverted to its previous behaviour of not even bothering to advertise itself. So how do we trigger pairing?

Pairing is only triggered when interogating a **secure** characteristic. Previously we requested the Model Number characteristic from the Device Information service which is not a secure characteristic, therefore pairing was not required and didn't happen. Let's try it again with a secure characteristic.

As before, enter Pairing Mode with the A/B/reset button dance. This time thought, instead of opening the Device Information service example, open the Event Service example and click connect. You should again see your micro:bit device `BBC micro:bit [xxxx]` in the list, connect to it and the example should integrogate the Event Serice (`E95D93AF251D470AA062FA1922DFA9A8`), retrieve the **secure** MicroBit Requirements characteristic then display its count (it should be 0).

If you look at the micro:bit screen you should see a [tick appear for 15 seconds](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L734) to indicate pairing was successful. Then the micro:bit will then reset out of Pairing Mode (you can also press the reset button if you're impatient).

Once the micro:bit has reset (i.e. it is not in Pairing Mode), you should now finally be able to open the Button Service example, click connect, connect to the listed micro:bit and see the state of Button A (n.b. the example is incredibly simplistic and will only update if you reconnect). You're now successfully connected to the micro:bit using Web Bluetooth and [all of the services should be available](https://lancaster-university.github.io/microbit-docs/ble/profile/#gatt-services) for you to experiment with!

*You may have noticed that the micro:bit [no longer has a device name suffix](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L299) (`[xxxx]`). This is a useful hint as to whether the device is in Pairing Mode or not although can not be fully relied upon becuase [its behaviour can change depending upon the configured pairing type](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L302).*

## Using custom firmware

*Don't skip straight to this section, be sure to follow through the instructions above or things will break and you won't understand why!* It'll be infuriating, you'll blame the micro:bit, your dumb computer, your outdated phone, etc.. Then you'll start questioning if gravity really works the way you thought it did, before abandoning all hope and turning to alcohol. Trust me, that's what I did...

Using your own firmware is essentially the same but it's worth noting the following -

* Bluetooth and most services need to be [explicitly enabled](#how-to-fully-enable-bluetooth-in-makecode).
* The pairing behaviour depends upon the [configured pairing type]((#is-there-an-easier-way).
* Flashing via USB [clears the pairing information](#it-was-working-and-now-its-stopped-what-did-i-do)

## Now onto the fun stuff

I'd assumed that by now I'd be done with this little side project, rather than celebrating a solitary bluetooth connection. It's not been a waste of time though, along the way I've picked up quite a bit of useful bluetooth terminology and delved quite a bit deeper into the micro:bit firmware.

Upon reflection, despite the various documentation articles I found online, the [firmware source code](https://github.com/lancaster-university/microbit-dal/blob/e0f8b005fe628552ab060a8f4cbbd1037bf3b8bb/source/bluetooth/MicroBitBLEManager.cpp#L302) was the (unsurpringly perhaps!) best description of the confusing behaviour I was seeing. However, trawling through c++ code isn't for everyone so I started thinking about how things could be designed differently to make them a little more intuitive.

All of my problems could obviously be solved by removing the requirement to pair with the micro:bit in order to interact with the secure services. This idea certainly wins on usability but falls quite a long way short on security for anything other than toy projects. I also don't think it's the right kind of lesson to be teaching the next generation of software developers, the current generation seem to have a hard enough time wrapping their heads around security!

This makes me start to question the whole concept of a firmare-level pairing mode. Whilst it does guarantee a bullet-proof pairing process, it does so in a very jarring way by completely hijacking control of the device from the developer. Relating it back to teaching the next generation of software developers, it reminds me of the security is someone else's problem mindset, rather than the responsibility of all.

I should caviat the following by saying I'm not sure if it would be technically possible (e.g. there may be some extreme resource contraints during pairing?). However, I think a more developer friendly approach could be to expose the pairing primitives as blocks such as -

* `set pairing type {none,simple,passkey}` - the pairing type (currently hidden in configuration)
* `start advertising to {everyone,only paired devices}` / `stop advertising` - enable or disabled advertising
* `on bluetooth pairing required` - a callback to run code when a secure service is accessed by an unpaired device (only applicable to certain pairing types)
* `on bluetooth [passkey] required` - a callback to run code when the pairing process requires the passkey to be communicated to the user (only applicable to certain pairing types)

This approach would mean that developers would have to consider how to secure their device. Whilst this might be slightly less intuitive, I believe an example program would be easily relatable and extendable. It allows the developer freedom and creativity in how they communicate bluetooth states and, for passkey pairing, the passcode to users. Combined with the blocks for enabling the optional services, it also allows for a consistent presentation of services rather than a unmodifiable Pairing Mode set.

One thing I haven't considered as it's not something supported by MakeCode yet, is programming via bluetooth. In such a mode I can see why a last-resort Pairing Mode would be appropriate to provide a backdoor into the device when required (e.g. a user communicates the incorrect passcode). 

### FAQ

#### Why was the first step to flash the default firmware onto the micro:bit via USB?

Good question! Unfortunately there are a number of issues, each of which can cause communication problems. We needed to ensure -

* Bluetooth was enabled.
  * The default firmware enables bluetooth. Custom firmware often does not e.g. [MakeCode](https://makecode.microbit.org/) does not include the bluetooth package by default.

* All bluetooth services were enabled.
  * The default firmware's bluetooth profile contains all of the built-in services. Custom firmware often only contains a subset of these services e.g. [MakeCode](https://makecode.microbit.org/) only enables 3 services by default: Device Information Service, Event Service and DFU Control Service.

* Paired device information was in a known state.
  * Flashing via USB clears all paired device information from the micro:bit. Mismatched pairing information can cause hard to debug issues. Additionally, there's a hard limit of 4 paired devices.

* It was possible to enter Pairing Mode.
  * Whilst more typically symptomatic of bluetooth not being enabled, it is possible to disable this independently.

* `Just Works` Pairing was enabled.
  * As there are three different pairing types available, this makes for simpler instructions. See [Is there an easier way?](#is-there-an-easier-way) for a description of the other modes.

#### Is there an easier way?

Kind of. There are 3 different pairing types, each with their own advantages -

* `Just Works` Pairing
  * This is the mode used by the default firmware and its use is covered by the instructions above.
* Passkey Pairing
  * Similar to the above, the micro:bit screen shows a passcode which you must enter on the connecting device. This prevents a [MITM attack](https://en.wikipedia.org/wiki/Man-in-the-middle_attack) but is probably unnecessary for hobby projects.
* No Pairing
  * During development you can disable the need to pair the devices at all. This can save time if you're repeatedly flashing the micro:bit with new firmware (no need to re-pair) but leaves the device open for anyone to connect to. This risk is mitigated when developing as it's likely you'll be restarting frequently which will terminate the one permitted active connection.

You can change between these modes via Project Settings in MakeCode or [the project's config JSON file](https://lancaster-university.github.io/microbit-docs/ble/profile/#bluetooth-security).

#### How to enable bluetooth and all services in MakeCode?

By default [MakeCode](https://makecode.microbit.org/) projects do not include the bluetooth package. Add the "bluetooth" package (Blocks -> Advanced -> Add Package) to enable bluetooth (and Pairing Mode). Then ensure that in an `on start` block you add any `bluetooth xxx service`s you want to interact with (the following are included by default: Device Information Service, Event Service and DFU Control Service).

#### It was working and now it's stopped - what did I do?!

If you've not previously followed the above instructions, the first thing you should do is work through them. They'll walk you through getting a working connection, as well as explaining what's happening behind the scenes which should explain some of the really odd behaviour you can witness.

If you have previously worked through the instructions, then the most likely cause is re-flashing the micro:bit via USB has cleared the pairing information. Re-pairing as described above should fix the problem. If you find this is happening a lot, you could [temporarily disable the need for pairing](#is-there-an-easier-way).


