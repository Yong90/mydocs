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
