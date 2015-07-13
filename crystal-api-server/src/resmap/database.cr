require "mysql"

class Database
  def initialize(config)
    @connection = MySql::Connection.new(config.fetch("host", "localhost") as String,
        (config.fetch("port", "3306") as String).to_u32,
        config.fetch("username") as String,
        config.fetch("password") as String)

    @connection.execute("USE #{config.fetch("database") as String}")
  end

  def make_default
    @@instance = self
  end

  def self.instance
    @@instance.not_nil!
  end

  def execute(sql)
    @connection.execute(sql) as MySql::ResultSet
  end
end
