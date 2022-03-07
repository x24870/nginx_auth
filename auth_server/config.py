import os

class Config:
    def __init__(self):
        self.port = os.getenv('port')
        self.token = os.getenv('secret')

conf = Config()
