use czmq
import czmq

main: func {
    ctx := Context new()

    output := Socket new(ctx, ZMQ PAIR)
    output bind("inproc://zloop.test")
    input := Socket new(ctx, ZMQ PAIR)
    input connect("inproc://zloop.test")

    loop := Loop new()

    loop setVerbose(true) // fancy debug messages
    //  After 10 msecs, send a ping message to output
    loop timer(10, 1, timerEvent, output)
    //  When we get the ping message, end the reactor
    pollInput := [input, 0, ZMQ POLLIN] as PollItem // struct literal

    pollStdIn := [null, 1, ZMQ POLLIN] as PollItem
    loop timer(5000, 1, exitEvent, null) // force exit
    loop poller(pollInput, socketEvent, null)
    loop start()

    loop destroy()
    ctx destroy()

}

socketEvent: func(a: Loop, b: PollItem, c: Pointer) {
    "socket event!" println()
    "Message received: %s" format(b@ socket recvString()) println()
}

timerEvent: func(loop: Loop, item: PollItem, arg: Pointer) {
    "timer event!" println()
    "item addr:%p" format(item) println()
    arg as Socket sendString("hello")
}

// program hangs somehow
exitEvent: func(a: Loop, b: PollItem, c: Pointer) {
    "Goodbye, cruel world!" println()
    exit(0)
}
