import socket
import ssl
import h2.connection
import h2.config
import h2.events
import base64
import struct

HOST = "grpc.biliapi.net"
PORT = 443
SERVICE = "/bilibili.app.show.v1.Popular/Index"


def varint(v):
    b = b""
    while True:
        c = v & 0x7F
        v >>= 7
        b += bytes([c | 0x80]) if v else bytes([c])
        if not v:
            return b


def tag(field, wire):
    return varint((field << 3) | wire)


def field_varint(f, v):
    return tag(f, 0) + varint(v)


def field_str(f, s):
    data = s.encode("utf-8")
    return tag(f, 2) + varint(len(data)) + data


def field_msg(f, data):
    return tag(f, 2) + varint(len(data)) + data


def build_device():
    out = b""
    out += field_varint(1, 10013)          # app_id
    out += field_varint(2, 8840200)        # build
    out += field_str(3, "427BD4A0-C7ED-9E7B-C955-2E90B990F88228979infoc")  # buvid
    out += field_str(4, "android")         # mobi_app
    out += field_str(5, "android")         # platform
    out += field_str(6, "Pixel 8")         # device
    out += field_str(7, "bili")            # channel
    out += field_str(8, "Google")          # brand
    out += field_str(9, "Pixel 8")         # model
    out += field_str(10, "14")             # osver
    out += field_str(13, "8.84.0")         # version_name
    return out


def build_metadata():
    out = b""
    out += field_str(1, "")                # access_key
    out += field_str(2, "android")         # mobi_app
    out += field_msg(3, build_device())    # device
    out += field_varint(4, 8840200)        # build
    out += field_str(5, "bili")            # channel
    out += field_str(6, "427BD4A0-C7ED-9E7B-C955-2E90B990F88228979infoc")  # buvid
    out += field_str(7, "android")         # platform
    return out


def build_fawkes():
    out = b""
    out += field_str(1, "27eb53fc9058f8c3")  # appkey
    out += field_str(2, "prod")              # env
    return out


def build_network():
    out = b""
    out += field_varint(1, 1)   # type = WIFI
    return out


def build_req(source_id=1, flush=1):
    out = b""
    out += tag(13, 0) + varint(source_id)
    out += tag(14, 0) + varint(flush)
    return out


def grpc_frame(msg):
    return b"\x00" + struct.pack(">I", len(msg)) + msg


ctx = ssl.create_default_context()
ctx.set_alpn_protocols(["h2"])
sock = ctx.wrap_socket(socket.create_connection((HOST, PORT), timeout=30), server_hostname=HOST)
cfg = h2.config.H2Configuration(client_side=True, header_encoding="utf-8")
conn = h2.connection.H2Connection(config=cfg)
conn.initiate_connection()
sock.sendall(conn.data_to_send())
body = grpc_frame(build_req())

device_bin = base64.b64encode(build_device()).decode()
metadata_bin = base64.b64encode(build_metadata()).decode()
fawkes_bin = base64.b64encode(build_fawkes()).decode()
network_bin = base64.b64encode(build_network()).decode()

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
    ("x-bili-device-bin", device_bin),
    ("x-bili-metadata-bin", metadata_bin),
    ("x-bili-fawkes-req-bin", fawkes_bin),
    ("x-bili-network-bin", network_bin),
    ("x-bili-mid", "0"),
    ("x-bili-trace-id", "2a600ba7456a8e7702c0111039879ec4"),
    ("x-bili-aurora-eid", ""),
    ("x-bili-gaia-vtoken", ""),
    ("x-bili-ip-bin", base64.b64encode(bytes(16)).decode()),
    ("x-bili-exps-bin", base64.b64encode(bytes(2)).decode()),
]
conn.send_headers(1, headers, end_stream=False)
conn.send_data(1, body, end_stream=True)
sock.sendall(conn.data_to_send())
resp = b""
end = False
while not end:
    data = sock.recv(65535)
    if not data:
        break
    for e in conn.receive_data(data):
        t = type(e).__name__
        if isinstance(e, h2.events.DataReceived):
            resp += e.data
            conn.acknowledge_received_data(e.flow_controlled_length, e.stream_id)
        elif isinstance(e, h2.events.StreamEnded):
            end = True
        elif isinstance(e, h2.events.ResponseReceived):
            print("RESP", [(k, v) for k, v in e.headers])
        elif isinstance(e, h2.events.TrailersReceived):
            print("TRAIL", [(k, v) for k, v in e.headers])
        elif isinstance(e, h2.events.StreamReset):
            print("RST", e.error_code)
    sock.sendall(conn.data_to_send())
print("resp bytes:", len(resp))
open(r"C:\Users\memz2345\AppData\Local\Temp\opencode\testapk\hot_resp.bin", "wb").write(resp)
if len(resp) > 5:
    print("first bytes:", resp[:16].hex())