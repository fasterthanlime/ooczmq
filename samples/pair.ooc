use czmq
import czmq


main: func {

    context := Context new()

    pair1 := Socket new(context, ZMQ PAIR)
    pair2 := Socket new(context, ZMQ PAIR)

    pair1 bind("tcp://0.0.0.0:7777")
    pair2 connect("tcp://0.0.0.0:7777")

    pair1 sendString("Hello, World")
    pair2 recvString() println()

}
