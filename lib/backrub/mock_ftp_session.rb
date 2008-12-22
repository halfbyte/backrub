module Backrub
  class MockFTPSession
    
    class Fake
      def method_missing(name, *params)
        puts "#{name} called"
      end
      
      def nlst(dest)
        puts "nlst called, returning empty array"
        []
      end
    end
    
    attr_reader :ftp
    def initialize(host, user, password)
      puts "faking login"
      @ftp = Fake.new
    end
    
    
    
    def fake?
      true
    end
    
    def close
      puts "faking ftp close"
      # @ftp.close
    end
  end
  
end