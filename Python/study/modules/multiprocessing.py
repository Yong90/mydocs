from multiprocessing import Process
import time
def f(name):
    time.sleep(1)
    print('hello', name,time.ctime())

if __name__ == '__main__':
    p_list=[]
    for i in range(3):
        p = Process(target=f, args=('alvin',))
        p_list.append(p)
        p.start()
    for i in p_list:
        p.join()
    print('end')
    
    
###Process
构造方法：
Process([group [, target [, name [, args [, kwargs]]]]])

　　group: 线程组，目前还没有实现，库引用中提示必须是None； 
　　target: 要执行的方法； 
　　name: 进程名； 
　　args/kwargs: 要传入方法的参数。

实例方法：
　　is_alive()：返回进程是否在运行。
　　join([timeout])：阻塞当前上下文环境的进程程，直到调用此方法的进程终止或到达指定的timeout（可选参数）。
　　start()：进程准备就绪，等待CPU调度
　　run()：strat()调用run方法，如果实例进程时未制定传入target，这star执行t默认run()方法。
　　terminate()：不管任务是否完成，立即停止工作进程

属性：
　　authkey
　　daemon：和线程的setDeamon功能一样
　　exitcode(进程在运行时为None、如果为–N，表示被信号N结束）
　　name：进程名字。
　　pid：进程号。
  
#     进程池
from  multiprocessing import Process,Pool
import time
 
def Foo(i):
    time.sleep(2)
    return i+100
 
def Bar(arg):
    print('-->exec done:',arg)
 
pool = Pool(5)
 
for i in range(10):
    pool.apply_async(func=Foo, args=(i,),callback=Bar)
    #pool.apply(func=Foo, args=(i,))
 
print('end')
pool.close()
pool.join()




#Queues
from multiprocessing import Process, Queue

def f(q,n):
    q.put([42, n, 'hello'])

if __name__ == '__main__':
    q = Queue()
    p_list=[]
    for i in range(3):
        p = Process(target=f, args=(q,i))
        p_list.append(p)
        p.start()
    print(q.get())
    print(q.get())
    print(q.get())
    for i in p_list:
            i.join()
            
#Pipes
from multiprocessing import Process, Pipe
 
def f(conn):
    conn.send([42, None, 'hello'])
    conn.close()
 
if __name__ == '__main__':
    parent_conn, child_conn = Pipe()
    p = Process(target=f, args=(child_conn,))
    p.start()
    print(parent_conn.recv())   # prints "[42, None, 'hello']"
    p.join()
    
 ###Managers
 from multiprocessing import Process, Manager

def f(d, l,n):
    d[n] = '1'
    d['2'] = 2
    d[0.25] = None
    l.append(n)
    print(l)

if __name__ == '__main__':
    with Manager() as manager:
        d = manager.dict()

        l = manager.list(range(5))
        p_list = []
        for i in range(10):
            p = Process(target=f, args=(d, l,i))
            p.start()
            p_list.append(p)
        for res in p_list:
            res.join()

        print(d)
        print(l)
        
        
        
 
 
 
