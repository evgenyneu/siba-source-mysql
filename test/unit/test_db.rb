# encoding: UTF-8

require 'helper/require_unit'
require 'siba-source-mysql/init'

describe Siba::Source::Mysql::Db do
  before do                    
    @cls = Siba::Source::Mysql::Db 
    @fmock = mock_file :shell_ok?, true, [String]
  end

  it "should initialize" do
    options = {a: "b"}
    @obj = @cls.new options
    @obj.options.must_equal options
  end

  it "init should raise error when table are specified with no databases" do
    ->{@cls.new({tables: ["table"]})}.must_raise Siba::CheckError
  end

  it "init should raise error when table are specified with empty databases" do
    ->{@cls.new({tables: ["table"], databases: []})}.must_raise Siba::CheckError
  end

  it "init should raise error when table are specified with more than one database" do
    ->{@cls.new({tables: ["table"], databases: ["one", "two"]})}.must_raise Siba::CheckError
  end

  it "init should raise no error when table are specified with one database" do
    @cls.new({tables: ["table"], databases: ["one"]})
  end

  it "init should raise error if databases contain spaces" do
    ->{@cls.new({tables: ["table"], databases: ["with space"]})}.must_raise Siba::CheckError
  end

  it "init should raise error if tables contain spaces" do
    ->{@cls.new({tables: ["table1 table2"], databases: ["data"]})}.must_raise Siba::CheckError
  end

  it "init should raise error if ignore_tables contains spaces" do
    ->{@cls.new({ignore_tables: ["table1 table2"], databases: ["data"]})}.must_raise Siba::CheckError
  end

  it "should call db_and_table_names" do
    @obj = @cls.new({})
    @obj.db_and_table_names.must_equal " > all databases"

    @obj = @cls.new({databases: ["one"]})
    @obj.db_and_table_names.must_equal " > DB: one"

    @obj = @cls.new({databases: ["one", "two"]})
    @obj.db_and_table_names.must_equal " > DBs: one, two"


    @obj = @cls.new({tables: ["table"], databases: ["one"]})
    @obj.db_and_table_names.must_equal " > DB: one, table: table"

    @obj = @cls.new({tables: ["table1", "table2"], databases: ["one"]})
    @obj.db_and_table_names.must_equal " > DB: one, tables: table1, table2"
  end

  it "must call check_spaces_in_arrays" do
    @cls.check_spaces_in_arrays ["hi"], "name"
    @cls.check_spaces_in_arrays ["  hi  "], "name"
    @cls.check_spaces_in_arrays ["hi", "ho"], "name"
    @cls.check_spaces_in_arrays nil, "name"
    @cls.check_spaces_in_arrays [], "name"
  end

  it "check_spaces_in_arrays should fail" do
    ->{@cls.check_spaces_in_arrays ["with space"], "name"}.must_raise Siba::CheckError
    ->{@cls.check_spaces_in_arrays ["hi", "with space"], "name"}.must_raise Siba::CheckError
    ->{@cls.check_spaces_in_arrays ["hi", "with,comma"], "name"}.must_raise Siba::CheckError
    ->{@cls.check_spaces_in_arrays ["hi", "with, comma"], "name"}.must_raise Siba::CheckError
    ->{@cls.check_spaces_in_arrays ["hi", "with;comma"], "name"}.must_raise Siba::CheckError
  end
  
  it "should call get_mysqldump_params" do
    settings = {
      host: "myhost",
      port: "123",
      protocol: "myTCP",
      socket: "mysock",
      user: "uname",
      password: "my password"}
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( --host="myhost")
    params.must_include %( --port="123")
    params.must_include %( --protocol="myTCP")
    params.must_include %( --socket="mysock")
    params.must_include %( --user="uname")
    params.must_include %( --password="#{@cls::HIDE_PASSWORD_TEXT}")
    params.must_include %( --all-databases)
  end
  
  it "get_mysqldump_params should contain database" do
    settings = {
      databases: ["db1"]
    }
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( --databases db1)
    params.wont_include %( --all-databases)
  end

  it "get_mysqldump_params should contain databases" do
    settings = {
      databases: ["db1", "db2"]
    }
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( --databases db1 db2)
    params.wont_include %( --all-databases)
  end

  it "get_mysqldump_params should contain table" do
    settings = {
      databases: ["db1"],
      tables: ["table1"]
    }
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( --tables table1)
  end

  it "get_mysqldump_params should contain tables" do
    settings = {
      databases: ["db1"],
      tables: ["table1", "table2"]
    }
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( --tables table1 table2)
  end

  it "get_mysqldump_params should contain ignore-table" do
    settings = {
      ignore_tables: ["ig1","ig2"]
    }
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( --ignore-table=ig1)
    params.must_include %( --ignore-table=ig2)
  end

  it "get_mysqldump_params should contain databases" do
    settings = {
      databases: ["db1", "db2"]
    }
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( --databases db1 db2)
  end

  it "get_mysqldump_params should contain databases" do
    custom_text = "this is a cutom text"
    settings = {
      custom_parameters: custom_text
    }
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( #{custom_text})
  end

  it "get_mysqldump_params should escape double quotes" do
    settings = {
      user: %(user"name)
    }
    params = " " + @cls.new(settings).get_mysqldump_params
    params.must_include %( --user="user\\"name")
  end

  it "should call get_mysql_params" do
    settings = {
      host: "myhost",
      port: "123",
      protocol: "myTCP",
      socket: "mysock",
      user: "uname",
      password: "my password"}
    params = " " + @cls.new(settings).get_mysql_params
    params.must_include %( --host="myhost")
    params.must_include %( --port="123")
    params.must_include %( --protocol="myTCP")
    params.must_include %( --socket="mysock")
    params.must_include %( --user="uname")
    params.must_include %( --password="#{@cls::HIDE_PASSWORD_TEXT}")
    params.wont_include %( --all-databases)
  end

  it "should espace for shell" do
    @cls.escape_for_shell("hi\"").must_equal "hi\\\""
  end

  it "should call format_mysql_parameter" do
    @cls.format_mysql_parameter(:name,%(val"val)).must_equal %(--name="val\\"val")
    @cls.format_mysql_parameter(:password,%(pwd)).must_equal %(--password="#{@cls::HIDE_PASSWORD_TEXT}")
  end

  it "should run backup" do
    @fmock.expect :run_this, true, []
    @fmock.expect :dir_entries, [], [String]
    @fmock.expect :run_shell, nil, [String, String]
    @fmock.expect :file_file?, true, [String]
    @cls.new({}).backup "/dest/dir"
  end

  it "should run restore" do
    @fmock.expect :file_file?, true, [String]
    @fmock.expect :run_shell, nil, [String, String]
    @cls.new({}).restore "/from/dir"
  end
end
