import configparser
  
config = configparser.ConfigParser()
config["DEFAULT"] = {'ServerAliveInterval': '45',
                      'Compression': 'yes',
                     'CompressionLevel': '9'}
  
config['bitbucket.org'] = {}
config['bitbucket.org']['User'] = 'hg'
config['topsecret.server.com'] = {}
topsecret = config['topsecret.server.com']
topsecret['Host Port'] = '50022'     # mutates the parser
topsecret['ForwardX11'] = 'no'  # same here
config['DEFAULT']['ForwardX11'] = 'yes'<br>
with open('example.ini', 'w') as configfile:
   config.write(configfile)



'''
[DEFAULT]
ServerAliveInterval = 45
Compression = yes
CompressionLevel = 9
ForwardX11 = yes
  
[bitbucket.org]
User = hg
  
[topsecret.server.com]
Port = 50022
ForwardX11 = no
'''

####  增删改查
import configparser

config = configparser.ConfigParser()

#---------------------------------------------查
print(config.sections())   #[]

config.read('example.ini')

print(config.sections())   #['bitbucket.org', 'topsecret.server.com']

print('bytebong.com' in config)# False

print(config['bitbucket.org']['User']) # hg

print(config['DEFAULT']['Compression']) #yes

print(config['topsecret.server.com']['ForwardX11'])  #no


for key in config['bitbucket.org']:
    print(key)


# user
# serveraliveinterval
# compression
# compressionlevel
# forwardx11


print(config.options('bitbucket.org'))#['user', 'serveraliveinterval', 'compression', 'compressionlevel', 'forwardx11']
print(config.items('bitbucket.org'))  #[('serveraliveinterval', '45'), ('compression', 'yes'), ('compressionlevel', '9'), ('forwardx11', 'yes'), ('user', 'hg')]

print(config.get('bitbucket.org','compression'))#yes


