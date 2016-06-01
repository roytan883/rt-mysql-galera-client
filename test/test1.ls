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

count = 0

#setInterval(!->
#  console.log("")
#  count += 1
#  thisCount = count
#  pool.query('select * from MyClass LIMIT 1', (error, results, fields) !->
#    console.log("out err = #{error}")
#    console.log("<<<<<<<< thisCount = ", thisCount)
#  )
#, 1000)

now = Date.now()

#此测试测试在添加60个新数据
#可以在此过程中关闭集群中的一台mysql服务器来测试60条数据有没有完整写入集群
setInterval(!->
  console.log("")
  count += 1
  thisCount = count
  sql = ""
  if thisCount <= 60
    sql = "insert into MyClass (name,sex,degree) values('#{now}-#{thisCount}',0,0)"
  else
    sql = "select count(*) from MyClass where name like '%#{now}%'"
  console.log(">>>>>>>> runCount = ", thisCount)
  pool.query(sql, (error, results, fields) !->
    console.log("out error = ", error)
    console.log("out results = ", results)
    console.log("<<<<<<<< runCount = ", thisCount)
  )
, 1000)