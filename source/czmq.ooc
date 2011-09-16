use czmq
include czmq

// DEBUG code
import structs/ArrayList

ZMQ: enum {
    REQ: extern(ZMQ_REQ)
    REP: extern(ZMQ_REP)
    XREQ: extern(ZMQ_XREQ)
    XREP: extern(ZMQ_XREP)
    PUSH: extern(ZMQ_PUSH)
    PULL: extern(ZMQ_PULL)
    PUB: extern(ZMQ_PUB)
    SUB: extern(ZMQ_SUB)
    PAIR: extern(ZMQ_PAIR)

    POLLIN: extern(ZMQ_POLLIN)
    POLLOUT: extern(ZMQ_POLLOUT)
    POLLERR: extern(ZMQ_POLLERR)

    SUBSCRIBE: extern(ZMQ_SUBSCRIBE)
}

Context: cover from zctx_t* {

    new: extern(zctx_new) static func -> This
    createSocket: extern(zsocket_new) func (ZMQ) -> Socket
    destroySocket: extern(zsocket_destroy) func (Socket)
    destroy: extern(zctx_destroy) func@

}

zstr_send: extern func (Socket, CString)
zstr_recv: extern func (Socket) -> CString
zstr_recv_nowait: extern func (Socket) -> CString
zframe_send: extern func (Frame*, Socket, Int)
zmsg_send: extern func (Message*, Socket)
zsockopt_set_subscribe: extern func (Socket, CString)

/**
 * zsocket - working with ØMQ sockets
 */
Socket: cover from Pointer {

    //  This port range is defined by IANA for dynamic or private ports
    //  We use this when choosing a port for dynamic binding.
    DYNFROM: extern(ZSOCKET_DYNFROM) static Int
    DYNTO:   extern(ZSOCKET_DYNTO) static Int

    /**
     * Create a new socket within our czmq context, replaces zmq_socket.
     * If the socket is a SUB socket, automatically subscribes to everything.
     * Use this to get automatic management of the socket at shutdown.
     */
    new: extern(zsocket_new) static func (Context, ZMQ) -> This

    getType: extern(zsocket_type_str) func -> CString
    /** Returns socket type as printable constant string */
    type: String {
        get { getType() toString() }
    }

    /**
     * Bind a socket to a formatted endpoint. If the port is specified as
     * '*', binds to any free port from ZSOCKET_DYNFROM to ZSOCKET_DYNTO
     * and returns the actual port number used. Otherwise asserts that the
     * bind succeeded with the specified port number. Always returns the
     * port number if successful.
     */
    bind: extern(zsocket_bind) func (url: CString, ...) -> Int

    /**
     * Connect a socket to a formatted endpoint
     * Checks with assertion that the connect was valid
     */
    connect: extern (zsocket_connect) func (url: CString, ...) -> Int

    /**
     * Read 1 or more frames off the socket, into a new message object
     */
    recvMessage: extern(zmsg_recv) func -> Message

    /**
     * Receive frame from socket, returns zframe_t object or NULL if the recv
     * was interrupted. Does a blocking recv, if you want to not block then use
     * recvFrameNoWait().
     */
    recvFrame: extern(zframe_recv) func -> Frame

    /**
     * Receive a new frame off the socket. Returns newly allocated frame, or
     * NULL if there was no input waiting, or if the read was interrupted.
     */
    recvFrameNoWait: extern(zframe_recv_nowait) func -> Frame

    /**
     * Receive a string off a socket - string is garbage collected when not
     * used anymore.
     */
    recvString: func -> String {
        recv := zstr_recv(this)
        result := recv toString()
        free(recv)
        result
    }

    /**
     * Receive a string off a socket if socket had input waiting
     */
    recvStringNoWait: func -> String {
        recv := zstr_recv_nowait(this)
	if(!recv) return null

        result := recv toString()
        free(recv)
        result
    }

    /**
     * Send a message to the socket, and then destroy it
     */
    sendMessage: func (message: Message) {
        zmsg_send(message&, this)
    }

    /**
     * Send a frame to a socket, destroys frame after sending unless
     * you use ZFRAME REUSE flag
     */
    sendFrame: func (frame: Frame, flags: Int = 0) {
	zframe_send(frame&, this, flags)
    }

    /**
     * Send a string to a socket in ØMQ string format
     */
    sendString: func (s: String) {
        zstr_send(this, s toCString())
    }

}

/**
 * The zframe class provides methods to send and receive single message frames across ØMQ sockets.
 * 
 * A frame corresponds to one zmq_msg_t. When you read a frame from a socket, the zframe_more()
 * method indicates if the frame is part of an unfinished multipart message. The zframe_send method
 * normally destroys the frame, but with the ZFRAME_REUSE flag, you can send the same frame many
 * times. Frames are binary, and this class has no special support for text data.
 */
Frame: cover from zframe_t* {

    MORE : extern(ZFRAME_MORE ) Int
    REUSE: extern(ZFRAME_REUSE) Int

    /**
     * Create a new frame with optional size, and optional data
     */
    new: extern(zframe_new) static func (data: Pointer, size: SizeT) -> This

    /**
     * Return address of frame data
     */
    data: extern(zframe_data) func -> Pointer

    /**
     * Return number of bytes in frame data
     */
    size: extern(zframe_size) func -> SizeT

    /**
     * Destroy a frame
     */
    destroy: extern(zframe_destroy) func@

    /*
     * Create a new frame that duplicates an existing frame
     */
    dup: extern(zframe_dup) func -> Frame

}

