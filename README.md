# rt-mysql-galera-client
mariadb/mysql client support galera cluster High Availability

## Introduction
This is a node.js driver for mysql galera cluster, include those features:

* auto recover from mysql server crash or connection failure.
* provide high availability. If one mysql server crash at runtime, it will auto re-send mysql command to another host in galera cluster. So your won't lose any data or query failure.
  You need at least 2 hosts in galera cluster to enable high availability.
* use Round-Robin rule to send mysql command to galera cluster

## Install
```npm install --save rt-mysql-galera-client```

## Usage
```js
var MyGaleraClient = require('rt-mysql-galera-client');

//createPool = function(mysqlGaleraHostsArray, user, password, database)
pool = MyGaleraClient.createPool([
    {
     host: '192.168.1.221',
     port: 3306,
     connectionLimit: 2
    }, {
     host: '192.168.1.223',
     port: 3306,
     connectionLimit: 3
    }
], 'testuser', '123123', 'test1');
                                 
//pool.query(sql, function(error, results, fields)
pool.query("select count(*) from MyClass", function(error, results, fields){
    console.log("out error = ", error);
    console.log("out results = ", results);
});
```
