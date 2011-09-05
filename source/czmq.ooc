use czmq
include czmq

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

zsockopt_set_subscribe: extern func (Socket, CString)
// I would expect zsocket_t but the examples use void*, so here goes.
Socket: cover from Pointer {

    DYNFROM: extern(ZSOCKET_DYNFROM) static Int
    DYNTO:   extern(ZSOCKET_DYNTO) static Int

    new: extern(zsocket_new) static func (Context, ZMQ) -> This

    getType: extern(zsocket_type_str) func -> CString
    type: String {
        get { getType() toString() }
    }

    bind: extern(zsocket_bind) func (url: CString, ...) -> Int
    connect: extern (zsocket_connect) func (url: CString, ...) -> Int

    recvFrame: extern(zframe_recv) func -> Frame

    recvString: func -> String {
        recv := zstr_recv(this)
        result := recv toString()
        free(recv)
        result
    }

    sendString: func (s: String) {
        zstr_send(this, s toCString())
    }

    setSockOpt: extern(zmq_setsockopt) func (opt: ZMQ, value: Pointer, option_len: SizeT)

    setSubscribe: func (prefix: String) {
        setSockOpt(ZMQ SUBSCRIBE, prefix toCString(), prefix length())
    }

}

Frame: cover from zframe_t* {

    data: extern(zframe_data) func -> Pointer
    destroy: extern(zframe_destroy) func

}

_PollItem: cover from zmq_pollitem_t {
    socket: extern Socket
    fd: extern Int
    events: extern ZMQ
    revents: extern Short
}
PollItem: cover from _PollItem* 

    //LoopFn: cover from Func(Loop, PollItem, Pointer)

LoopCallback: class {
    f: Func (Loop, PollItem)
    init: func(=f)
}

loop_thunk: func (l: Loop, item: PollItem, arg: Pointer) {
    arg as LoopCallback f(l, item)
}

Loop: cover from Pointer {

    new: extern(zloop_new) static func -> This

    //zloop_poller (zloop_t *self, zmq_pollitem_t *item, zloop_fn handler, void *arg);
    poller: extern(zloop_poller) func(PollItem, Pointer, Pointer) -> Int

    //zloop_poller_end (zloop_t *self, zmq_pollitem_t *item);
    pollerEnd: extern(zloop_poller_end) func(PollItem)

    addEvent: func (socket: Socket, events: ZMQ, f: Func (Loop, PollItem)) {
	pollitem: _PollItem
	pollitem socket = socket
	pollitem fd = 0
	pollitem events = events

	poller(pollitem&, loop_thunk, LoopCallback new(f))
    }

    removeEvent: func (socket: Socket) {
	pollitem: _PollItem
	pollitem socket = socket
	pollitem fd = 0

	pollerEnd(pollitem&)
    }

    start: extern(zloop_start) func -> Int

    //zloop_timer (zloop_t *self, size_t delay, size_t times, zloop_fn handler, void *arg);
    timer: extern(zloop_timer) func(SizeT, SizeT, Pointer, Pointer) -> Int

    addTimer: func (delay: SizeT, times: SizeT, f: Func (Loop, PollItem)) {
	timer(delay, times, loop_thunk, LoopCallback new(f))
    }

    destroy: extern(zloop_destroy) func 

    setVerbose: extern(zloop_set_verbose) func(Bool) -> Int
}
