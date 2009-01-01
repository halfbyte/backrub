require 'fileutils'
module Backrub
  class Rubber
    
    attr_reader :keep_days
    
    def self.execute(file)
      Rubber.new(file)
      #self.class_eval(File.read(file))
    end

    def initialize(file)
      instance_eval(File.read(file))
    end
    
    def dry_backrub(a,b,c,d)
      @keep_days = d
      @ftpsession = MockFTPSession.new(a,b,c)
      yield
      @ftpsession.close
    end
    
    def backrub(a,b,c,d = 3)
      @keep_days = d
      @ftpsession = FTPSession.new(a,b,c)
        yield
      @ftpsession.close
    end

    def ftp
      @ftpsession.ftp
    end
    
    def keep_days
      @keep_days
    end
    
    
    def cleanup_old_backups(dest, ftp_dest)
      
      # todo: allow for more complex keeping strategies. (like keeping versions from every week, month, year)
      
      all_backup_dirs = Dir.list(dest).sort
      if all_backup_dirs.length > self.keep_days
        all_backup_dirs.sort[0,all_backup_dirs.length-self.keep_days].each do |old_directory|
          puts("lösche altes backup verzeichnis #{dest}/#{old_directory}")
          system("rm -rf #{dest}/#{old_directory}")
        end
      end

      all_backup_dirs = ftp.nlst("#{ftp_dest}").sort
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
    
    def backup_subdirectories(src, dest, ftp_dest)
      ftp.chdir(ftp_dest)
      src_list = Dir.list(File.expand_path(src))
      dest = File.expand_path(dest)
      FileUtils.mkpath(dest)
      last_backup = Dir.list(dest).sort.last
      puts("letztes backup-verzeichnis: #{last_backup}")
      today = Time.now.strftime('%Y-%m-%d-%H-%M')
      
      FileUtils.mkpath("#{dest}/#{today}")
      FileUtils.chdir("#{dest}/#{today}")
      
      ftp.mkdir(today)
      
      ftp.chdir(today)
      src_list.each do |directory|
        puts "processing #{directory}"
        real_src = "#{src}/#{directory}"
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
      cleanup_old_backups(dest, ftp_dest)
      
    end

    def backup_directory(src, dest, ftp_dest)
      ftp.chdir(ftp_dest)
      src = File.expand_path(src)
      src_name = File.basename(src)
      dest = File.expand_path(dest)
      FileUtils.mkpath(dest)
      last_backup = Dir.list(dest).sort.last
      puts("letztes backup-verzeichnis: #{last_backup}")
      today = Time.now.strftime('%Y-%m-%d-%H-%M')
      
      FileUtils.mkpath("#{dest}/#{today}")
      FileUtils.chdir("#{dest}/#{today}")
      
      ftp.mkdir(today)
      ftp.chdir(today)
      
      puts "processing #{src}"
      
      real_dest = "#{dest}/#{today}"
      if block_given?
        yield src, real_dest
      else
        system("cp -r #{src} #{real_dest}/#{src_name}")
      end
        
      puts("erstelle #{src_name}.tar.gz")   
      system("tar cfz #{src_name}.tar.gz #{src_name}")
        
      puts("kopiere #{src_name}.tar.gz auf ftp-server")
      self.ftp.putbinaryfile("#{src_name}.tar.gz", "#{src_name}.tar.gz", 1024)
    
      puts("lösche lokales archiv")
      system("rm #{src_name}.tar.gz")
        
      cleanup_old_backups(dest, ftp_dest)
      
    end

    
    def backup_dumps(entries, dest, ftp_dest)      
      ftp.chdir(ftp_dest)            
      dest = File.expand_path(dest)
      FileUtils.mkpath(dest)
      
      last_backup = Dir.list(dest).sort.last
      puts("letztes backup-verzeichnis: #{last_backup}")
      today = Time.now.strftime('%Y-%m-%d-%H-%M')
      
      FileUtils.mkpath("#{dest}/#{today}")
      FileUtils.chdir("#{dest}/#{today}")
      
      ftp.mkdir(today)
      ftp.chdir(today)

      real_dest = "#{dest}/#{today}"
      

      entries.each do |entry|
        puts "processing #{entry}"
        
        dump_to_backup = ""
        
        if block_given?
          dump_to_backup = yield entry, real_dest
        else
          raise "backup_dumps should be called with a block"
        end
        
        system("gzip #{real_dest}/#{dump_to_backup}")
        
        puts("kopiere #{real_dest}/#{dump_to_backup}.gz auf ftp-server")
        self.ftp.putbinaryfile("#{real_dest}/#{dump_to_backup}.gz", "#{dump_to_backup}.gz", 1024)
                
      end
      cleanup_old_backups(dest, ftp_dest)
    end
  end
end