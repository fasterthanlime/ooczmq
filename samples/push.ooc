use czmq
import czmq

import os/Time, structs/ArrayList

main: func (args: ArrayList<String>) {
    if(args size < 2) {
	"Usage: push <name>" println()
	return 1
    }

    name := args[1]

    ctx := Context new()

    push := ctx createSocket(ZMQ PUSH)
    push connect("tcp://localhost:5555")

    i := 0
    while(true) {
        push sendString("%s:Strike %d" format(name, i))
	i += 1
	Time sleepSec(1)
    }
}   
