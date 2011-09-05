use czmq
import czmq

import os/Time

counter := 0
myHandler: func(l: Loop, item: PollItem, arg: Pointer) -> Int {
    arg as Socket sendString("%d" format(counter))
    counter += 1
    0
}

main: func {
    ctx := Context new()
    pub := ctx createSocket(ZMQ PUB)
    pub bind("tcp://0.0.0.0:5555")
    loop := Loop new()
    loop setVerbose(true)
    loop timer(100, 0,  myHandler, pub)
    loop start()

}   
