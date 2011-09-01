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
}

Context: cover from zctx_t* {

    new: extern(zctx_new) static func -> This
    createSocket: extern(zsocket_new) func (ZMQ) -> Socket
    destroySocket: extern(zsocket_destroy) func (Socket)
    destroy: extern(zctx_destroy) func@

}

zstr_send: extern func (Socket, CString)
zstr_recv: extern func (Socket) -> CString

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

}

Frame: cover from zframe_t* {

    data: extern(zframe_data) func -> Pointer
    destroy: extern(zframe_destroy) func

}

