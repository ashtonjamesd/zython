# lol, 'elif' does not work yet so i had to be silly with this implementation

i = 0
while i < 15:
    i += 1
    
    if i % 3 == 0 and i % 5 == 0:
        print("FizzBuzz")
    if i % 3 == 0 and i % 5 != 0:
        print("Fizz")
    if i % 5 == 0 and i % 3 != 0:
        print("Buzz")
    
    if not (i % 3 == 0 or i % 5 == 0):
        print(i)