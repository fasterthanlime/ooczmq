use czmq
import czmq

myHandler: func(l: Loop, item: PollItem, arg: Pointer) -> Int {
    item@ socket recvString() println()
    0
}

main: func {
    ctx := Context new()
    sub := ctx createSocket(ZMQ SUB)
    sub connect("tcp://localhost:5555") 
    loop := Loop new()
    loop setVerbose(true)
    pollInput := [sub, 0, ZMQ POLLIN] as PollItem
    loop poller(pollInput, myHandler, null)
    loop start()

}
