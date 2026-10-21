#!/usr/bin/env python3
import sys,json
for line in sys.stdin:
    request=json.loads(line)
    for method,params in [('autohand.pipe.output',{'type':'progress','future':False}),('autohand.future',[1,None,False]),('autohand.future',None)]:
        print(json.dumps({'jsonrpc':'2.0','method':method,'params':params}),flush=True)
    print(json.dumps({'jsonrpc':'2.0','id':request['id'],'result':{'status':'idle'}}),flush=True)
