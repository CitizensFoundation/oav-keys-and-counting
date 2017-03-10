require 'fileutils'

namespace :db do

  desc "Dumps the database"
  task :dump_backup => :environment do
    cmd = nil
    path = "#{Rails.root}/Backups/sql"
    FileUtils.mkdir_p(path)
    with_config do |app, host, db, user, password|
      cmd "mysqldump --opt --host=#{host} --user=#{user} --password #{password} #{db} > #{path}/#{app}.#{db}-#{Time.now.to_f}.sql"
    end
    puts cmd
    exec cmd
  end

  desc "Restores the database from default location"
  task :restore => :environment do
    cmd = nil
    filePath = "#{Rails.root}/Import/sql/current.sql"
    with_config do |app, host, db, user, password|
      cmd = "mysql -u #{user} --host=#{host} --password=#{password} #{db} < #{filePath}"
    end
    Rake::Task["db:drop"].invoke
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