# coding: utf-8

# Copyright (C) 2010-2016 Íbúar ses / Citizens Foundation Iceland
# Authors Robert Bjarnason, Gunnar Grimsson & Gudny Maren Valsdottir
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

MASTER_KEY_PAIR_PATH = Rails.root.join("master_key_pair")
PRIVATE_KEY_PATH =  Rails.root.join("master_key_pair","private.key")
PUBLIC_KEY_PATH = Rails.root.join("master_key_pair","public.key")
TEMP_PASSPHRASE_FILE_PATH = Rails.root.join("/tmp/tmpPassphrase")
TEMP_OLD_PASSPHRASE_FILE_PATH = Rails.root.join("/tmp/tmpOldPassphrase")

class KeysController < ApplicationController

  def create_public_private_key_pair
    # We write the passphrases to file so it is not displayed in the command line with ps auxf for example
    File.open(TEMP_PASSPHRASE_FILE_PATH, 'w') { |file| file.write(params[:passphrase]) }
    puts params[:passphrase]
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

    begin
      vote_count = Vote.count
      private_key_exists = File.exists?(PRIVATE_KEY_PATH)
      public_key_exists = (BudgetConfig.first and BudgetConfig.first.public_key) != nil
      public_key_file_exists = File.exists?(PUBLIC_KEY_PATH)

      if vote_count>0 and private_key_exists and public_key_exists
        boot_state = "counting"
      elsif private_key_exists and public_key_exists
        boot_state = "config"
      elsif vote_count==0 and !private_key_exists and !public_key_exists
        boot_state = "createKeyPair"
      end
    rescue Exception => e
      exception = "#{e}"
    end

    respond_to do |format|
      format.json { render :json => {:boot_state => boot_state,
                                     :vote_count => vote_count,
                                     :private_key_exists => private_key_exists,
                                     :public_key_exists => public_key_exists,
                                     :public_key_file_exists => public_key_file_exists,
                                     :exception => exception }
      }
    end
  end

  def backup_and_reset
    begin
      vote_count = Vote.count
    rescue
      vote_count = -1
    end
    private_key_exists = File.exists?(PRIVATE_KEY_PATH)
    public_key_exists = File.exists?(PUBLIC_KEY_PATH)

    puts "Before dump backup"
    if vote_count>0 or public_key_exists
      system "rake db:dump_backup"
    end

    puts "Backup private and public keys"
    backupPath = "#{Rails.root}/Backups/master_key_pairs/#{Time.now.to_f}"
    FileUtils.mkdir_p(backupPath)

    if private_key_exists
      FileUtils.copy(PRIVATE_KEY_PATH, backupPath+"/private.key")
    end

    if public_key_exists
      FileUtils.copy(PUBLIC_KEY_PATH, backupPath+"/public.key")
    end
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
    if File.exists?(PUBLIC_KEY_PATH)
      send_file PUBLIC_KEY_PATH, :filename=>"open_active_voting_#{Time.now.to_f}_public.key"
    else
      render :status => 404
    end
  end

  def download_private_key_backup
    if File.exists?(PRIVATE_KEY_PATH)
      send_file PRIVATE_KEY_PATH, :filename=>"open_active_voting_#{Time.now.to_f}_private.key"
    else
      render :status => 404
    end
  end

  private


  def download_public_key

  end

  def test_key_pair
    # Show back to user both encrypted and unecrypted
    # Dulkóðunarpartur kosningar tilbúin
  end

end
