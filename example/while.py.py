import time

i = 1
n = 1000000

st = time.time()

while i <= n:
    print(i)
    i += 1

et = time.time()

elapsed = (et - st) * 1000
print(f"{elapsed:.3f} ms")