require 'net/ftp'
module Backrub
  class FTPSession
    attr_reader :ftp
    def initialize(host, user, password)
      @ftp = Net::FTP.open(host)
      @ftp.login(user, password)
    end
    
    
    
    def close
      @ftp.close
    end
  end
  
end