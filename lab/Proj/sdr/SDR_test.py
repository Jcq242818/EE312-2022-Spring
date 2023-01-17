from rtlsdr import *
from pylab import *
from multiprocessing.dummy import Pool
from threading import Thread
import time
import traceback


def read_data(sdr):
    samples = sdr.read_samples(256 * 1024)
    clf()
    psd(samples.real, NFFT=1024, Fs=sdr.sample_rate / 1e6, Fc=sdr.center_freq / 1e6)
    xlabel('Frequency (MHz)')
    ylabel('Relative power (dB)')
    show()
    sdr.close()  # 读完这一次设备要关不然下一次读取该设备会被占用，但是USB总线上可挂载多个设备，所以同时并行读取应该没啥问题


serial_number = RtlSdr.get_device_serial_addresses()
print(serial_number)
sdr_ar = []
for i in range(0, size(serial_number)):
    sdr_i = RtlSdr(RtlSdr.get_device_index_by_serial(serial_number[i]))
    sdr_i.sample_rate = 2.4e6
    sdr_i.center_freq = 93.5e6
    sdr_i.gain = 50  # 这些参数需要配置，如要配置配置多大的值
    sdr_ar.append(sdr_i)  # 这里应该先查找4个
tread = []
for i in range(0, size(serial_number)):
    tread.append(Thread(target=read_data, args=sdr_ar[i]))

if __name__ == '__main__':
    try:
        tread[0].start()
        tread[1].start()
        tread[2].start()
        tread[3].start()
        # 自旋锁等待线程终止
        tread[0].join()
        tread[1].join()
        tread[2].join()
        tread[3].join()
    except Exception as e:
        info = traceback.format_exc()
        print(info)
    else:
        print("读取正常，没有任何错误")
