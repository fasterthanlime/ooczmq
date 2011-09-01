use czmq
import czmq

{
    ctx := Context new()
    interf := "*"
    domain := "localhost"
    service := 5560

    writer := Socket new(ctx, ZMQ PUSH)
    reader := Socket new(ctx, ZMQ PULL)

    writer bind("tcp://%s:%d", interf toCString(), service)
    reader connect("tcp://%s:%d", domain toCString(), service)

    "ooc POWER FTW" sendTo(writer)
    reader recvString() println()

}
