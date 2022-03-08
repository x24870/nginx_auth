from flask import Flask
from flask import request
from flask import Response
from flask import abort

from config import conf
from middleware import middleware

app = Flask(__name__)

# middleware
app.wsgi_app = middleware(app=app.wsgi_app)

@app.route('/')
def hello_world():
    return 'Flask Dockerized'

@app.route('/auth')
def auth():
    if request.headers.get('token') and request.headers['token'] == conf.token:
        resp = Response(response='authenticated', status=200)
    else:
        return abort(401, "auth_server: invalid token")
    return resp

@app.route('/private')
def private():
    return Response(response='this is a private page', status=200)


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=conf.port)
