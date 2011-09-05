use czmq
import czmq

main: func {
    ctx := Context new()
    sub := ctx createSocket(ZMQ SUB)
    sub connect("tcp://localhost:5555") 
    loop := Loop new()
    loop setVerbose(true)

    loop addEvent(sub, ZMQ POLLIN, |l, item|
	sub recvString() println()
    )
    loop start()

}
