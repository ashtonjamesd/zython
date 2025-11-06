a = 0
b = 1

# reaches 32-bit integer limit at 46
n = 45

while n > 0:
    print(a)

    temp = a
    a = b
    b = temp + b

    n -= 1