# coding: utf-8

class CounterWorker
  include Sidekiq::Worker
    def perform(passphrase)
      # Starting vote counting
      I18n.locale = "is"

      Dir.mkdir("results") unless File.exist?("results")

      time_for_files = Time.now.strftime('%Y_%m_%d.%H_%M_%S')

      # Splitting user id hash and vote and generating final votes database tables
      Vote.split_and_generate_final_votes!

      completed_areas = []

      BudgetBallotArea.all.order(:id).each do |area, index|
        #puts "Counting votes for area: #{area.name}"
        counting_progress = { status: "starting_area_count", areaName: area.name, index: index }
        BudgetConfig.first.update_attribute(:counting_progress, counting_progress.to_json.to_s)

        sleep 1
        count  = BudgetVoteCounting.new(PRIVATE_KEY_PATH, passphrase, time_for_files)
        count.count_unique_votes(area.id)

        # Writing unencrypted audit report
        count.write_counted_unencrypted_audit_report

        completed_areas << counting_progress = { status: "completed_area_count", votes_count: count.votes_count,
                                                 counted_votes_count: count.counted_votes_count,
                                                 invalid_votes_count: count.invalid_votes_count,
                                                 areaName: area.name, areaId: area.id, index: index }
        BudgetConfig.first.update_attribute(:counting_progress, counting_progress.to_json.to_s)
        puts counting_progress.to_json
      end
      counting_progress = { status: "all_completed", time_for_files: time_for_files, completed_areas: completed_areas }.to_json
      BudgetConfig.first.update_attribute(:counting_progress, counting_progress.to_json.to_s)
      puts counting_progress.to_s
    end
end