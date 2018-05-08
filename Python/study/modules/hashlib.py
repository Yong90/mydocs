import hashlib
 
m=hashlib.md5()# m=hashlib.sha256()
 
m.update('hello'.encode('utf8'))
print(m.hexdigest())  #5d41402abc4b2a76b9719d911017c592
 
m.update('alvin'.encode('utf8'))
 
print(m.hexdigest())  #92a7e713c30abbb0319fa07da2a5c4af
 
m2=hashlib.md5()
m2.update('helloalvin'.encode('utf8'))
print(m2.hexdigest()) #92a7e713c30abbb0319fa07da2a5c4af


hash = hashlib.sha256('898oaFs09f'.encode('utf8'))
hash.update('alvin'.encode('utf8'))
print (hash.hexdigest())#e79e68f070cdedcfe63eaf1a2e92c83b4cfb1b5c6bc452d214c1b7e77cdfd1c7




import hmac
h = hmac.new('alvin'.encode('utf8'))
h.update('hello'.encode('utf8'))
print (h.hexdigest())#320df9832eab4c038b6c1d7ed73a5940
