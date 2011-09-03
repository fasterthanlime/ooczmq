use czmq
import czmq

import os/Time

main: func {
    ctx := Context new()

    pub := ctx createSocket(ZMQ PUB)
    pub bind("tcp://0.0.0.0:5555")

    i := 0
    while(true) {
        pub sendString("Strike %d" format(i))
        i += 1
        Time sleepSec(0.001)
    }
}   
