from werkzeug.wrappers import Request, Response

from config import conf

class middleware():
    '''
    Simple WSGI middleware
    '''

    def __init__(self, app):
        self.app = app
        self.token = conf.token

    def __call__(self, environ, start_response):
        request = Request(environ)
        token = request.headers.get('Token')
        
        if token == self.token:
            return self.app(environ, start_response)

        res = Response(u'Authorization failed', mimetype= 'text/plain', status=401)
        return res(environ, start_response)
