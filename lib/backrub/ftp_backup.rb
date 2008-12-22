module Backrub
  module FtpBackup
    def do_the_backup(backup_source, backup_destination, ftp_backup_destination)
      FileUtils.mkpath(backup_destination)
      last_backup = Dir.list(backup_destination).sort.last
      puts("letztes backup-verzeichnis: #{last_backup}")
      today = Time.now.strftime('%Y-%m-%d-%H-%M')

      puts("öffne ftp verbindung")
      Net::FTP.open(FTP_HOST) do |ftp|
        ftp.login(FTP_USER, FTP_PASS)
        ftp.chdir(ftp_backup_destination)

        puts("wechsle in Ziel-Verzeichnis fuer heute")
        FileUtils.mkpath("#{backup_destination}/#{today}")
        FileUtils.chdir("#{backup_destination}/#{today}")
        ftp.mkdir(today)
        ftp.chdir(today)

        Dir.list(backup_source).each do |directory|
          yield("#{backup_source}/#{directory}", "#{backup_destination}/#{today}/#{directory}")

          puts("erstelle #{directory}.tar.gz")   
          system("tar cfz #{directory}.tar.gz #{directory}")

          puts("kopiere #{directory}.tar.gz auf ftp-server")
          ftp.putbinaryfile("#{directory}.tar.gz", "#{directory}.tar.gz", 1024)

          puts("lösche lokales archiv")
          system("rm #{directory}.tar.gz")
        end

        all_backup_dirs = Dir.list(backup_destination).sort
        if all_backup_dirs.length > KEEP_DAYS
          all_backup_dirs.sort[0,all_backup_dirs.length-KEEP_DAYS].each do |old_directory|
            puts("lösche altes backup verzeichnis #{backup_destination}/#{old_directory}")
            system("rm -rf #{backup_destination}/#{old_directory}")
          end
        end

        all_backup_dirs = ftp.nlst(ftp_backup_destination).sort
        if all_backup_dirs.length > KEEP_DAYS
          all_backup_dirs.sort[0,all_backup_dirs.length-KEEP_DAYS].each do |old_directory|
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
end