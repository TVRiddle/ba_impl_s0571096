import asyncio

import typer

from tasks import *

app = typer.Typer()

server_ip = {
    "first.m_server": "http://127.0.0.1:8008",
    "second.m_server": "http://127.0.0.1:8009",
    "third.m_server": "http://127.0.0.1:8010"
}
server_name = {
    "first.m_server": "first.server",
    "second.m_server": "second.server",
    "third.m_server": "third.server"
}


def get_client(user_name: str, server: str) -> AsyncClient:
    c = AsyncClient(server_ip[server], user_name)
    asyncio.get_event_loop().run_until_complete(login(c, user_name))
    return c


def get_full_user_name(user_name: str, server: str) -> str:
    return f"@{user_name}:{server_name[server]}"


@app.command()
def create_room(server: str, user: str, room: str) -> None:
    c = get_client(user, server)
    asyncio.get_event_loop().run_until_complete(create_new_room(c, room, room))
    asyncio.get_event_loop().run_until_complete(logout(c))


@app.command()
def invite_user(server: str, user: str, room: str, server_inv: str, user_inv: str) -> None:
    c = get_client(user, server)
    inv = get_client(user_inv, server_inv)

    asyncio.get_event_loop().run_until_complete(invite_to_room(c, room, get_full_user_name(user_inv, server_inv)))
    asyncio.get_event_loop().run_until_complete(join_room(inv, room))

    asyncio.get_event_loop().run_until_complete(logout(c))
    asyncio.get_event_loop().run_until_complete(logout(inv))


@app.command()
def write_message(server: str, user: str, room: str, msg: str):
    c = get_client(user, server)
    asyncio.get_event_loop().run_until_complete(send_message(c, room, msg))
    asyncio.get_event_loop().run_until_complete(logout(c))


@app.command()
def read_message(server: str, user: str, room: str):
    c = get_client(user, server)
    asyncio.get_event_loop().run_until_complete(receive_msgs(c, room))
    asyncio.get_event_loop().run_until_complete(logout(c))


if __name__ == "__main__":
    app()
