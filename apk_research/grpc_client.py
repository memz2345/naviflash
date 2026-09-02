import socket
import ssl
import h2.connection
import h2.config
import h2.events
import sys
import base64
import struct

HOST = "grpc.biliapi.net"
PORT = 443
SERVICE = "/bilibili.app.show.v1.Popular/Index"

# PopularResultReq fields: source_id=13(varint), flush=14(varint), idx=1(varint)
def build_req(source_id=1, flush=1, idx=0, entrance_id=0):
    out = b""
    def varint(v):
        b = b""
        while True:
            c = v & 0x7F
            v >>= 7
            if v:
                b += bytes([c | 0x80])
            else:
                b += bytes([c])
                return b
    def tag(field, wire):
        return varint((field << 3) | wire)
    if idx:
        out += tag(1, 0) + varint(idx)
    if source_id:
        out += tag(13, 0) + varint(source_id)
    if flush:
        out += tag(14, 0) + varint(flush)
    return out

def grpc_frame(msg):
    return b"\x00" + struct.pack(">I", len(msg)) + msg

ctx = ssl.create_default_context()
ctx.set_alpn_protocols(["h2"])
raw = socket.create_connection((HOST, PORT), timeout=30)
sock = ctx.wrap_socket(raw, server_hostname=HOST)
print("TLS ALPN:", sock.selected_alpn_protocol())

config = h2.config.H2Configuration(client_side=True, header_encoding="utf-8")
conn = h2.connection.H2Connection(config=config)
conn.initiate_connection()
sock.sendall(conn.data_to_send())

req_body = build_req(source_id=1, flush=1)
body = grpc_frame(req_body)

headers = [
    (":method", "POST"),
    (":scheme", "https"),
    (":authority", HOST),
    (":path", SERVICE),
    ("te", "trailers"),
    ("content-type", "application/grpc"),
    ("user-agent", "grpc-java-okhttp/1.63.0"),
    ("accept-encoding", "gzip"),
    ("buvid", "427BD4A0-C7ED-9E7B-C955-2E90B990F88228979infoc"),
    ("x-bili-device-bin", base64.b64encode(bytes(96)).decode()),
    ("x-bili-metadata-bin", base64.b64encode(bytes(16)).decode()),
    ("x-bili-trace-id", "00000000000000000000000000000000"),
]
conn.send_headers(1, headers, end_stream=False)
conn.send_data(1, body, end_stream=True)
sock.sendall(conn.data_to_send())

resp_data = b""
trailers = {}
end = False
while not end:
    data = sock.recv(65535)
    if not data:
        break
    events = conn.receive_data(data)
    for event in events:
        if isinstance(event, h2.events.DataReceived):
            resp_data += event.data
            conn.acknowledge_received_data(event.flow_controlled_length, event.stream_id)
        elif isinstance(event, h2.events.StreamEnded):
            end = True
        elif isinstance(event, h2.events.ResponseReceived):
            for k, v in event.headers:
                if k == ":status":
                    print("GRPC status:", v)
        elif isinstance(event, h2.events.TrailersReceived):
            for k, v in event.headers:
                trailers[k] = v
    sock.sendall(conn.data_to_send())

print("trailers:", trailers)
with open(r"C:\Users\memz2345\AppData\Local\Temp\opencode\testapk\hot_resp.bin", "wb") as f:
    f.write(resp_data)
print("response bytes:", len(resp_data))
if len(resp_data) > 5:
    print("first 5 bytes:", resp_data[:5].hex())