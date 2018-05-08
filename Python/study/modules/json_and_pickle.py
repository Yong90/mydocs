import json
 
dic={'name':'alvin','age':23,'sex':'male'}
print(type(dic))#<class 'dict'>
 
j=json.dumps(dic)
print(type(j))#<class 'str'>
 
 
f=open('序列化对象','w')
f.write(j)  #-------------------等价于json.dump(dic,f)
f.close()
#-----------------------------反序列化<br>
import json
f=open('序列化对象')
data=json.loads(f.read())#  等价于data=json.load(f)


#dct="{'1':111}"#json 不认单引号
#dct=str({"1":111})#报错,因为生成的数据还是单引号:{'one': 1}

dct='{"1":"111"}'
print(json.loads(dct))

#conclusion:
#        无论数据是怎样创建的，只要满足json格式，就可以json.loads出来,不一定非要dumps的数据才能loads




import pickle
 
dic={'name':'alvin','age':23,'sex':'male'}
 
print(type(dic))#<class 'dict'>
 
j=pickle.dumps(dic)
print(type(j))#<class 'bytes'>
 
 
f=open('序列化对象_pickle','wb')#注意是w是写入str,wb是写入bytes,j是'bytes'
f.write(j)  #-------------------等价于pickle.dump(dic,f)
 
f.close()
#-------------------------反序列化
import pickle
f=open('序列化对象_pickle','rb')
 
data=pickle.loads(f.read())#  等价于data=pickle.load(f)
 
 
print(data['age'])   


import shelve
 
f = shelve.open(r'shelve.txt')
 
# f['stu1_info']={'name':'alex','age':'18'}
# f['stu2_info']={'name':'alvin','age':'20'}
# f['school_info']={'website':'oldboyedu.com','city':'beijing'}
#
#
# f.close()
 
print(f.get('stu_info')['age'])
