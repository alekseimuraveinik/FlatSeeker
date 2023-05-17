from telethon import TelegramClient, sync
import asyncio
import requests
from itertools import groupby


class Client:
    limit = 20
    least_recent_message_id = None
    remaining_messages = []

    def __init__(self, session_path, api_id, api_hash, phone_number, code_request_url, chat_id):
        self.chat_id = chat_id
        self.client = TelegramClient(session_path, api_id, api_hash)
        self.client.start(
            phone=lambda: phone_number,
            code_callback=lambda: requests.get(code_request_url).json()
        )

    def get_messages(self):
        if self.least_recent_message_id:
            messages = self.client.get_messages(self.chat_id, limit=self.limit, max_id=self.least_recent_message_id)
        else:
            messages = self.client.get_messages(self.chat_id, limit=self.limit)
        self.least_recent_message_id = messages[-1].id

        messages = list(filter(lambda x: x.grouped_id != None, messages))
        grouped = [list(result) for key, result in groupby(messages, key=lambda x: x.grouped_id)]
        groups = grouped[0:-1]

        messages = [item for sublist in groups for item in sublist]

        messages_to_return = self.remaining_messages + messages
        self.remaining_messages = grouped[-1]
        return messages_to_return


async def _download_photo(message):
    return await message.download_media(file=bytes)


def download_photos(messages):
    tasks = [_download_photo(message) for message in messages]
    loop = asyncio.get_event_loop()
    image_bytes_array = loop.run_until_complete(asyncio.gather(*tasks))
    return image_bytes_array


def main():
    from dotenv import load_dotenv
    from os import getenv
    load_dotenv()
    session_path = getenv('SESSION_PATH')
    api_id = getenv('API_ID')
    api_hash = getenv('API_HASH')
    phone_number = getenv('PHONE_NUMBER')
    code_request_url = getenv('CODE_REQUEST_URL')
    chat_id = int('-' + getenv('CHAT_ID'))

    client = Client(session_path, api_id, api_hash, phone_number, code_request_url, chat_id)
    while True:
        try:
            messages = client.get_messages()
            print(list(map(lambda x: x.grouped_id, messages)))
            input('Type Enter to fetch next page')
        except KeyboardInterrupt:
            break


if __name__ == "__main__":
    main()
