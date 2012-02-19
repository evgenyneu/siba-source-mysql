# encoding: UTF-8

module Siba::Source
  module Mysql                 
    class Db                 
      HIDE_PASSWORD_TEXT = "****p7d****"
      include Siba::FilePlug
      include Siba::LoggerPlug

      attr_accessor :options

      def initialize(options)
        @options = options

        if !tables.nil? && !tables.empty? && 
          (databases.nil? || (!databases.nil? && databases.size != 1))
          raise Siba::CheckError, "When 'tables' option is set there must be a single database specified in 'databases' option."
        end

        Siba::Source::Mysql::Db.check_spaces_in_arrays databases, 'databases'
        Siba::Source::Mysql::Db.check_spaces_in_arrays tables, 'tables'
        Siba::Source::Mysql::Db.check_spaces_in_arrays ignore_tables, 'ignore_tables'

        check_installed
      end

      def self.check_spaces_in_arrays(array, option_name)
        unless array.nil? || array.empty?
          array.each do |value|
            value.strip!
            if value.gsub(/[,;]/," ").split(" ").size > 1  
              raise Siba::CheckError, "'#{option_name}' value can not contain spaces or commas. If you need to specify multiple values please use YAML array sytax instead:
- one
- two
- three"
            end
          end
        end
      end

      def check_installed
        msg =  "utility is not found. Please make sure MySQL is installed and you have access to it."
        raise Siba::Error, "'mysqldump' #{msg}" unless siba_file.shell_ok? "mysqldump --help"
        raise Siba::Error, "'mysql' #{msg}" unless siba_file.shell_ok? "mysql --help"
        logger.debug "Mysql backup utilities verified"
      end

      def backup(dest_dir)
        siba_file.run_this do
          unless Siba::FileHelper.dir_empty? dest_dir
            raise Siba::Error, "Failed to backup MySQL: output directory is not empty: #{dest_dir}"
          end

          command_without_password = %(mysqldump -o "#{dest_dir}" #{get_shell_parameters})
          command = command_without_password
          unless settings[:password].nil?
            command = command_without_password.gsub HIDE_PASSWORD_TEXT, settings[:password]
          end
          output = siba_file.run_shell command, "failed to backup MongoDb: #{command_without_password}"
          raise Siba::Error, "failed to backup MongoDb: #{output}" if output =~ /ERROR:/

          if Siba::FileHelper.dir_empty?(dest_dir)
            raise Siba::Error, "Failed to backup MongoDB: dump directory is empty"
          end

          Siba::FileHelper.entries(dest_dir).each do |entry|
            path_to_collection = File.join dest_dir, entry
            next unless File.directory? path_to_collection
            if Siba::FileHelper.dir_empty? path_to_collection
              logger.warn "MongoDB collection/database name '#{entry}' is incorrect or it has no data."
            end
          end
        end
      end

      # def restore(from_dir)
      #   siba_file.run_this do
      #     if Siba::FileHelper.dirs_count(from_dir) == 0
      #       raise Siba::Error, "Failed to restore MongoDB: backup directory is empty: #{from_dir}"
      #     end

      #     unless settings[:database].nil?
      #       dirs = Siba::FileHelper.dirs from_dir
      #       if dirs.size != 1
      #         raise Siba::Error, "Dump should contain exactly one directory when restoring a single database"
      #       end
      #       from_dir = File.join from_dir, dirs[0]
      #     end

      #     command_without_password = %(mongorestore --drop #{get_shell_parameters} "#{from_dir}")
      #     command = command_without_password
      #     unless settings[:password].nil?
      #       command = command_without_password.gsub HIDE_PASSWORD_TEXT, settings[:password]
      #     end
      #     output = siba_file.run_shell command, "failed to restore MongoDb: #{command_without_password}"
      #     raise Siba::Error, "failed to restore MongoDb: #{output}" if output =~ /ERROR:/
      #   end
      # end

      def get_shell_parameters
        params = []
        OPTION_NAMES.each do |name|
          val = options[name]
          next if val.nil? && name != :databases
          if MULTIPLE_CHOISES.include? name
            case name
            when :databases
              if val.nil? || val.empty?
                params << "--all-databases" 
              else
                params << "--databases #{val.join(" ")}"  
              end
            when :tables
              params << "--tables #{val.join(" ")}"  
            when :ignore_tables
              val.each do |ignore_table|
                params << %(--ignore-table=#{ignore_table})
              end
            end
          elsif name == :custom_parameters
            params << val
          else
            val = HIDE_PASSWORD_TEXT if name == :password
            val = escape_for_shell val
            params << %(--#{name.to_s}="#{val}")
          end
        end
        params.join " "
      end

      def escape_for_shell(str)
        str.gsub "\"", "\\\""
      end

      def method_missing(meth, *args, &block)
        if method_defined? meth
          options[meth]
        else
          super
        end
      end

      def respond_to?(meth)
        if method_defined? meth
          true
        else
          super
        end
      end

      def method_defined?(meth)
        OPTION_NAMES.include? meth.to_sym
      end
      
      def db_and_table_names
        names = []
        unless databases.nil? || databases.empty?
          names << "DB#{databases.size > 1 ? "s": ""}: #{databases.join(", ")}" 
        else
          names << "all databases" 
        end

        unless tables.nil? || tables.empty?
          names << "table#{tables.size > 1 ? "s": ""}: #{tables.join(", ")}"
        end
        out = names.join(", ")
        out = " > " + out unless out.empty?
        out
      end
    end
  end
end
