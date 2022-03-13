from datetime import datetime

from nio import AsyncClient
from nio import EnableEncryptionBuilder
from nio import JoinError
from nio import MatrixRoom
from nio import RoomCreateError
from nio import RoomInviteError
from nio import RoomMessageText
from nio import RoomSendError
from typer.colors import CYAN
from typer.colors import GREEN
from typer.colors import RED
from typer.colors import YELLOW

from utils import color_print


async def resolve_room_id(room_name, used_client):
    await used_client.sync()
    for room in used_client.rooms:
        if used_client.rooms[room].display_name == room_name:
            return room
    color_print(f"Room {room_name} is not available. Either the user have not joined the room or it does not exist!",
                RED)


async def create_new_room(used_client: AsyncClient, room_name: str, alias: str, topic: str = "test",
                          init_state: list = [EnableEncryptionBuilder().as_dict()]):
    resp = await used_client.room_create(
        alias=alias,
        name=room_name,
        topic=topic,
        initial_state=init_state)
    if isinstance(resp, RoomCreateError):
        color_print(f"Room_create failed with {resp}", YELLOW)
    else:
        color_print(f'Created room {room_name}.', CYAN)


async def invite_to_room(used_client: AsyncClient, room_name: str, invite_user_id: str) -> str:
    room_id = await resolve_room_id(room_name, used_client)
    resp = await used_client.room_invite(room_id, invite_user_id)
    if isinstance(resp, RoomInviteError):
        color_print(f"room_invite failed with {resp}", YELLOW)
    else:
        color_print(f'User "{invite_user_id}" was successfully invited to room "{room_name}" | ID->"{room_id}".', CYAN)
    return room_id


async def join_room(used_client: AsyncClient, room_display_name: str):
    await used_client.sync()
    room_id = [x for x in used_client.invited_rooms if used_client.invited_rooms[x].display_name == room_display_name]
    if len(room_id) == 0:
        if 0 != len([x for x in used_client.rooms if used_client.rooms[x].display_name == room_display_name]):
            color_print(f'User {used_client.user_id} already in group {room_display_name}', CYAN)
            return
        color_print(f'User: {used_client.user_id} could not enter {room_display_name} | Cause: He was not invited', RED)
        return
    resp = await used_client.join(room_id[0])
    if isinstance(resp, JoinError):
        color_print(f'User: {used_client.user_id} could not enter {room_display_name} | Cause: {resp}', RED)
    else:
        color_print(f'{used_client.user_id} joined room {room_display_name} | ID: {room_id[0]}', CYAN)


async def send_message(used_client: AsyncClient, room_name: str, message: str):
    try:
        room_name = await resolve_room_id(room_name, used_client)
        resp = await used_client.room_send(
            room_name,
            message_type="m.room.message",
            content={
                "msgtype": "m.text",
                "body": message.strip()
            }
        )
        if isinstance(resp, RoomSendError):
            color_print(f'Message not sent. User: {used_client.user_id} | Room: {room_name} | Message: {message}')
        else:
            color_print("Message send successfully.", CYAN)
    except Exception:
        color_print("Message send failed. Sorry.", RED)
        color_print(f"Message {message} send to room {room_name}", YELLOW)


def message_callback(room: MatrixRoom, event: RoomMessageText) -> None:
    color_print(f"Room: {room.display_name} | Sender: {room.user_name(event.sender)} | Message: {event.body}", GREEN)


async def receive_msgs(used_client: AsyncClient, room_name: str = None):
    if room_name == "":
        used_client.add_event_callback(message_callback, RoomMessageText)
        await used_client.sync()
    else:
        resp = await used_client.sync()
        room_id = [x for x in used_client.rooms if used_client.rooms[x].display_name == room_name][0]
        events = await used_client.room_messages(room_id, resp.next_batch)
        messages = [x for x in events.chunk if (type(x) == RoomMessageText)]
        messages.reverse()
        for m in messages:
            time = datetime.fromtimestamp(int(m.server_timestamp / 1000))
            color_print(f"Time: {time} | Room: {room_name} | Sender: {m.sender} | Message: {m.body}", GREEN)


async def do_stuf(c1, r1, c2):
    await invite_to_room(c1, r1, c2)
    print("here for development stuff")


async def login(client: AsyncClient, pw: str):
    resp = str(await client.login(pw))
    # Uncomment if you want to see every login
    # color_print(resp, CYAN)


async def logout(client: AsyncClient):
    await client.close()
