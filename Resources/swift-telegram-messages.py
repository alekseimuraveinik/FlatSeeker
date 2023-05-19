from telethon import TelegramClient, sync
from itertools import groupby
import re
from telethon import utils
from requests import get


districts = [
    'ваке-сабуртало',
    'ваке',
    'сабуртало',
    'диди дигоми',
    'дигоми',
    'исани',
    'исаны',
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
    'вазисубани',
    'варкетили',
    'батуми',
    'ортчала',
    'мардженешвили',
    'марджанишвили',
]

district_patterns = list(map(lambda name: re.compile(name), districts)) + [
    re.compile(r'Район {0,2}#([а-яА-Я]+)'),
    re.compile(r'Район {0,2}:? {0,2}([а-яА-Я]+)')
]

price_patterns = [
    re.compile(r'\$[  ]{0,3}(\d{3,4})'),
    re.compile(r'(\d{3,4})[  ]{0,3}[$💰💵]'),
    re.compile(r'(\d{3,4})[  ]{0,3}долларов')
]


def parse_price(text):
    for price_pattern in price_patterns:
        match = re.search(price_pattern, text)
        if match:
            value = match.group(1)
            if int(value) == 0:
                return ''
            return value
    return None


def parse_district(text):
    text = text.lower()
    for district_pattern in district_patterns:
        match = re.search(district_pattern, text)
        if match:
            try:
                return match.group(1)
            except:
                return text[match.start():match.end()]
    return None


class MessageGroup:
    def __init__(self, grouped_id, messages):
        self.grouped_id = grouped_id
        self.messages = messages
        self.images = list(
            map(
                lambda x: (x.id, utils.stripped_photo_to_jpg(x.photo.sizes[0].bytes)),
                messages
            )
        )

        text_message = next((x for x in self.messages if x.message != ''), None)
        if text_message:
            self.text = text_message.message
            self.price = parse_price(self.text)
            self.district = parse_district(self.text)
        else:
            self.text = None


class Client:
    limit = 100
    least_recent_message_id = None
    remaining_messages = []

    def __init__(self, session_path, api_id, api_hash, phone_number, code_request_url, chat_id):
        self.chat_id = chat_id
        self.client = TelegramClient(session_path, api_id, api_hash)
        self.client.start(
            phone=lambda: phone_number,
            code_callback=lambda: get(code_request_url).json()
        )

    def get_message_groups(self):
        if self.least_recent_message_id:
            messages = self.client.get_messages(self.chat_id, limit=self.limit, max_id=self.least_recent_message_id)
        else:
            messages = self.client.get_messages(self.chat_id, limit=self.limit)
        self.least_recent_message_id = messages[-1].id

        messages = list(
            filter(
                lambda x: x.grouped_id is not None and x.photo is not None,
                messages
            )
        )

        messages = self.remaining_messages + messages

        grouped_messages = groupby(messages, key=lambda x: x.grouped_id)
        message_groups = [MessageGroup(key, list(result)) for key, result in grouped_messages]

        if len(message_groups) < 2:
            self.remaining_messages = messages
            return []

        self.remaining_messages = message_groups[-1].messages

        message_groups = list(sorted(message_groups, key=lambda x: x.grouped_id, reverse=True))[0:-1]
        message_groups = list(
            filter(
                lambda group: group.text is not None and group.text != '',
                message_groups
            )
        )

        return message_groups


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
            if len(message_groups) != 0:
                for group in message_groups:
                    print('Images:', len(group.images), '|', group.district, group.price)
                input()
        except KeyboardInterrupt:
            client.client.disconnect()
            break


if __name__ == "__main__":
    main()
