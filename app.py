from flask import Flask, render_template
from redis import Redis

from tornado.wsgi import WSGIContainer
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop

import os

app = Flask(__name__)
redis = Redis(host='redis', port=6379)
server_name = os.getenv('SRV_NAME')
server_health_key = '{0}_health'.format(server_name)

@app.route('/health/on')
def health_on():
    redis.set(server_health_key, 'on')
    return 'Health key {0} set to on!'.format(server_health_key)

@app.route('/health/off')
def health_off():
    redis.set(server_health_key, 'off')
    return 'Health key {0} set to off!'.format(server_health_key)

@app.route('/health/check')
def health_check():
    health = redis.get(server_health_key)
    if health == 'on':
        return 'healthy', 200
    else:
        return 'not healthy', 500

@app.route('/')
def index():
    redis.incr('hits')
    return render_template('index.html', hits=redis.get('hits'))

if __name__ == "__main__":
    health_on()
    http_server = HTTPServer(WSGIContainer(app))
    http_server.listen(5000)
    IOLoop.instance().start()
