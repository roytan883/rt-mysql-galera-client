/**
 * User: Roy
 * Date: 2016/5/31
 * Time: 11:07
 */

mysql = require('mysql')
_ = require('lodash')

exp = (mysqlGaleraHostsArray, user, password, database) !->
  self = this
  self.poolCluster = poolCluster = mysql.createPoolCluster({
    canRetry:true
    removeNodeErrorCount:Number.MAX_VALUE
    restoreNodeTimeout: Number.MAX_VALUE
    defaultSelector:'RR'
  })
  console.log("[mysql galera] new poolCluster for DB:", database)
  for item in mysqlGaleraHostsArray
    console.log("[mysql galera] poolCluster.add hosts:", item)
    poolCluster.add({
      host: item.host
      port: item.port ? 3306
      user: user
      password: password
      database: database
      connectTimeout: 1000 * 3
      acquireTimeout: 1000 * 3
      waitForConnections: true
      connectionLimit: item.connectionLimit
      queueLimit: 300
    })

exp.prototype.query = (sqlString, values, callback) !->
  self = this
  inputArgs = []
  for item in &
    inputArgs.push(item)
  self.poolCluster.getConnection (err, connection) !->
    cb = inputArgs[inputArgs.length - 1]
    if _.isFunction(cb)
      inputArgs[inputArgs.length - 1] = (error, results, fields) !->
        connection.release()
        cb(error, results, fields)
    else
      inputArgs[inputArgs.length] = (error, results, fields) !->
        connection.release()
    connection.query.apply(connection, inputArgs)

createPool = (mysqlGaleraHostsArray, user, password, database) ->
  return new exp(mysqlGaleraHostsArray, user, password, database)

module.exports.createPool = createPool