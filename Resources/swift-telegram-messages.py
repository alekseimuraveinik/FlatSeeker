from telethon import TelegramClient, sync
import asyncio
import requests


api_id = 15845540
api_hash = '4cb8ba1d05d513ed32a86f62fcd0e499'
phone_number = '+995555993502'
code_request_url = 'http://localhost:8080'

chat_id = -1001793067559


def start_client(path):
    client = TelegramClient(path, api_id, api_hash)
    client.start(
        phone=lambda: phone_number,
        code_callback=lambda: requests.get(code_request_url).json()
    )
    return client


def get_messages(client):
    return client.get_messages(chat_id, limit=20)


async def _download_photo(message):
    return await message.download_media(file=bytes)


def download_photos(messages):
    tasks = [_download_photo(message) for message in messages]
    loop = asyncio.get_event_loop()
    image_bytes_array = loop.run_until_complete(asyncio.gather(*tasks))
    return image_bytes_array
