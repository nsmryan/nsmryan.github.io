+++
title = "Notes On Radiation Tolerance of Stored Data"
[taxonomies]
categories = ["Flight Software"]
+++
This post is just a couple of thoughts on detection and correction of corruption in stored data. This applies to
any data, but I'm talking from the perspective of space systems which experience occasional corruption in any onboard
storage device (Flash, RAM, EEPROM). There are a lot of ways to deal with this, and I just wanted to put down some
experience and some different designs I've seen over time as a way to share knowledge.


The general concern of radiation is a much broader topic, and this post is only about what we can do in software to
address corruption in our data. Some techniques require hardware support, and of course part selection is a vital aspect
of creating a tolerant system. On top of the hardware, we can do a number of things in software to get the final level
of protection. 

# The Setup
The reason that we need to think about corruption from radiation for space system is that any data we store may become corrupt.
This includes anything in RAM, and stored files such as software images or configuration files, or data in a storage device.
If your software is corrupt the system can become inoperable if it is unable to boot up, and if RAM is corrupt it can 
have unexpected consequences on operation which are immpossible to predict (likely causing software crashes).


In this environment we have to ensure that our data is protected, and often we end up using different protections for each type of
data due to differences in the devices or the criticality of the data. It is therefore important to understand some options when designing
a system for space, which is what this post is about- we will go over a few options to consider.


# Assumptions
For our detection and correction of data corruption we have to make a few assumptions. If these are violated then these techniques will
degrade in effectiveness or simply not work.


One assumption is that corruption occurs infrequently. If your data is corrupting constantly all over the place you need some serious protection,
but in my experience we are talking on the order of minutes, hours, or days between radiation hits that cause corruption depending on the system,
the memory device, and the orbit. I've never done extra-planetary missions where the radiation is much higher then, say, the ISS orbit so they
may be doing more extensive protection then I will discuss here.


Another assumption is that radiation is essentially random- it is unlikely for a single device to be hit in the same place more then once. This
assumption may be somewhat violated as a device degrades and becomes more sensitive. However, in general if a single bit is corrupt, it does not
seem likely for nearly bits to be necessarily corrupt.


The last assumption we will make is that the corruption occurs in memory devices liek flash, RAM, or EEPROM, but not in other devices. We need
hardware mechanisms to prevent, for example, our processor registers from becoming corrupt. This can be done, either through design, redundancy,
or choice of components to reduce sensitivity to radiation, but I'm no expert in that kind of thing and won't talk about it here.


# Techniques for Detection and Correction of Radiation Corruption
## Scrubbing
Corruption is something that accumulates over time, so a system must check periodically in case it has been getting data corruption.
The more corruption is present the harder it is to fix, so its important to check all memory devices at fixed intervels. This can be done around the
order of minutes- every 10 minutes or every hour is not uncommon.


Nearly every system has some scrubbing, whether is it done automatically or by command. There can also be a mixture where some devices are scrubbed
automatically while others are checked infrequently or even checked manually by downlinking their data and checking it on the ground.


Errors are detected on reads when the detection is done in hardware, so often a scrubber is just a low priority task that reads from certain memory
ranges corresponding to each device that requires protection. If an error occurs, we get a notification and we can correct it- say a corruption in
RAM that triggers an interrupt with a register giving the location and corrected value to write back to RAM.


Make sure to report when errors have to be corrected. This is the kind of information we can track on the ground and start to determine if a
particular location is failing more often then others for trending purposes. In some cases we can start to avoid that location if it exceeds a 
certain error rate. The one pitfall here is to make sure to limit the number of errors you report- there are a lot of locations in a memory device
and you don't want to report thousands of errors in some kind of anamolous case where every location is in error.

## CRC
One way to detect errors is to store a CRC along with your data. This is especially useful for data that changes infrequently like software images
or configuration files. A CRC is the result of a calculation which can be performed on the data (say, on the ground and uploaded with the data),
which can then we reperformed and compared against the stored result to see if we get the same result. Its like a stronger form of checksum.


A CRC can only help with detection, but in general it is very good at this. A single bit corruption in a software image is very likely to be
detected, the CRC only takes up a small amount of storage (4 bytes for a CRC32), and the calculation, while not exactly the fastest, is not
a problem if performed relatively infrequently.


One quick note- its generally better to not implement a CRC algorithm yourself. Its better to take an implementation that you know is correct and
not risk a mistake- its just not worth the risk and development cost.


## Redundant Copies
The easiest way to detect corruption is to store redundant copies of your data. With two copies you can detect corruption but do not necessarily
know which copy is correct, while with three copies you can "vote" and use the version of the data that occurs the most frequently.

It is always possible to have two images corrupt, but it is very unlikely. This is especially true because you can vote the data on a byte or
even bit level and the likelyhood of two bits being corrupt in the same location in two copies is extrememly low. This is especially true when
the hardware is designed with multiple storage devices, such as three identical RAM chips, each of which is offset in space from the others so
that radiation should not hit them in the same way.