zmsg_pushstr: extern func (Message, CString)
zmsg_addstr : extern func (Message, CString)
zmsg_popstr : extern func (Message) -> CString
zmsg_size : extern func (Message) -> SizeT

/**
 * The zmsg class provides methods to send and receive multipart messages across ØMQ sockets.
 * 
 * This class provides a list-like container interface, with methods to work with the overall
 * container. zmsg_t messages are composed of zero or more zframe_t frames.
 */
Message: cover from zmsg_t* {

    new: extern(zmsg_new) static func -> This 

    push: extern(zmsg_push) func (Frame)
    add : extern(zmsg_add)  func (Frame)
    pop:  extern(zmsg_pop) func -> Frame

    pushmem: extern(zmsg_pushmem) func (Pointer, SizeT)
    addmem : extern(zmsg_addmem)  func (Pointer, SizeT)

    pushstr: func (s: String) {
        zmsg_pushstr(this, s toCString())
    }

    addstr : func (s: String) {
        zmsg_addstr(this, s toCString())
    }

    popstr : func -> String {
        zmsg_popstr(this) toString()
    }

    destroy: extern(zmsg_destroy) func@

    size: func -> SizeT {
        zmsg_size(this)
    }
}

_PollItem: cover from zmq_pollitem_t {
    socket: extern Socket
    fd: extern Int
    events: extern ZMQ
    revents: extern Short
}

PollItem: cover from _PollItem* 

LoopCallback: class {
    socket: Socket = null
    fd: Int = 0

    f: Func (Loop, PollItem)
    init: func ~sock (=f, =socket)
    init: func ~fd (=f, =fd)
    init: func ~nothing (=f)
}

loop_thunk: func (l: Loop, item: PollItem, arg: Pointer) {
    arg as LoopCallback f(l, item)
}

loop_callbacks := ArrayList<LoopCallback> new()

/**
 * The zloop class provides an event-driven reactor pattern. The reactor handles
 * zmq_pollitem_t items (pollers or writers, sockets or fds), and once-off or
 * repeated timers. Its resolution is 1 msec. It uses a tickless timer to reduce
 * CPU interrupts in inactive processes.
 */
Loop: cover from Pointer {

    /**
     * Create a new zloop reactor
     */
    new: extern(zloop_new) static func -> This

    //zloop_poller (zloop_t *self, zmq_pollitem_t *item, zloop_fn handler, void *arg);
    poller: extern(zloop_poller) func(PollItem, Pointer, Pointer) -> Int

    //zloop_poller_end (zloop_t *self, zmq_pollitem_t *item);
    pollerEnd: extern(zloop_poller_end) func(PollItem)

    /**
     * Register pollitem with the reactor. When the pollitem is ready, will call
     * the handler, passing the arg.
     * 
     * Returns 0 if OK, -1 if there was an error.
     * If you register the pollitem more than once, each instance will invoke its
     * corresponding handler.
     */
    addEvent: func ~socket (socket: Socket, events: ZMQ, f: Func (Loop, PollItem)) -> LoopCallback {
	pollitem := gc_malloc(_PollItem size) as PollItem
	pollitem@ socket = socket
	pollitem@ fd = 0
	pollitem@ events = events

	callback := LoopCallback new(f, socket)
	loop_callbacks add(callback)

	poller(pollitem, loop_thunk, callback)

        callback
    }

    addEvent: func ~fileDescriptor (fd: Int, events: ZMQ, f: Func (Loop, PollItem)) -> LoopCallback {
	pollitem := gc_malloc(_PollItem size) as PollItem
	pollitem@ socket = null
	pollitem@ fd = fd
	pollitem@ events = events

	callback := LoopCallback new(f, fd)
	loop_callbacks add(callback)

	poller(pollitem, loop_thunk, callback)

        callback
    }

    removeEvent: func (callback: LoopCallback) {
        pollitem := gc_malloc(_PollItem size) as PollItem
        pollitem@ socket = callback socket
        pollitem@ fd = callback fd

        pollerEnd(pollitem)
        loop_callbacks remove(callback)
    }

    // TODO: removeEvent

    start: extern(zloop_start) func -> Int

    //zloop_timer (zloop_t *self, size_t delay, size_t times, zloop_fn handler, void *arg);
    timer: extern(zloop_timer) func(SizeT, SizeT, Pointer, Pointer) -> Int

    //zloop_timer_end (zloop_t *self, void *arg);
    timerEnd: extern(zloop_timer_end) func (Pointer)

    addTimer: func (delay: SizeT, times: SizeT, f: Func (Loop, PollItem)) -> LoopCallback {
        callback := LoopCallback new(f)
        loop_callbacks add(callback)

	timer(delay, times, loop_thunk, callback)

        callback
    }

    removeTimer: func (callback: LoopCallback) {
        timerEnd(callback)
        loop_callbacks remove(callback)
    }

    /**
     * Destroy a reactor
     */
    destroy: extern(zloop_destroy) func 

    /**
     * Set verbose tracing of reactor on/off
     */
    setVerbose: extern(zloop_set_verbose) func(Bool) -> Int
}

