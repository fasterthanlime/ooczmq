use czmq
import czmq

main: func {
    ctx := Context new()

    pull := ctx createSocket(ZMQ PULL)
    pull bind("tcp://*:5555") 

    while(true) {
	pull recvString() println()
    }
}
