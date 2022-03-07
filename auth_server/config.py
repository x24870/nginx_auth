import os

class Config:
    def __init__(self):
        self.port = os.environ['PORT']
        self.token = os.environ['TOKEN']

conf = Config()
