require 'fileutils'
module Backrub
  class Rubber
    def self.execute(file)
      self.class_eval(File.read(file))
    end
    
    def self.dry_backrub(a,b,c,d)
      @@keep_days = d
      @@ftpsession = MockFTPSession.new(a,b,c)
      yield
      @@ftpsession.close
    end
    
    def self.backrub(a,b,c,d = 3)
      @@keep_days = d
      @@ftpsession = FTPSession.new(a,b,c)
        yield
      @@ftpsession.close
    end

    def self.ftp
      @@ftpsession.ftp
    end
    
    def self.keep_days
      @@keep_days
    end
    
    def self.backup(src, dest, ftp_dest)
      
      self.ftp.chdir(ftp_dest)
      
      if src.is_a?(Array)
        src_list = src
      else
        src_list = Dir.list(File.expand_path(src))
      end
      
      dest = File.expand_path(dest)
      FileUtils.mkpath(dest)
      last_backup = Dir.list(dest).sort.last
      puts("letztes backup-verzeichnis: #{last_backup}")
      today = Time.now.strftime('%Y-%m-%d-%H-%M')
      
      FileUtils.mkpath("#{dest}/#{today}")
      FileUtils.chdir("#{dest}/#{today}")
      
      self.ftp.mkdir(today)
      self.ftp.chdir(today)
      
      src_list.each do |directory|
        puts "processing #{directory}"
        real_src = ""
        if (src.is_a?(Array))
          real_src = "#{directory}"
        else
          real_src = "#{src}/#{directory}"
        end
        real_dest = "#{dest}/#{today}/#{directory}"
        if block_given?
          yield real_src, real_dest
        else
          system("cp -r #{real_src} #{real_dest}")
        end
        
        puts("erstelle #{directory}.tar.gz")   
        system("tar cfz #{directory}.tar.gz #{directory}")
        
        puts("kopiere #{directory}.tar.gz auf ftp-server")
        self.ftp.putbinaryfile("#{directory}.tar.gz", "#{directory}.tar.gz", 1024)
        
        puts("lösche lokales archiv")
        system("rm #{directory}.tar.gz")
        
      end
      
      all_backup_dirs = Dir.list(dest).sort
      if all_backup_dirs.length > self.keep_days
        all_backup_dirs.sort[0,all_backup_dirs.length-self.keep_days].each do |old_directory|
          puts("lösche altes backup verzeichnis #{dest}/#{old_directory}")
          system("rm -rf #{dest}/#{old_directory}")
        end
      end

      all_backup_dirs = ftp.nlst(ftp_dest).sort
      if all_backup_dirs.length > self.keep_days
        all_backup_dirs.sort[0,all_backup_dirs.length-self.keep_days].each do |old_directory|
          puts("lösche altes backup verzeichnis #{old_directory}")
          ftp.nlst(old_directory).each do |file|
            ftp.delete(file)
          end
          ftp.rmdir(old_directory)
        end
      end
    end
  end
end