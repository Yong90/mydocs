import random
 
print(random.random())#(0,1)----float
 
print(random.randint(1,3))  #[1,3]
 
print(random.randrange(1,3)) #[1,3)
 
print(random.choice([1,'23',[4,5]]))#23
 
print(random.sample([1,'23',[4,5]],2))#[[4, 5], '23']
 
print(random.uniform(1,3))#1.927109612082716
 
 
item=[1,3,5,7,9]
random.shuffle(item)
print(item)


#######  验证码
import random

def v_code():

    code = ''
    for i in range(5):

        num=random.randint(0,9)
        alf=chr(random.randint(65,90))
        add=random.choice([num,alf])
        code += str(add)
    return code

print(v_code())

验证码
