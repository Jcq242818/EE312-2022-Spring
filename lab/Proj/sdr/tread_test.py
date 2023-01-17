import threading
import random
import time


class calthread(threading.Thread):
    # 初始化函数
    def __init__(self, threadname, cond, startN, endN):
        threading.Thread.__init__(self, name=threadname)
        self.cond = cond
        self.startN = startN
        self.endN = endN
        # print "MyName: " + threadname +",start--" +str(startN) +",end--"+str(endN)

    # 业务函数
    def run(self):
        global sumN, alist, countFinish
        temp = 0
        for i in range(self.startN, self.endN + 1):
            temp = temp + alist[i]
            # 累加计算和，并累加完成计数器
        self.cond.acquire()
        countFinish += 1
        sumN += temp
        # print "MyName: " + self.getName() +",mySum--" +str(temp) +",countFinish--"+str(countFinish)+",currentTotalSum---"+str(sumN)+"\n"
        global threadN
        if (countFinish == threadN):
            print
            "End time of threadCal -- " + str(time.time())
            print
            "The total sum : " + str(sumN) + "\n"
        self.cond.release()

    # 获取线程锁


cond = threading.Condition()
# 目标计算数组的长度
alen = 10000000
# 执行计算工作的线程长度
threadN = 10000
# 随机初始化数组元素
alist = []
# alist = [random.uniform(1,1000) for x in range(0,alen)]
for i in range(1, alen + 1):
    alist.append(i)

# 执行线程对象列表
threadL = []
t = alen / threadN
print
"初始化线程"
for x in range(0, threadN):
    startN = x * t
    endN = 0
    if ((x + 1) * t >= alen):
        endN = alen - 1
    else:
        if (x == threadN - 1):
            endN = alen - 1
        else:
            endN = (x + 1) * t - 1
            # 向列表中存入新线程对象
    threadTT = calthread("Thread--" + str(x), cond, startN, endN)
    threadL.append(threadTT)

# 总计完成线程计数器
countFinish = 0
sumN = 0
print
"Start time of threadCal--" + str(time.time())
for a in threadL:
    a.start()

time.sleep(10)
normalSum = 0
print
"Start time of normalCal--" + str(time.time())
for n in range(0, alen):
    normalSum += alist[n]
print
"End time of normalCal--" + str(time.time())

print
"Normal : " + str(normalSum) + "\n"
