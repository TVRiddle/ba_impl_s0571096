import typer

from nio import AsyncClient
from nio import ClientConfig

config = ClientConfig(store_sync_tokens=True)
# admin1 = AsyncClient("https://127.0.0.1:8008", "admin_a", store_path="./creds/admin_a", config=config)
# admin2 = AsyncClient("https://127.0.0.1:8009", "admin_b", store_path="./creds/admin_b", config=config)
# admin3 = AsyncClient("https://127.0.0.1:8010", "admin_c", store_path="./creds/admin_c", config=config)
# user1 = AsyncClient("https://127.0.0.1:8008", "user_a", store_path="./creds/admin_a", config=config)
# user2 = AsyncClient("https://127.0.0.1:8009", "user_b", store_path="./creds/admin_b", config=config)
# user3 = AsyncClient("https://127.0.0.1:8010", "user_c", store_path="./creds/admin_c", config=config)
admin1 = AsyncClient("http://127.0.0.1:8008", "admin_a", store_path="./creds/admin_a", config=config)
admin2 = AsyncClient("http://127.0.0.1:8009", "admin_b", store_path="./creds/admin_b", config=config)
admin3 = AsyncClient("http://127.0.0.1:8010", "admin_c", store_path="./creds/admin_c", config=config)
user1 = AsyncClient("http://127.0.0.1:8008", "user_a", store_path="./creds/admin_a", config=config)
user2 = AsyncClient("http://127.0.0.1:8009", "user_b", store_path="./creds/admin_b", config=config)
user3 = AsyncClient("http://127.0.0.1:8010", "user_c", store_path="./creds/admin_c", config=config)

clients = {
    "admin_a": {
        "c": admin1,
        "p": "admin",
        "h": "first.server",
        "i": "@admin_a:first.server"
    },
    "admin_b": {
        "c": admin2,
        "p": "admin",
        "h": "second.server",
        "i": "@admin_b:second.server"
    },
    "admin_c": {
        "c": admin3,
        "p": "admin",
        "h": "third.server",
        "i": "@admin_c:third.server"
    },
    "user_a": {
        "c": user1,
        "p": "user",
        "h": "first.server",
        "i": "@user_a:first.server"
    },
    "user_b": {
        "c": user2,
        "p": "user",
        "h": "second.server",
        "i": "@user_b:second.server"
    },
    "user_c": {
        "c": user3,
        "p": "user",
        "h": "third.server",
        "i": "@user_c:third.server"
    },
}


def get_clients_from_source():
    return clients


def get_client(user):
    if user in clients:
        return clients[user]
    else:
        color_print(f"{user} is not available. Consider to run 'show-users' to see which users are available",
                    typer.colors.RED)


async def login_check() -> None:
    for c in clients:
        color_print(await clients[c]['c'].login(clients[c]['p']))
        await clients[c]['c'].close()


def color_print(msg: str, color: typer.colors = typer.colors.WHITE):
    typer.echo(typer.style(f"{msg}", fg=color))
