# 引入traceback打印异常信息,最全面
import traceback


def dev(a, b):
    try:
        c = a / b
    except Exception as e:
        info = traceback.format_exc()
        print(info)
    else:
        print("不存在异常")


if __name__ == '__main__':
    dev(2, 1)
