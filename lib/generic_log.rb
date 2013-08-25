module CrudService
  class GenericLog
    def debug(str)
      puts "DEBUG: #{str}"
    end

    def info(str)
      puts "INFO: #{str}"
    end

    def warn(str)
      puts "WARN: #{str}"
    end

    def error(str)
      puts "ERROR: #{str}"
    end
  end
end