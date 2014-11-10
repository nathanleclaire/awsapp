from python:2.7
add /requirements.txt /code/requirements.txt
workdir /code
run pip install -r requirements.txt
add . /code
cmd ["python", "app.py"]
