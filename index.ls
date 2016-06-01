/**
 * User: Roy
 * Date: 2016/5/31
 * Time: 11:07
 */

mysql = require('mysql')
_ = require('lodash')

exp = (mysqlGaleraHostsArray, user, password, database) !->
  self = this
#  self.poolCluster = poolCluster = mysql.createPoolCluster()
  self.poolCluster = poolCluster = mysql.createPoolCluster({
    canRetry:true
    defaultSelector:'RR'
    #restoreNodeTimeout表示当一个host失效的时候，循环多久以后再次尝试使用该host
    #当设置为0的时候，表示失败以后立即移除该host，且再也不使用该host
    restoreNodeTimeout: 1000 * 10
    removeNodeErrorCount: 2
  })

  self.inputArgs = &
  self.mysqlGaleraHostsArray = mysqlGaleraHostsArray
  self.hostsCount = mysqlGaleraHostsArray.length

  if self.hostsCount < 2
    console.warn "[mysql galera] you should at least configure 2 galera hosts to enable High Availability !!!"

  self.poolCluster.on 'online' (id) !-> console.warn "[mysql galera] online: #{id}"
  self.poolCluster.on 'offline' (id) !-> console.warn "[mysql galera] offline: #{id}"
  self.poolCluster.on 'remove' (id) !-> console.warn "[mysql galera] remove: #{id}"

  console.warn("[mysql galera] new poolCluster for DB:", database)
  for item in mysqlGaleraHostsArray
    console.warn("[mysql galera] poolCluster.add hosts:", item)
    poolCluster.add("#{item.host}:#{item.port}", {
      host: item.host
      port: item.port ? 3306
      user: user
      password: password
      database: database
      connectTimeout: 1000 * 3
      acquireTimeout: 1000 * 3
      waitForConnections: true
      connectionLimit: item.connectionLimit ? 5
      queueLimit: 300
    })


exp.prototype.query = (sqlString, values, callback) !->
  self = this
  inputArgs = []
  for item in &
    inputArgs.push(item)

  self.poolCluster.getConnection (err, connection) !->
    cb = inputArgs[inputArgs.length - 1]

    if err
      console.error("[mysql galera] poolCluster.getConnection first err = ", err)
      if self.hostsCount > 1
        console.error("[mysql galera] poolCluster.getConnection first has err, but hostsCount > 1, now try again")
        self._queryAgainOnError(inputArgs)
      else
        if _.isFunction(cb) then cb(err)
      return

    if _.isFunction(cb)
      inputArgs[inputArgs.length - 1] = (error, results, fields) !->
        connection.release()
        if error and self.hostsCount > 1
          console.error("[mysql galera] poolCluster.getConnection first after query.apply error = ", error)
          console.error("[mysql galera] poolCluster.getConnection first after query.apply has error, but hostsCount > 1, now try again")
          inputArgs[inputArgs.length - 1] = cb
          self._queryAgainOnError(inputArgs)
        else
          cb(error, results, fields)
    else
      inputArgs[inputArgs.length] = (error, results, fields) !->
        connection.release()
        if error and self.hostsCount > 1
          inputArgs[inputArgs.length - 1] = !->
          self._queryAgainOnError(inputArgs)
    console.log("connection [#{connection.threadId}][#{connection.config.host}]")
    connection.query.apply(connection, inputArgs)

exp.prototype._queryAgainOnError = (inputArgs) !->
  self = this
  console.warn("[mysql galera] _queryAgainOnError")
  self.poolCluster.getConnection (err2, connection2) !->
    cb2 = inputArgs[inputArgs.length - 1]
    if _.isFunction(cb2)
      inputArgs[inputArgs.length - 1] = (error, results, fields) !->
        connection2.release()
        cb2(error, results, fields)
    else
      inputArgs[inputArgs.length] = (error, results, fields) !->
        connection2.release()
    if err2
      console.error("[mysql galera] _queryAgainOnError second err2 = ", err2)
      if _.isFunction(cb2) then return cb2(err2)
    else
      console.log("connection2 [#{connection2.threadId}][#{connection2.config.host}]")
      connection2.query.apply(connection2, inputArgs)

createPool = (mysqlGaleraHostsArray, user, password, database) ->
  return new exp(mysqlGaleraHostsArray, user, password, database)

module.exports.createPool = createPool