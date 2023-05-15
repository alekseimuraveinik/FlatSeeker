from telethon import TelegramClient, sync
import asyncio
import requests

def get_code():
    return requests.get("http://localhost:8080").json()

def start_client(path):
    client = TelegramClient(path, 15845540, '4cb8ba1d05d513ed32a86f62fcd0e499')
    client.start('+995555993502', code_callback=get_code)
    return client

def get_messages(client):
    return client.get_messages(-1001793067559, limit=20)

async def _download_photo(message):
    return await message.download_media(file=bytes)

def download_photos(messages, path):
    tasks = [_download_photo(message) for message in messages]
    loop = asyncio.get_event_loop()
    image_bytes_array = loop.run_until_complete(asyncio.gather(*tasks))
    return image_bytes_array
