from flask import Flask, render_template
import socket
app = Flask(__name__)
@app.route("/")
def index():
    host = socket.gethostname()
    ip = socket.gethostbyname(host)
    return render_template('index.html', \
               message=ip)
if __name__ == "__main__":
    app.run(host='0.0.0.0', debug=True)
