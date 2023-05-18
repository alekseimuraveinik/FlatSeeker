from telethon import TelegramClient, sync
import asyncio
import requests
from itertools import groupby
import re
from telethon import utils
import aiohttp


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
    def __init__(self, grouped_id, zipped):
        self.messages = list(map(lambda x: x[0], zipped.copy()))
        self.images = list(map(lambda x: x[1], zipped))
        self.grouped_id = grouped_id
        self.text_message = next((x for x in self.messages if x.message != ''), None)
        if self.text_message:
            text = self.text_message.message
            self.thumbnail = utils.stripped_photo_to_jpg(self.text_message.photo.sizes[0].bytes)
        else:
            text = ''
        self.price = parse_price(text)
        if self.price != '' and int(self.price) == 0:
            self.price = ''
        self.district = parse_district(text).capitalize()



class ImageGroup:
    def __init__(self, grouped_id, images):
        self.grouped_id = grouped_id
        self.images = images


class Client:
    limit = 100
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

        messages = list(
            filter(
                lambda x: x.grouped_id is not None and x.photo is not None,
                messages
            )
        )

        messages = self.remaining_messages + messages

        loop = asyncio.get_event_loop()
        images = loop.run_until_complete(get_image_urls(messages))

        zipped = list(zip(messages, images))
        grouped_messages = groupby(zipped, key=lambda x: x[0].grouped_id)
        message_groups = [
            MessageGroup(
                key,
                list(result)
            ) for key, result in grouped_messages
        ]

        if len(message_groups) < 2:
            self.remaining_messages = messages
            return []

        self.remaining_messages = message_groups[-1].messages

        message_groups = message_groups[0:-1]
        message_groups = list(
            filter(
                lambda group: group.text_message is not None and group.text_message.message != '',
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
                urls = message_groups[0].images
                for url in urls:
                    print(url)
            input()
        except KeyboardInterrupt:
            client.client.disconnect()
            break


photo_pattern = re.compile(r"background-image:url\('(.*?\.jpg)'\)")
headers = {
    "Host": "t.me",
    "Connection": "keep-alive",
    "Cache-Control": "max-age=0",
    "sec-ch-ua": '"Google Chrome";v="113", "Chromium";v="113", "Not-A.Brand";v="24"',
    "sec-ch-ua-mobile": "?0",
    "sec-ch-ua-platform": "macOS",
    "Upgrade-Insecure-Requests": "1",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-User": "?1",
    "Sec-Fetch-Dest": "document",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "en-GB,en-US;q=0.9,en;q=0.8",
    "Cookie": "stel_ssid=5676ae759e7c041e13_12211778403092897585; stel_on=1; stel_dt=-240"
}


image_url_template = 'https://t.me/tbilisi_arendaa/{}?embed=1&mode=tme&single=1'


async def get_image_urls(messages):
    urls = list(
        map(
            lambda message: image_url_template.format(str(message.id)),
            messages
        )
    )
    async with aiohttp.ClientSession() as session:
        tasks = [fetch(session, url) for url in urls]
        return await asyncio.gather(*tasks)


async def fetch(s, url):
    async with s.get(url, headers=headers) as r:
        if r.status != 200:
            r.raise_for_status()
        text = await r.text()
        matches = re.search(r"background-image:url\('(https://cdn4\S+?\.jpg)", text)
        text = matches.group(1)
        return text


if __name__ == "__main__":
    main()
