# encoding: UTF-8

module Siba::Source
  module Mysql                 
    class Db                 
      include Siba::FilePlug
      include Siba::LoggerPlug

      attr_accessor :options

      def initialize(options)
        @options = options

        if !@options[:tables].nil? && !@options[:tables].empty? && 
          (@options[:databases].nil? || (!@options[:databases].nil? && @options[:databases].size != 1))
          raise Siba::CheckError, "When 'tables' option is set there must be a single database specified in 'databases' option."
        end
      end
    end
  end
end
