# encoding: UTF-8

require 'helper/require_unit'
require 'siba-source-mysql/init'

describe Siba::Source::Mysql::Db do
  before do                    
    @cls = Siba::Source::Mysql::Db 
    mock_file :shell_ok?, true, [String]
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
  
  it "should call get_shell_parameters" do
    settings = {
      host: "myhost",
      port: "123",
      protocol: "myTCP",
      socket: "mysock",
      user: "uname",
      password: "my password"}
    @obj = @cls.new(settings)
    params = @obj.get_shell_parameters
    params = " "  + params
    params.must_include %( --host="myhost")
    params.must_include %( --port="123")
    params.must_include %( --protocol="myTCP")
    params.must_include %( --socket="mysock")
    params.must_include %( --user="uname")
    params.must_include %( --password="#{@cls::HIDE_PASSWORD_TEXT}")
    params.must_include %( --all-databases)
  end

  it "should espace for shell" do
    @obj = @cls.new({})
    @obj.escape_for_shell("hi\"").must_equal "hi\\\""
  end
end
