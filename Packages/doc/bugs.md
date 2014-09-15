# Known bugs in 3rd party software

## ITC XOP

* The help of the operation `ITCShortAcquisition` says
> Third Column  = SamplingInterval:  integer value for sampling interval in microseconds (minimum value - 5 us)
which is plain wrong. The third column of the setup wave holds the number of data points which should be acquired.
