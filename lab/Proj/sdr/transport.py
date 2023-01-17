import socket

client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)


def send_file(file_path):
    try:
        # 数据传输
        with open(file_path, "rb") as file:
            while True:
                # 读取文件数据
                file_data = file.read(-1)
                # 数据长度不为0表示还有数据
                if file_data:
                    client.send(file_data)
                # 数据为0表示传输完成
                else:
                    print("传输成功")
                    break
    except Exception as e:
        print("传输异常：", e)


ip = '192.168.0.103'
# 连接服务器
client.connect((ip, 8000))
print('connect successful')
file_path = '/home/pi/Desktop/test000001.csv'
while True:
    recv_com = client.recv(1024).decode('utf-8')
    print(recv_com)
    if recv_com == '1':
        send_file(file_path)
        # 这里需要设置传输完成后手动关闭本连接，要不然服务器会一直等待。
        client.close()
        break
client.close()
print('Done')
