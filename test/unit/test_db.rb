# encoding: UTF-8

require 'helper/require_unit'
require 'siba-source-mysql/init'

describe Siba::Source::Mysql::Db do
  before do                    
    @cls = Siba::Source::Mysql::Db 
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
end
