interface State
    exposes [
        attempt,
        perform,
        bind,
        map,
        get,
        put,
        ok,
        err,
    ]
    imports []

State state ok err := state -> Result (ok, state) err

attempt : State state ok err, state -> Result (ok, state) err
attempt = \@State r, init ->
    r init

perform : State state ok [], state -> (ok, state)
perform = \state, init ->
    (Ok result) = attempt state init
    result

bind : State state ok err, (ok -> State state ok2 err) -> State state ok2 err
bind = \first, next ->
    @State \s1 ->
        (o, s2) <- attempt first s1 |> Result.try
        attempt (next o) s2

map : State state ok err, (ok -> ok2) -> State state ok2 err
map = \first, next ->
    @State \s1 ->
        (o, s2) <- attempt first s1 |> Result.map
        (next o, s2)

get : State state state err
get = @State \state -> Ok (state, state)

put : state -> State state {} err
put = \state -> @State \_ -> Ok ({}, state)

ok : ok -> State * ok *
ok = \o -> @State \state -> Ok (o, state)

err : err -> State * * err
err = \e -> @State \_ -> Err e

expect
    next =
        curr <- get |> bind
        _ <- put (curr + 1) |> bind

        ok curr

    seq =
        one <- next |> bind
        two <- next |> bind
        three <- next |> bind

        ok (one, two, three)

    perform seq 1 == ((1, 2, 3), 3)

expect
    seq =
        one <- get |> bind
        err one

    attempt seq 1 == Err 1
