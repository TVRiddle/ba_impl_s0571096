import asyncio

import typer

from tasks import create_new_room
from tasks import do_stuf
from tasks import invite_to_room
from tasks import join_room
from tasks import login
from tasks import logout
from tasks import receive_msgs
from tasks import send_message
from utils import get_client
from utils import get_clients_from_source
from utils import login_check

app = typer.Typer()

tasks = []


@app.command()
def test() -> None:
    """
    Tests if all available users can login
    """
    asyncio.get_event_loop().run_until_complete(login_check())


@app.command()
def show_users():
    """
    Shows all available users. All users with the same letter are based on the same server
    """
    for c in get_clients_from_source():
        typer.echo(typer.style(c, fg=typer.colors.GREEN, bold=True))


@app.command()
def create_room(
        user: str = typer.Option("", "--user", "-u", help="User that should be owner of the room", show_default=False),
        room: str = typer.Option("", "--room", "-r", help="Name of the room that should be created",
                                 show_default=False)):
    """
    Creates new room with the named user as owner
    """
    client = get_client(user)
    asyncio.get_event_loop().run_until_complete(login(client['c'], client['p']))
    asyncio.get_event_loop().run_until_complete(create_new_room(client['c'], room, room))
    asyncio.get_event_loop().run_until_complete(logout(client['c']))


@app.command()
def invite(user: str = typer.Option("", "--user", "-u", help="Inviting user", show_default=False),
           room: str = typer.Option("", "--room", "-r", help="Room name that should be invited in", show_default=False),
           new_user=typer.Option("", "--new-user", "-n", help="Invited user that also accept the invitation",
                                 show_default=False)):
    """
    The first named client invites the second in the named room. The second client accept this invitation
    """
    client = get_client(user)
    invited = get_client(new_user)
    asyncio.get_event_loop().run_until_complete(login(client['c'], client['p']))
    asyncio.get_event_loop().run_until_complete(invite_to_room(client['c'], room, invited["i"]))

    asyncio.get_event_loop().run_until_complete(login(invited['c'], invited['p']))
    asyncio.get_event_loop().run_until_complete(join_room(invited['c'], room))

    asyncio.get_event_loop().run_until_complete(logout(client['c']))
    asyncio.get_event_loop().run_until_complete(logout(invited['c']))


@app.command("send-message")
def send_message_cli(user: str = typer.Option("", "--user", "-u", help="Inviting user", show_default=False),
                     room: str = typer.Option("", "--room", "-r", help="Room in witch the message should be send",
                                              show_default=False),
                     message: str = typer.Option("", "--message", "-m", help="The string that should be send",
                                                 show_default=False)):
    """
    Sends message in name of the user to the named room
    """
    client = get_client(user)
    asyncio.get_event_loop().run_until_complete(login(client['c'], client['p']))
    asyncio.get_event_loop().run_until_complete(send_message(client['c'], room, message))
    asyncio.get_event_loop().run_until_complete(logout(client['c']))


@app.command()
def receive_messages(user: str = typer.Option("", "--user", "-u", help="User for which all messages got received",
                                              show_default=False),
                     room: str = typer.Option("", "--room", "-r", help="Shows only messages for named room",
                                              show_default=False)):
    """
    Gets all messeges for named user
    """
    client = get_client(user)
    asyncio.get_event_loop().run_until_complete(login(client['c'], client['p']))
    asyncio.get_event_loop().run_until_complete(receive_msgs(client['c'], room))
    asyncio.get_event_loop().run_until_complete(logout(client['c']))


@app.command()
def delete_room(
        user: str = typer.Option("", "--user", "-u", help="User that should be owner of the room", show_default=False),
        room: str = typer.Option("", "--room", "-r", help="Name of the room that should be deleted",
                                 show_default=False)):
    """
    Lets a user leave a room and forgets it
    """
    client = get_client(user)
    asyncio.get_event_loop().run_until_complete(login(client['c'], client['p']))
    asyncio.get_event_loop().run_until_complete(do_stuf(client['c'], room))
    asyncio.get_event_loop().run_until_complete(logout(client['c']))


def get_loggedin_client(name):
    c = get_client(name)
    cl = c['c']
    asyncio.get_event_loop().run_until_complete(login(cl, c['p']))
    return cl


if __name__ == "__main__":
    app()
