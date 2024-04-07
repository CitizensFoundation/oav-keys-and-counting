# coding: utf-8

# Copyright (C) 2010-2018 Íbúar ses / Citizens Foundation Iceland
# Authors Robert Bjarnason, Gunnar Grimsson, Gudny Maren Valsdottir & Alexander Mani Gautason
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'fileutils'

class KeysController < ApplicationController

  def create_public_private_key_pair
    puts "Request Content-Type: #{request.content_type}"
    puts "Request Method: #{request.method}"
    puts "Raw POST Body: #{request.raw_post}"
    puts "CHECKING PARAMS"
    # Parse raw_post as JSON
    begin
      parsed_body = JSON.parse(request.raw_post)
    rescue JSON::ParserError => e
      puts "Error parsing JSON: #{e}"
      puts "Raw POST Body: #{request.raw_post}"
      return render :json => {:error => "Error parsing JSON"}
    end

    puts parsed_body.inspect
    passphrase = parsed_body["passphrase"]
    puts passphrase
    # We write the passphrases to file so it is not displayed in the command line with ps auxf for example
    File.open(TEMP_PASSPHRASE_FILE_PATH, 'w') { |file| file.write(passphrase) }
    #puts params[:passphrase]
    puts MASTER_KEY_PAIR_PATH
    puts PRIVATE_KEY_PATH
    puts PUBLIC_KEY_PATH
    FileUtils.mkdir_p(MASTER_KEY_PAIR_PATH)
    output = ""
    puts output += `openssl genrsa -aes128 -out #{PRIVATE_KEY_PATH} -passout file:#{TEMP_PASSPHRASE_FILE_PATH} 2048`
    success_1 = $?.success?
    puts output += `openssl rsa -pubout -in #{PRIVATE_KEY_PATH} -passin file:#{TEMP_PASSPHRASE_FILE_PATH} -out #{PUBLIC_KEY_PATH}`
    success_2 = $?.success?

    FileUtils.rm(TEMP_PASSPHRASE_FILE_PATH)

    if success_1 and success_2
      unless BudgetConfig.first
        config=BudgetConfig.new
        config.timeout_in_seconds = 600
        config.save
      end
      config=BudgetConfig.first
      config.public_key = File.read(PUBLIC_KEY_PATH)
      config.save
    end

    respond_to do |format|
      format.json { render :json => {output: output, success_1: success_1, success_2: success_2 }}
    end
  end

  def change_passphrase
    # We write the passphrases to file so it is not displayed in the command line with ps auxf for example
    File.open(TEMP_PASSPHRASE_FILE_PATH, 'w') { |file| file.write(params[:passphrase]) }
    output = ""
    output += `openssl genpkey -algorithm RSA -out #{PRIVATE_KEY_PATH} -pkeyopt rsa_keygen_bits:2048 -passout file:tempPasswordFile.txt`
    success_1 = $?.success?
    output += `openssl rsa -pubout -in #{PRIVATE_KEY_PATH} -passin file:#{TEMP_PASSPHRASE_FILE_PATH} -out #{PUBLIC_KEY_PATH}`
    success_2 = $?.success?

    FileUtils.rm(TEMP_PASSPHRASE_FILE_PATH)

    if success_1 and success_2
      counting_progress = { status: 'keys_created'}
      BudgetBallot.update(:counting_progress, counting_progress.to_s)
    end

    respond_to do |format|
      format.json { render :json => {:counting_progress => BudgetConfig.first.counting_progress, output: output, success_1: success_1, success_2: success_2 }}
    end
  end

  def boot
    puts "BOOTING"

    boot_state = "unexpected"
    exception = nil
    public_key = nil

    begin
      vote_table_exists = ActiveRecord::Base.connection.table_exists? 'votes'
      config_table_exists = ActiveRecord::Base.connection.table_exists? 'config'
      has_tested_key_pair = File.exist?(KEY_PAIR_HAS_BEEN_TESTED_FILE)

      vote_count = (vote_table_exists and Vote.where.not(:saml_assertion_id=>nil).count) ? Vote.where.not(:saml_assertion_id=>nil).count : -1
      private_key_exists = File.exist?(PRIVATE_KEY_PATH)
      public_key = (config_table_exists and BudgetConfig.first and BudgetConfig.first.public_key)
      public_key_file_exists = File.exist?(PUBLIC_KEY_PATH)
      if vote_count>0 and private_key_exists and public_key
        boot_state = "counting"
      elsif config_table_exists and vote_table_exists and private_key_exists and public_key and has_tested_key_pair
        boot_state = "config"
      elsif config_table_exists and vote_table_exists and private_key_exists and public_key
        boot_state = "testKeyPair"
      elsif vote_count<1 and !private_key_exists and !public_key and vote_table_exists and config_table_exists
        boot_state = "createKeyPair"
      end
    rescue Exception => e
      exception = "#{e}"
    end

    puts boot_state

    respond_to do |format|
      format.json { render :json => {:boot_state => boot_state,
                                     :vote_count => vote_count,
                                     :private_key_exists => private_key_exists,
                                     :public_key => public_key,
                                     :public_key_file_exists => public_key_file_exists,
                                     :exception => exception,
                                     :counting_progress => (config_table_exists && BudgetConfig.first) ? BudgetConfig.first.counting_progress : nil }
      }
    end
  end

  def restore_sql
    filePath = "#{Rails.root}/Backups/sql/latest_for_import.sql"
    FileUtils.mkdir_p("#{Rails.root}/Backups/sql")
    File.open(filePath, "wb") { |f| f.write(params[:file].read) }
    system "rake db:restore_sql"

    respond_to do |format|
      format.json { render :json => {:ok => true} }
    end
  end

  def backup_and_reset
    begin
      vote_count = Vote.count
    rescue
      vote_count = -1
    end
    private_key_exists = File.exist?(PRIVATE_KEY_PATH)
    public_key_exists = File.exist?(PUBLIC_KEY_PATH)

    puts "Before dump backup"
    if vote_count>0 or public_key_exists
      system "rake db:dump_backup"
    end

    puts "Backup private and public keys"
    backupPath = "#{Rails.root}/Backups/master_key_pairs/#{Time.now.strftime('%Y_%m_%d.%H_%M_%S')}"
    FileUtils.mkdir_p(backupPath)

    if private_key_exists
      FileUtils.copy(PRIVATE_KEY_PATH, backupPath+"/private.key")
    end

    if public_key_exists
      FileUtils.copy(PUBLIC_KEY_PATH, backupPath+"/public.key")
    end

    puts "Backup results folder and reset it"
    results_root = "#{Rails.root}/results"
    backups_root = "#{Rails.root}/Backups/resultsAt"
    unless File.directory?(backups_root)
      FileUtils.mkdir_p(backups_root)
    end

    if File.directory?(results_root)
      FileUtils.mv(results_root, "#{backups_root}/#{Time.now.strftime('%Y_%m_%d.%H_%M_%S')}")
    end
    FileUtils.mkdir_p(results_root)

    ENV["DISABLE_DATABASE_ENVIRONMENT_CHECK"]="1"

    puts "Before drop"
    system "rake db:drop"

    puts "Before create"
    system "rake db:create"

    puts "Before load schema"
    system "rake db:schema:load"

    puts "Before recreating master key pair path"
    FileUtils.rm_rf(MASTER_KEY_PAIR_PATH)
    FileUtils.mkdir_p(MASTER_KEY_PAIR_PATH)

    respond_to do |format|
      format.json { render :json => {:ok => true} }
    end
  end

  def download_public_key_backup
    if File.exist?(PUBLIC_KEY_PATH)
      send_file PUBLIC_KEY_PATH, :filename=>"open_active_voting_#{Time.now.strftime('%Y_%m_%d.%H_%M_%S')}_public.key"
    else
      render :status => 404
    end
  end

  def download_private_key_backup
    if File.exist?(PRIVATE_KEY_PATH)
      send_file PRIVATE_KEY_PATH, :filename=>"open_active_voting_#{Time.now.strftime('%Y_%m_%d.%H_%M_%S')}_private.key"
    else
      render :status => 404
    end
  end

  def download_voting_database
    system "rake db:dump_backup_for_download"
    download_filename = Rails.root.join("Backups","sql","latest_for_download.sql")
    puts download_filename
    if File.exist?(download_filename)
      send_file download_filename, :filename=>"open_active_voting_database_with_public_key_#{Time.now.strftime('%Y_%m_%d.%H_%M_%S')}.sql"
    else
      render :file=>"#{Rails.root}/public/404.html", :status=>404
    end
  end

  def test_key_pair
    vote = Vote.new
    vote.payload_data = params[:text_to_decrypt]
    passphrase_error = false
    puts "PAYLOAD: #{vote.payload_data}"
    decrypted_text = nil
    begin
      helper = BudgetVoteHelper.new(vote.payload_data, PRIVATE_KEY_PATH, params[:passphrase], vote)
      decrypted_text = helper.unpack_text_only_for_testing
      decrypted_text.force_encoding('ISO-8859-1').encode('UTF-8') unless passphrase_error
    rescue OpenSSL::PKey::RSAError => e
      passphrase_error = true
    end

    unless passphrase_error
      File.open(KEY_PAIR_HAS_BEEN_TESTED_FILE, "wb") { |f| f.write("Test OK") }
    end

    puts "INFO"
    puts decrypted_text
    puts passphrase_error
    puts "END INFO"
    respond_to do |format|
      format.json { render :json => {:decrypted_text => decrypted_text, passphrase_error: passphrase_error} }
    end
  end

  private

end
