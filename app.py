from flask import Flask, render_template
from redis import Redis
import os
app = Flask(__name__)
redis = Redis(host='redis', port=6379)

@app.route('/')
def hello():
    redis.incr('hits')
    return render_template('index.html', hits=redis.get('hits'))

if __name__ == "__main__":
    app.run(host="0.0.0.0")
