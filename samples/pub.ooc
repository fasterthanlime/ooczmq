use czmq
import czmq

import os/Time

main: func {
    ctx := Context new()

    pub := ctx createSocket(ZMQ PUB)
    pub bind("tcp://0.0.0.0:5555")

    while(true) {
        pub sendString("Strike %d")
    }
}   
