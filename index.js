// Generated by LiveScript 1.4.0
/**
 * User: Roy
 * Date: 2016/5/31
 * Time: 11:07
 */
var mysql, _, exp, createPool;
mysql = require('mysql');
_ = require('lodash');
exp = function(mysqlGaleraHostsArray, user, password, database){
  var self, poolCluster, i$, len$, item, ref$;
  self = this;
  self.poolCluster = poolCluster = mysql.createPoolCluster({
    canRetry: true,
    defaultSelector: 'RR',
    restoreNodeTimeout: 1000 * 10,
    removeNodeErrorCount: 2
  });
  self.inputArgs = arguments;
  self.mysqlGaleraHostsArray = mysqlGaleraHostsArray;
  self.hostsCount = mysqlGaleraHostsArray.length;
  if (self.hostsCount < 2) {
    console.warn("[mysql galera] you should at least configure 2 galera hosts to enable High Availability !!!");
  }
  self.poolCluster.on('online', function(id){
    console.warn("[mysql galera] online: " + id);
  });
  self.poolCluster.on('offline', function(id){
    console.warn("[mysql galera] offline: " + id);
  });
  self.poolCluster.on('remove', function(id){
    console.warn("[mysql galera] remove: " + id);
  });
  console.warn("[mysql galera] new poolCluster for DB:", database);
  for (i$ = 0, len$ = mysqlGaleraHostsArray.length; i$ < len$; ++i$) {
    item = mysqlGaleraHostsArray[i$];
    console.warn("[mysql galera] poolCluster.add hosts:", item);
    poolCluster.add(item.host + ":" + item.port, {
      host: item.host,
      port: (ref$ = item.port) != null ? ref$ : 3306,
      user: user,
      password: password,
      database: database,
      connectTimeout: 1000 * 3,
      acquireTimeout: 1000 * 3,
      waitForConnections: true,
      connectionLimit: (ref$ = item.connectionLimit) != null ? ref$ : 5,
      queueLimit: 300
    });
  }
};
exp.prototype.query = function(sqlString, values, callback){
  var self, inputArgs, i$, len$, item;
  self = this;
  inputArgs = [];
  for (i$ = 0, len$ = arguments.length; i$ < len$; ++i$) {
    item = arguments[i$];
    inputArgs.push(item);
  }
  self.poolCluster.getConnection(function(err, connection){
    var cb;
    cb = inputArgs[inputArgs.length - 1];
    if (err) {
      console.error("[mysql galera] poolCluster.getConnection first err = ", err);
      if (self.hostsCount > 1) {
        console.error("[mysql galera] poolCluster.getConnection first has err, but hostsCount > 1, now try again");
        self._queryAgainOnError(inputArgs);
      } else {
        if (_.isFunction(cb)) {
          cb(err);
        }
      }
      return;
    }
    if (_.isFunction(cb)) {
      inputArgs[inputArgs.length - 1] = function(error, results, fields){
        connection.release();
        if (error && self.hostsCount > 1) {
          console.error("[mysql galera] poolCluster.getConnection first after query.apply error = ", error);
          console.error("[mysql galera] poolCluster.getConnection first after query.apply has error, but hostsCount > 1, now try again");
          inputArgs[inputArgs.length - 1] = cb;
          self._queryAgainOnError(inputArgs);
        } else {
          cb(error, results, fields);
        }
      };
    } else {
      inputArgs[inputArgs.length] = function(error, results, fields){
        connection.release();
        if (error && self.hostsCount > 1) {
          inputArgs[inputArgs.length - 1] = function(){};
          self._queryAgainOnError(inputArgs);
        }
      };
    }
    console.log("connection [" + connection.threadId + "][" + connection.config.host + "]");
    connection.query.apply(connection, inputArgs);
  });
};
exp.prototype._queryAgainOnError = function(inputArgs){
  var self;
  self = this;
  console.warn("[mysql galera] _queryAgainOnError");
  self.poolCluster.getConnection(function(err2, connection2){
    var cb2;
    cb2 = inputArgs[inputArgs.length - 1];
    if (_.isFunction(cb2)) {
      inputArgs[inputArgs.length - 1] = function(error, results, fields){
        connection2.release();
        cb2(error, results, fields);
      };
    } else {
      inputArgs[inputArgs.length] = function(error, results, fields){
        connection2.release();
      };
    }
    if (err2) {
      console.error("[mysql galera] _queryAgainOnError second err2 = ", err2);
      if (_.isFunction(cb2)) {
        return cb2(err2);
      }
    } else {
      console.log("connection2 [" + connection2.threadId + "][" + connection2.config.host + "]");
      connection2.query.apply(connection2, inputArgs);
    }
  });
};
createPool = function(mysqlGaleraHostsArray, user, password, database){
  return new exp(mysqlGaleraHostsArray, user, password, database);
};
module.exports.createPool = createPool;