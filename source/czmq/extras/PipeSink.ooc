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
    inputCallback: LoopCallback = null
    timeoutCallback: LoopCallback = null
    // How often to check for inactivity
    timeout: SizeT = 250

    init: func ~pipe (=loop, =pullSocket, =pipe) {
        fd = pipe writeFD
        start()
    }
    init: func ~fileDescriptor (=loop, =pullSocket, =fd) {
        start()
    }

    start: func () {
        outputCallback = loop addEvent(pullSocket, ZMQ POLLIN, |loop, item| processEvents())
        timeoutCallback = loop addTimer(timeout, 0, |loop, item| checkInactivity())
    }

    processEvents: func () {
        if(!inputCallback) {
            removeOutputCB()
            inputCallback = loop addEvent(fd, ZMQ POLLOUT, |loop, item| pump())
        }
    }

    pump: func () -> Bool {
        frame := pullSocket recvFrameNoWait()
        if(frame) {
            feed(frame data(), frame size())
            return true
        }
        false
    }

    checkInactivity: func () {
        if(!outputCallback && !pump()) {
            removeInputCB()
            outputCallback = loop addEvent(pullSocket, ZMQ POLLIN, |loop, item| processEvents())
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

    removeOutputCB: func () {
        if(outputCallback) {
            loop removeEvent(outputCallback)
            outputCallback = null
        }
    }

    removeInputCB: func () {
        if(inputCallback) {
            loop removeEvent(inputCallback)
            inputCallback = null
        }
    }

    destroy: func () {
        removeOutputCB()
        removeInputCB()
        loop removeTimer(timeoutCallback)
        timeoutCallback = null
        // FIXME: There's probably something else to do here as well, ideas?
    }
}
