use czmq
import czmq

import os/Time

main: func {
    ctx := Context new()

    push := ctx createSocket(ZMQ PUSH)
    push bind("tcp://localhost:5555")

    i := 0
    while(true) {
        push sendString("Strike %d" format(i))
	i += 1
	Time sleepSec(0.000001)
    }
}   
