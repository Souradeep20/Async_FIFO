# RTL Design and Validation of Dual Clock Asynchronous FIFO
A clock-domain crossing (CDC) occurs when digital information is transferred between logic operating from different clocks. A dual-clock asynchronous FIFO is a commonly used CDC structure for safely buffering data between such domains. Unlike a synchronous FIFO, the write and read sides of an asynchronous FIFO do not require a common clock or a fixed phase relationship.
This project implements a 32-bit wide asynchronous FIFO with a depth of 8 words. The write domain operates at 100 MHz while the read domain operates at 50 MHz. Since the write side is faster than the read side, the FIFO is intentionally exercised under a producer-faster-than-consumer condition. The design uses binary pointers for memory addressing, Gray-coded pointers for clock-domain crossing, and two-flop synchronizers for the crossing pointer signals.


# Asynchronous FIFO Architecture
The FIFO contains an 8-entry memory. The write side controls the memory write operation using the write clock, while the read side controls the read pointer using the read clock. The two domains exchange only Gray-coded pointer information through synchronizers.


# Pointer Organization
Eight memory locations require three address bits because 2^3 = 8. However, an asynchronous FIFO needs one additional pointer bit to distinguish between different wrap-around states. Therefore, both the read and write pointers are 4 bits wide.
For example, the binary write pointer progresses from 0000 through 0111 for the first pass through the memory and then continues to 1000 through 1111 for the next pass. The lower three bits select the memory location, while the additional bit participates in full detection.


# Binary-to-Gray conversion
The binary pointers are converted to Gray code before crossing clock domains. The conversion used in the RTL is: Gray = Binary XOR (Binary >> 1)
Gray code is useful because adjacent pointer values differ in only one bit. This reduces the possibility of the destination domain observing an ambiguous multi-bit transition.


# Clock-Domain Crossing and Metastability
The write pointer is generated using wclk, whereas the read logic uses rclk. Because these clocks are asynchronous, a pointer signal generated in one domain cannot be directly used as synchronous logic in the other domain.
The design therefore uses a two-flop synchronizer for each pointer crossing. The Gray-coded read pointer is synchronized into the write domain, and the Gray-coded write pointer is synchronized into the read domain.

The first synchronizer stage may become metastable when the asynchronous input changes near a destination clock edge. The second stage provides additional settling time before the signal reaches the FIFO control logic. Thus, the two-flop synchronizer mitigates metastability propagation, while Gray coding minimizes multi-bit transition ambiguity.

# Full and Empty Flag Logic

## Empty flag
The read domain considers the FIFO empty when the next read Gray pointer is equal to the synchronized write Gray pointer.
An important consequence of the asynchronous design is that empty does not necessarily deassert immediately when a write occurs. The write pointer must first pass through the two-flop synchronizer into the read domain. This intentional latency is a normal property of a safe CDC implementation.

## Full flag
For the 4-bit Gray pointer used by this 8-entry FIFO, full is detected by comparing the next write Gray pointer against the synchronized read Gray pointer with the two most significant bits inverted.
This comparison detects the condition in which the write pointer is one complete FIFO capacity ahead of the read pointer.

Because the flags depend on synchronized pointer information, they are conservative. After a write, the read side may continue to indicate empty until the write pointer is synchronized. Similarly, after a read creates free space, the write side may continue to indicate full until the updated read pointer reaches the write domain. This behavior is desirable for CDC safety because it avoids making optimistic decisions based on unsynchronized information.
