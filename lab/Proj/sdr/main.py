from rtlsdr import *
from pylab import *
from multiprocessing.dummy import Pool
import time


def read_data(sdr):
    samples = sdr.read_samples(256 * 1024)
    clf()
    psd(samples.real, NFFT=1024, Fs=sdr.sample_rate / 1e6, Fc=sdr.center_freq / 1e6)
    xlabel('Frequency (MHz)')
    ylabel('Relative power (dB)')
    show()
    time.sleep(1)  # sleep for 1s


pool = Pool(15)  # 创建拥有15个进程数量的进程池
serial_number = RtlSdr.get_device_serial_addresses()
print(serial_number)
sdr_ar = []
for i in range(0, size(serial_number)):
    sdr_i = RtlSdr(RtlSdr.get_device_index_by_serial(serial_number[i]))
    sdr_i.sample_rate = 2.4e6
    sdr_i.center_freq = 93.5e6
    sdr_i.gain = 50  # 这些参数需要配置，如要配置配置多大的值
    sdr_ar.append(sdr_i)  # 这里应该先查找4个
# 开始并行读取接收
pool.map(read_data, sdr_ar)
pool.close()
pool.join()
