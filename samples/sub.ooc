use czmq
import czmq

main: func {
    ctx := Context new()

    sub := ctx createSocket(ZMQ SUB)
    sub connect("tcp://localhost:5555") 

    while(true) {
	sub recvString() println()
    }
}
