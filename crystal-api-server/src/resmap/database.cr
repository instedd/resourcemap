# require "mysql"
#
# class Database
#   def initialize
#     @connection = MySql::Connection.new("localhost", 3306, "root", "")
#     execute "USE resource_map"
#   end

#   def execute(sql)
#     @connection.execute(sql)
#   end
# end

require "../libmysql"

class Database
  def initialize(config)
    @connection = LibMySqlClient.mysql_init(nil)
    LibMySqlClient.mysql_real_connect(@connection,
      config.fetch("host", "localhost") as String,
      config.fetch("username") as String, "",
      "resource_map",
      (config.fetch("port", "3306") as String).to_u32,
      nil, 0u64)
  end

  def make_default
    @@instance = self
  end

  def self.instance
    @@instance.not_nil!
  end

  def execute(sql)
    mysql_error LibMySqlClient.mysql_query(@connection, sql)
    ResultSet.new(self, @connection)
  end

  def finalize
    LibMySqlClient.mysql_close(@connection)
  end

  private def mysql_error(res)
    mysql_error(res.address)
  end

  private def mysql_error(res : Int)
    if res != 0
      raise_mysql_error
    end
  end

  def raise_mysql_error
    raise String.new(LibMySqlClient.mysql_error(@connection))
  end

  class ResultSet
    def initialize(@db, connection)
      @res = LibMySqlClient.mysql_use_result(connection);
    end

    def each_row
      num_fields = LibMySqlClient.mysql_num_fields(@res).to_i

      row = LibMySqlClient.mysql_fetch_row(@res)
      while row.address != 0
        lengths = Slice.new(LibMySqlClient.mysql_fetch_lengths(@res), num_fields)
        yield ResultRow.new(row, lengths)

        row = LibMySqlClient.mysql_fetch_row(@res)
      end

      LibMySqlClient.mysql_free_result(@res)
    end
  end

  class ResultRow
    def initialize(@row, @lengths)
    end

    def [](index)
      read_string(index)
    end

    def read_int(index)
      read_string(index).to_i
    end

    def read_string(index)
      String.new(@row[index] as UInt8*)
    end

    def read_binary(index)
      Slice.new(@row[index], @lengths[index].to_i)
    end
  end
end
