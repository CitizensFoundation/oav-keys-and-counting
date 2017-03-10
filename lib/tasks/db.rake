require 'fileutils'

namespace :db do

  desc "Dumps the database"
  task :dump_backup => :environment do
    cmd = nil
    tmpSqlFilename = nil
    path = "#{Rails.root}/Backups/sql"
    FileUtils.mkdir_p(path)
    with_config do |app, host, db, user, password|
      sqlConfig = "[mysqldump]\n"
      if host
        sqlConfig += "host=#{host}\n"
      end
      sqlConfig += "user=#{user}\n"
      sqlConfig += "password=#{password}\n"

      puts sqlConfig
      tmpSqlFilename = (0...20).map { (65 + rand(26)).chr }.join
      tmpSqlFilename = "/tmp/"+tmpSqlFilename
      puts tmpSqlFilename
      File.open(tmpSqlFilename, 'w') { |file| file.write(sqlConfig) }
      cmd = "mysqldump --defaults-extra-file=#{tmpSqlFilename} #{db} > #{path}/#{app}.#{db}-#{Time.now.to_f}.sql"
    end
    puts cmd
    exec cmd
    FileUtils.rm(tmpSqlFilename)
  end

  desc "Restores the database from default location"
  task :restore => :environment do
    cmd = nil
    filePath = "#{Rails.root}/Import/sql/current.sql"
    with_config do |app, host, db, user, password|
      hostText = host ? "--host="+host : ""
      cmd = "mysql -u #{user} #{hostText} --password=#{password} #{db} < #{filePath}"
    end
    puts "Before drop"
    Rake::Task["db:drop"].invoke

    puts "Before create"
    Rake::Task["db:create"].invoke

    puts cmd
    exec cmd
  end

  private

  def with_config
    yield Rails.application.class.parent_name.underscore,
        ActiveRecord::Base.connection_config[:host],
        ActiveRecord::Base.connection_config[:database],
        ActiveRecord::Base.connection_config[:username],
        ActiveRecord::Base.connection_config[:password]
  end

end