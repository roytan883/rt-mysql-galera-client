/**
 * User: Roy
 * Date: 2016/5/31
 * Time: 16:52
 */

MyGaleraClient = require('../index')

pool = MyGaleraClient.createPool([
  {host:'192.168.1.221', port:3306, connectionLimit:2},
  {host:'192.168.1.223', port:3306, connectionLimit:3}
  ],
  'testuser',
  '123123',
  'test1')

setInterval(!->
  console.log("")
  console.log(">>>>>>>>> ")
#  pool.query()
#  pool.query('select * from MyClass LIMIT 1')
#  pool.query(!->)

  pool.query('select * from MyClass LIMIT 1')
  pool.query('select * from MyClass LIMIT 1', "")
#  console.log(">>>>>>>>> ")
  pool.query('select * from MyClass LIMIT 1', (error, results, fields) !->
    console.log("out err = #{error}")
#    console.log("error = ", error)
    console.log("results = ", results)
#    console.log("<<<<<<<<<<")
#    console.log("")
  )
, 1000)