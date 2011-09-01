use czmq
include czmq

Context: cover from zctx_t* {

    new: extern(zctx_new) static func -> This
    destroy_socket: extern(zsocket_destroy) func (Socket)
    destroy: extern(zctx_destroy) func@

}

zstr_send: extern func (Socket, CString)
zstr_recv: extern func (Socket) -> CString

// I would expect zsocket_t but the examples use void*, so here goes.
Socket: cover from Pointer {

    new: extern(zsocket_new) static func -> This

    getType: extern(zsocket_type_str) func -> CString
    type: String {
        get { getType() toString() }
    }

    bind: extern(zsocket_bind) func (url: CString, ...) -> Int
    connect: extern (zsocket_connect) func (url: CString, ...) -> Int

    recvString: func -> String {
        zstr_recv(this) toString()
    }

}

extend String {

    sendTo: func (s: Socket) {
        zstr_send(s, toCString())
    }

}
