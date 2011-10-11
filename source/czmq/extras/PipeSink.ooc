use czmq
import czmq

import os/[Pipe,FileDescriptor], os/native/PipeUnix

/**
 * The PipeSink class provides an interface for listening to a socket
 * and writing the data received forward to a Pipe or fd handle.
 * The PipeSink is designed for minimal CPU load, so it takes out the
 * Pipe POLLOUT when no data is available from the socket.
*/

PipeSink: class {
    loop: Loop
    pipe: PipeUnix
    fd: FileDescriptor
    pullSocket: Socket
    outputCallback: LoopCallback
    inputCallback: LoopCallback

    init: func ~pipe (=loop, =pullSocket, =pipe) {
        fd = pipe writeFD
        reset()
    }
    init: func ~fileDescriptor (=loop, =pullSocket, =fd) {
        reset()
    }

    reset: func () {
        inputCallback = null
        outputCallback = loop addEvent(pullSocket, ZMQ POLLIN, |loop, item| processEvents())
    }

    processEvents: func () {
        if(!inputCallback) {
            inputCallback = loop addEvent(fd, ZMQ POLLOUT, |loop, item| pump())
        }
    }

    pump: func () {
        frame := pullSocket recvFrameNoWait()
        if(frame) {
            feed(frame data(), frame size())
        } else {
            loop removeEvent(inputCallback)
            inputCallback = null
        }
    }

    feed: func (data : Pointer, len: Int) {
        d := data
        remainder := len
        while (remainder){
            written := fd write(d, remainder)
            remainder -= written
            d += written
        }
    }

    destroy: func () {
        loop removeEvent(outputCallback)
        if(inputCallback) {
            loop removeEvent(inputCallback)
        }
        // FIXME: There's probably something else to do here as well, ideas?
    }
}
