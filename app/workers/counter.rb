class CounterWorker
  include Sidekiq::Worker
    def perform
      # Starting vote counting
      Dir.mkdir("results") unless File.exists?("results")

      # Splitting user id hash and vote and generating final votes database tables
      Vote.split_and_generate_final_votes!

      BudgetBallotArea.all.each do |area, index|
        #puts "Counting votes for area: #{area.name}"
        counting_progress = { status: starting_area_count, areaName: area.name, index: index }
        BudgetBallot.update(:counting_progress, counting_progress.to_s)

        count  = BudgetVoteCounting.new(ENV['private_key'])
        count.count_unique_votes(area.id)

        # Writing unencrypted audit report
        count.write_counted_unencrypted_audit_report

        counting_progress = { status: completed_area_count, areaName: area.name, index: index }
        BudgetBallot.update(:counting_progress, counting_progress.to_s)
      end
      counting_progress = { status: all_completed }
      BudgetBallot.update(:counting_progress, counting_progress.to_s)
    end
end