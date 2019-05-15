namespace :redmine do
  desc <<-END_DESC
Process all the cuckoos sorted in .days descending order.
The bigger the .days is, the higger the priority is.

The task command:
  rake redmine:reminder_all_cuckoos RAILS_ENV="production"
END_DESC

  task reminder_all_cuckoos: :environment do
    CuckooMailer.task_start
    Cuckoo.order('days DESC').each do |r|
      CuckoosController.process_one_cuckoo(r, false)
      sleep 5
    end
    CuckooMailer.task_end
  end

end
