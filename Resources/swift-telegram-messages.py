from telethon import TelegramClient, sync
import asyncio
import requests
from itertools import groupby
import re


districts = [
    'ваке',
    'сабуртало',
    'диди дигоми',
    'исани',
    'сололаки',
    'надзаладеви',
    'авлабари',
    'глдани',
    'дидубе',
    'чугурети',
    'мтацминда',
    'cанзона',
    'ортачала',
    'церетели',
    'вера',
]

district_patterns = list(map(lambda name: re.compile(name), districts)) + [
    re.compile(r'Район {0,2}#([а-яА-Я]+)'),
    re.compile(r'Район {0,2}:? {0,2}([а-яА-Я]+)')
]

price_patterns = [
    re.compile(r'\$[  ]{0,3}(\d{3,4})'),
    re.compile(r'(\d{3,4})[  ]{0,3}[$💰]'),
    re.compile(r'(\d{3,4})[  ]{0,3}долларов')
]


def parse_price(text):
    for price_pattern in price_patterns:
        match = re.search(price_pattern, text)
        if match:
            return match.group(1)
    return ''


def parse_district(text):
    text = text.lower()
    for district_pattern in district_patterns:
        match = re.search(district_pattern, text)
        if match:
            try:
                return match.group(1)
            except:
                return text[match.start():match.end()]
    return ''


class MessageGroup:
    def __init__(self, grouped_id, messages):
        self.grouped_id = grouped_id
        self.messages = messages
        self.text_message = next((x.message for x in messages if x.message != ''), '')
        self.price = parse_price(self.text_message)
        if self.price != '' and int(self.price) == 0:
            self.price = ''
        self.district = parse_district(self.text_message).capitalize()


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

    def get_message_groups(self):
        if self.least_recent_message_id:
            messages = self.client.get_messages(self.chat_id, limit=self.limit, max_id=self.least_recent_message_id)
        else:
            messages = self.client.get_messages(self.chat_id, limit=self.limit)
        self.least_recent_message_id = messages[-1].id

        messages = self.remaining_messages + list(filter(lambda x: x.grouped_id != None, messages))
        grouped_messages = groupby(messages, key=lambda x: x.grouped_id)
        message_groups = [MessageGroup(key, list(result)) for key, result in grouped_messages]
        message_groups = list(
            filter(
                lambda group: group.text_message != '',
                message_groups
            )
        )

        if len(message_groups) == 0:
            return []

        self.remaining_messages = message_groups[-1].messages
        return message_groups[0:-1]


async def _download_image(message):
    return await message.download_media(file=bytes)


def download_images(messages):
    tasks = [_download_image(message) for message in messages]
    loop = asyncio.get_event_loop()
    image_bytes_array = loop.run_until_complete(asyncio.gather(*tasks))
    return image_bytes_array


def download_image(message):
    return message.download_media(file=bytes)


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
            message_groups = client.get_message_groups()
            for group in message_groups:
                print(group.price, group.district)
            input()
        except KeyboardInterrupt:
            break


if __name__ == "__main__":
    main()
