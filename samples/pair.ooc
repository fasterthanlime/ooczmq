use czmq
import czmq


main: func {

    context := Context new()

    pair1 := Socket new(context, ZMQ PAIR)
    pair2 := Socket new(context, ZMQ PAIR)

    pair1 bind("tcp://0.0.0.0:7777")
    pair2 connect("tcp://0.0.0.0:7777")

    for (i in 0..10) {
        pair1 sendString("Count: %d" format(i))
        pair2 recvString() println()
        pair2 sendString("Gotcha!")
        pair1 recvString() println() 
    }

}
