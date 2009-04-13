require 'aws/s3'
require 'date'
require 'digest'
require 'net/http'
require 'fileutils'

module AWS::S3
  class S3Object
    def <=>(other)
      DateTime.parse(self.about['last-modified']) <=> DateTime.parse(other.about['last-modified'])
    end
  end
end    

module EyBackup
  def self.get_from_ec2(thing="/")
    base_url = "http://169.254.169.254/latest/meta-data" + thing
    url = URI.parse(base_url)
    req = Net::HTTP::Get.new(url.path)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    res.body
  end
  class MysqlBackup
    def initialize(opts={})
      AWS::S3::Base.establish_connection!(
          :access_key_id     => opts[:aws_secret_id],
          :secret_access_key => opts[:aws_secret_key]
        )
      @dbuser = opts[:dbuser]
      @dbpass = opts[:dbpass]
      @databases = opts[:databases]
      @keep = opts[:keep]
      @bucket = "ey-backup-#{Digest::SHA1.hexdigest(opts[:aws_secret_id])[0..11]}"
      @tmpname = "#{Time.now.strftime("%Y-%m-%dT%H:%M:%S").gsub(/:/, '-')}.sql.gz"
      @id = EyBackup.get_from_ec2('/instance-id')
      FileUtils.mkdir_p '/mnt/tmp'
      begin
        AWS::S3::Bucket.create @bucket
      rescue AWS::S3::BucketAlreadyExists
      end  
    end
    
    def new_backup
      @databases.each do |db|
        backup_database(db)
      end  
    end
    
    def backup_database(database)
      mysqlcmd = "mysqldump -u #{@dbuser} -p'#{@dbpass}' #{database} | gzip - > /mnt/tmp/#{database}.#{@tmpname}"
      if system(mysqlcmd)
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
    
    def download(index)
      idx, db = index.split(":")
      obj =  list(db)[idx.to_i]
      puts "downloading: #{normalize_name(obj)}"
      File.open(normalize_name(obj), 'wb') do |f|
        print "."
        obj.value {|chunk| f.write chunk }
      end
      puts
      puts "finished"
      normalize_name(obj)
    end
    
    def restore(index)
      name = download(index)
      db = name.split('.').first
      cmd = "gunzip -c #{name} | mysql -u #{@dbuser} -p'#{@dbpass}' #{db}"
      if system(cmd)
        puts "successfully restored backup: #{name}"
      else
        puts "FAIL"
      end    
    end
    
    def cleanup
      list('all',false)[0...-(@keep*@databases.size)].each{|o| 
        puts "deleting: #{o.key}"  
        o.delete
      }
    end
    
    def normalize_name(obj)
      obj.key.gsub(/^.*?\//, '')
    end
    
    def list(database='all', printer = false)
      puts "listing #{database} database" if printer
      backups = []
      if database == 'all'
        @databases.each do |db|
          backups << AWS::S3::Bucket.objects(@bucket)
        end
        backups = backups.flatten.sort
      else  
        backups = AWS::S3::Bucket.objects(@bucket, :prefix => "#{@id}.#{database}").sort
      end
      if printer
        backups.each_with_index do |b,i|
          puts "#{i}:#{database} #{normalize_name(b)}"
        end
      end    
      backups
    end
    
  end
end