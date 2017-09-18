# coding: utf-8

# Copyright (C) 2010-2017 Íbúar ses / Citizens Foundation Iceland
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

require Rails.root.join("app","workers","counter.rb")

class CountingController < ApplicationController

#  after_filter :log_session_id

  def counting_info
    respond_to do |format|
      format.json { render :json => {:areas => BudgetBallotArea.all,
                                     area_voter_count: Vote.group(:area_id).distinct.count(:user_id_hash),
                                     total_voter_count: Vote.distinct.count(:user_id_hash) }}
    end
  end

  def start_counting
    BudgetConfig.first.update_attribute(:counting_progress, nil)
    CounterWorker.perform_async(params[:passphrase])
    respond_to do |format|
      format.json { render :json => {:ok => true }}
    end
  end

  def counting_progress
    respond_to do |format|
      format.json { render :json => BudgetConfig.first.counting_progress }
    end
  end

  def download_results_file
    send_file Rails.root.join("results", params[:filename])
  end


  def download_results_zip
    system "zip #{TEMP_ZIP_RESULTS_FILE} results/*"
    if File.exists?(TEMP_ZIP_RESULTS_FILE)
      send_file TEMP_ZIP_RESULTS_FILE, :type => 'application/zip', :filename=>"open_active_voting_results#{Time.now.strftime('%Y_%m_%d.%H_%M_%S')}.zip"
    else
      render :file=>"#{Rails.root}/public/404.html", :status=>404
    end
  end

  def clear_all_votes
    Vote.delete_all
    respond_to do |format|
      format.json { render :json => {:ok => true }}
    end
  end
end
