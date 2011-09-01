use czmq
import czmq

main: func {
    ctx := Context new()

    pull := ctx createSocket(ZMQ PULL)
    pull connect("tcp://localhost:5555") 

    while(true) {
	//pull recvString() println()
	frame := pull recv()
	"%s" printfln(size data())
	data destroy()
    }
}
