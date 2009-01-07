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
      @keep = opts[:keep]
      @bucket = "ey-backup-#{Digest::SHA1.hexdigest(opts[:aws_secret_id])[0..11]}"
      @tmpname = "db.#{Date.today.to_s}.#{Time.now.to_i}.sql.gz"
      @id = EyBackup.get_from_ec2('/instance-id')
      FileUtils.mkdir_p '/mnt/tmp'
      begin
        AWS::S3::Bucket.create @bucket
      rescue AWS::S3::BucketAlreadyExists
      end  
    end
    
    def new_backup
      mysqlcmd = "mysqldump -u #{@dbuser} -p'#{@dbpass}' --all-databases | gzip - > /mnt/tmp/#{@tmpname}"
      if system(mysqlcmd)
        AWS::S3::S3Object.store(
           "/#{@id}/#{@tmpname}",
           open("/mnt/tmp/#{@tmpname}"),
           @bucket,
           :access => :private
        )
        FileUtils.rm "/mnt/tmp/#{@tmpname}"
        puts "successful backup: #{@tmpname}"
      else
        raise "Unable to dump databases wtf?"
      end    
    end
    
    def download(index)
      obj =  list[index]
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
      cmd = "gunzip -c #{name} | mysql -u #{@dbuser} -p'#{@dbpass}'"
      if system(cmd)
        puts "successfully restored backup: #{name}"
      else
        puts "FAIL"
      end    
    end
    
    def cleanup
      list[0...-@keep].each{|o| 
        puts "deleting: #{o.key}"  
        o.delete
      }
    end
    
    def normalize_name(obj)
      obj.key.gsub("#{@id}/", '')
    end
    
    def list(print = false)
      backups = AWS::S3::Bucket.objects(@bucket, :prefix => @id).sort
      if print
        backups.each_with_index do |b,i|
          puts "index: #{i} #{normalize_name(b)}"
        end
      end    
      backups
    end
    
  end
end