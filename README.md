Program to test cascading CTC in ZXSpectrum Next emulation and hardware.
Utilises 3 CTC timers, cascading to create a 1 second interrupt, which increments a counter.

CTC runs at 28mhz = 28,000,000 T-States/cycles

CTC0 is a timer, prescaler 16, count 175 = 2,800 T
CTC1 is a counter, count 125 = 350,000 T
CTC2 is a counter, interrupt, count 80 = 28,000,000 T
