passed = 0
failed = 0

if True:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if False:
    print("Nay!")
    failed += 1
else:
    print("Yay!")
    passed += 1
    
if not True:
    print("Nay!")
    failed += 1
else:
    print("Yay!")
    passed += 1

if True and True:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1
    
if True or False:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 2 < 4:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 4 > 2:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1
    
if 2 <= 2 and 2 <= 4:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 4 >= 2 and 4 >= 4:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if True != False:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1
    
if True == True:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 2 + 2 == 4:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1
    
if 37 - 5 == 32:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1
    
if 4 * 5 == 20:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1
    
if 10 / 2 == 5:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1
    
if 548 % 2 == 0:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 5 ** 3 == 125:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 27 // 5 == 5:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 5 & 3 == 1:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 5 | 3 == 7:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if 5 ^ 3 == 6:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

if ~5 == -6:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

# if 3 << 2 == 12:
#     print("Yay!")
#     passed += 1
# else:
#     print("Nay!")
#     failed += 1
#
# if 12 >> 2 == 3:
#     print("Yay!")
#     passed += 1
# else:
#     print("Nay!")
#     failed += 1

a = 5
a += 3
if a == 8:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

b = 10
b -= 4
if b == 6:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

c = 7
c *= 3
if c == 21:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

d = 20
d /= 4
if d == 5:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

e = 10
e %= 3
if e == 1:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

f = 2
f **= 3
if f == 8:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

g = 17
g //= 3
if g == 5:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

a = 5
a &= 3
if a == 1:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

b = 5
b |= 2
if b == 7:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

c = 6
c ^= 3
if c == 5:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1

# d = 8
# d <<= 2
# if d == 32:
#     print("Yay!")
#     passed += 1
# else:
#     print("Nay!")
#     failed += 1

# e = 20
# e >>= 2
# if e == 5:
#     print("Yay!")
#     passed += 1
# else:
#     print("Nay!")
#     failed += 1

if i := 5 == 5:
    print("Yay!")
    passed += 1
else:
    print("Nay!")
    failed += 1


print("")
print("Passed:")
print(passed)

print("")

print("Failed:")
print(failed)
print("")