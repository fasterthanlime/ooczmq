use czmq
import czmq

{
    ctx := Context new()
    interf := "*"
    domain := "localhost"
    service := 5560

    writer := Socket new(ctx, ZMQ PUSH)
}
