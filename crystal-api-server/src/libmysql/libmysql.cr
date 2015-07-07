@[Link("mysqlclient")]
lib LibMySqlClient
  alias CChar = UInt8
  alias CUInt = UInt32
  alias CULong = UInt64
  alias CInt = Int32

  type MYSQL = Void*
  type MYSQL_RES = Void*
  type MYSQL_ROW = CChar**

  fun mysql_init(MYSQL) : MYSQL

  fun mysql_real_connect(MYSQL, host : CChar*, user : CChar*, passw : CChar*, db : CChar*, port : CUInt, unix_socket : CChar*, client_flag : CULong) : MYSQL
  fun mysql_error(MYSQL) : CChar*

  fun mysql_query(MYSQL, stmt_str : CChar*) : CInt

  fun mysql_use_result(MYSQL) : MYSQL_RES
  fun mysql_fetch_row(MYSQL_RES) : MYSQL_ROW
  fun mysql_num_fields(MYSQL_RES) : CUInt

  fun mysql_store_result(MYSQL) : MYSQL_RES
  fun mysql_fetch_lengths(MYSQL_RES) : CULong*


  fun mysql_free_result(MYSQL_RES) : Void
  fun mysql_close(MYSQL) : Void

end