One consideration when storing multiple copies of something is adding a CRC along with these copies. This allows a couple of additional protections
to be put into place- when voting we can check CRCs and determine if any copy is prestine, and after voting we can check the CRC and determine
if the resulting image is correct. This final point is important in case we have to correct multiple locations- we don't want to reconstruct an
image with corruption and assume it is correct.


Of course, the CRC can itself become corrupt. However, if the CRC is stored redundantly then we have a very high chance of being able to vote these
and get the correct CRC. If we can't, we don't need to store a CRC for our CRCs or anything like that- if the CRC check fails we just have to recognize
that this indicates either corruption in our data or in our CRC and that we don't know which is corrupt, which is generally true with this kind of
check.


There is an obvious tradeoff when storing data redundantly, which is that we need more storage and software complexity to manage it all. This can
increase hardware cost, and in some cases cannot be accomidated. This is especially true in storing your software images in a flash device with a
small, fixed capacity. I've seen several systems use two redundant flash devices, and store two copies of the software in each, resulting in a 
total of four images.


Redundancy can take different forms depending on the data dn device- if we want executing code to be stored redundantly we might need multiple entire
processor, if we want to store software images redunantly we might store multiple copies in a single flash device, or if we want RAM redunancy we might
have multiple RAM device and vote their values as we read them out (a hardware implementation).

## Single Error Detection, Multiple Error Detection (SECDED)
Another mechanism for protecting data that is in a sense an intermediate between a CRC and redunant image is hamming codes. In this case
we store extra data proportional to the data set size and use it to detect and correct errors.

This is very commonly used, and in some systems
there is a separate device to store this extra data, such as a flash device of a smaller size that stores the hamming codes used when reading
from the primary flash to detect corrupt data. In this case you might be given an interrupt which you can use to record the problem and correct
the corruption. This techique can be done in software, but it is very nice to have hardware support that can do the calculations and notify you
of any errors. Note that errors are usually only detected on reads, so your scrubber should be reading these devices to trigger error detection.


As the name suggests, these codes are usually used in a form that can correct a single bit and detect double bit errors. Note that there are several
parameters involves that trade off the amount of extra data and the number of errors we can detect and correct, but in every case I've seen these
used the parameters are set up for the SECDED scheme. I imagine that it is a good middle ground between correction and storage, especially if
corruption is infrequent and we expect to see almost all single bit errors.


I found a paper on the CALIPSO system which introduced me to a neat technique when using SECDED. If we store a single redunant image as well as
the SECDED data, we use less storage then three redundant images. However, consider the possible cases of corruption. If there is a single corruption
in any data, we can of course correct it. If there is two corruptions in different locations, then we can of course correct them. If there are
two corrupt bits in a single location then we can detect it with SECDED data, and correct it with the redundant copy. If there are three errors
in a single location, we can detect it again and correct with the correct data. If the three errors are split into two in one location, and one
in the corresponding location in the redundant copy, then we can correc the single bit error and then use the corrected result to correct the
double bit error in the other image. Its only when we get to 4 errors split into two corruptions in corresponding locations in each of the
two images that we can't correct the data. This means that we go from single error correction to triple error detection with a single
redunant image, which is quite cool.


# Boot Up
There are some aspects of the boot process that should be noted when it comes to memory corruption. If software images are corrupt, they can
become unbootable which is one potentially mission ending problem. There may be no way to correct this kind of issue, and you might end up in
a frozen state or a reboot loop which never ends.


With this said we should take bootup very seriously. The boot process should be able to perform checks on images, either voting them or
performing a CRC check and switching images if an error is detected. In the worst case we have no correct images, and in that case the
only thing to do is boot an image and hope that it works. Even if the image is corrupt, there is a good chance it will still boot at least
well enough to reimage the storage device and fix the problem.


There are a number of schemes we can implement here, and I think every system I've seen uses a different strategy. Some options are to 
have to boot process check an input discrete, and boot a different image depending on its value. This can be used to boot a 'golden image'
which is not updated during the mission, in case the normal image is corrupt (or just has a bug that we need to fix using the known good image).
I've never seen a system that votes images as they are read from flash- they usually seem to check a CRC and have a strategy for cycling
images when corruption is found. There can also be a system in place for the system to know that it did not finish booting, so that
it can try a different image next time it boots to prevent a cycle where the system resets (such as due to a watchdog timer) during bootup
and never gets to an operational state.


# Stuck Bits
There is a complication that we might want to think about when designing our storage system, which is that it is possible for a storage device
to fail in such a way as to have a bit that is stuck as a 1 or 0. In this case we can't just write our data back to fix the corruption- it might
be uncorrectable. In this case we might need to be able to move our data to another location in storage, although with a flash file system we
might not have this kind of control.


This is also important in large storage devices where we might want to mark a block of flash as a "bad block" and stop using it. Again a flash
file system will do this automatically, but if we manage flash by hand we should be able to detect this situation and avoid these parts of the
storage device.


# Conclusion
I hope this has been interesting or useful as a practical set of techniques for systems which have to operate in the presence of radiation.
I didn't go into details on hamming codes, or other codes for that matter, and I haven't given a full example design for how to apply these ideas,
but I just wanted to get some ideas down and make them available to others that might be in this situation.
