use czmq
import czmq

assert: extern func (...)

main: func {
    ctx := Context new()
    interf := "*" toCString()
    domain := "localhost" toCString()
    service := 5560

    writer := ctx createSocket(ZMQ PUSH)
    reader := ctx createSocket(ZMQ PULL)
    assert (writer type == "PUSH")
    assert (reader type == "PULL")
    rc := writer bind("tcp://%s:%d", interf, service)
    assert (rc == service)

    reader connect("tcp://%s:%d", domain, service)
    "HELLO" sendTo(writer)
    message := reader recvString()
    assert (message)
    assert (message == "HELLO")

    "Message received = %s" printfln(message)

    port :=  writer bind("tcp://%s:*", interf)
    assert (port >= Socket DYNFROM && port <= Socket DYNTO)

    ctx destroySocket(writer)
    ctx destroy()
}
