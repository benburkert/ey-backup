module EyBackup
  class PostgresqlBackup < MysqlBackup
    def backup_database(database)
      posgrecmd = "pg_dump --clean --no-owner --no-privileges -U#{@dbuser} -W'#{@dbpass}' #{database} | gzip - > /mnt/tmp/#{database}.#{@tmpname}"
      if system(posgrecmd)
        AWS::S3::S3Object.store(
           "/#{@id}.#{database}/#{database}.#{@tmpname}",
           open("/mnt/tmp/#{database}.#{@tmpname}"),
           @bucket,
           :access => :private
        )
        FileUtils.rm "/mnt/tmp/#{database}.#{@tmpname}"
        puts "successful backup: #{database}.#{@tmpname}"
      else
        raise "Unable to dump database#{database} wtf?"
      end
    end

    def restore(index)
      name = download(index)
      db = name.split('.').first
      cmd = "gunzip -c #{name} | psql -U#{@dbuser} -W'#{@dbpass}' #{db}"
      if system(cmd)
        puts "successfully restored backup: #{name}"
      else
        puts "FAIL"
      end    
    end
  end
end