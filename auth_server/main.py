from flask import Flask
from flask import request
from flask import Response
from flask import abort

SECRET = 'jigentec'

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Flask Dockerized'

@app.route('/auth')
def auth():
    if request.headers.get('secret') and request.headers['secret'] == SECRET:
        resp = Response(response='authenticated', status=200)
    else:
        return abort(401, "auth_server: not correct secret")
    return resp

@app.route('/private')
def private():
    return Response(response='this is a private page', status=200)


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=8080)