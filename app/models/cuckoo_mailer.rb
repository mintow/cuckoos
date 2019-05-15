class CuckooMailer < ActionMailer::Base
  default from: Setting.mail_from
  layout 'mailer'
  include Redmine::I18n

  @@cuckoo_issue_ids = []
  @@running_by_task = false

  def self.task_start
    if @@cuckoo_issue_ids.length > 0
      @@cuckoo_issue_ids.clear
    end
    @@running_by_task = true
  end

  def self.task_end
    if @@cuckoo_issue_ids.length > 0
      @@cuckoo_issue_ids.clear
    end
    @@running_by_task = false
  end

  def self.issue_was_reminded(id)
    if @@running_by_task == false
      return false
    end

    @@cuckoo_issue_ids.each do |i|
      if i == id
        return true
      end
    end
    @@cuckoo_issue_ids.push(id)
    return false
  end

  def self.deal_one_issue_of_cuckoo(scope, cuckoo)
    puts "#{@@running_by_task} #{cuckoo.id} start: #{@@cuckoo_issue_ids}"
    scope.each do |issue|
      if CuckooMailer.issue_was_reminded(issue.id)
        puts "\t#{issue.id} was reminded - #{issue.subject}"
        next
      end

      cc = Array.new()
      to = Array.new()
      get_recipients(issue, cuckoo, to, cc)
      cc = cc.uniq - to.uniq
      send_one_issue(issue, to.uniq.join(','), cc.uniq.join(','), cuckoo.days).deliver
    end
    puts "#{@@running_by_task} #{cuckoo.id} end: #{@@cuckoo_issue_ids}"
  end

  def self.deal_package_issue_of_cuckoo(scope, cuckoo)
    to = Array.new()
    cc = Array.new()
    ids = Array.new()
    scope.each do |issue|
      get_recipients(issue, cuckoo, to, cc)
      ids.push(issue.id)
    end
    cc = cc.uniq - to.uniq
    send_package_issue(ids, to.uniq.join(','), cc.uniq.join(','), cuckoo).deliver
  end

  def self.send_one_cuckoo(scope, cuckoo)
    set_language_if_valid Setting.default_language

    if cuckoo.send_by_package
      deal_package_issue_of_cuckoo(scope, cuckoo)
    else
      deal_one_issue_of_cuckoo(scope, cuckoo)
    end
  end

  def send_one_issue(issue, to, cc, days)
    # Generate the mail subject
    s = "[#{issue.project.name} - "
    case days
    when days == 0
      s << t(:mail_subject_cuckoo_one_today_issue)
    when days == -1
      s << t('mail_subject_cuckoo_one_future_issue', days: 1)
    when days < -1
      s << t('mail_subject_cuckoo_one_future_issue2', days: (issue.due_date-Date.today).to_i)
    when days == 1
      s << t('mail_subject_cuckoo_one_issue', days: 1)
    else
      s << t('mail_subject_cuckoo_one_issue2', days: (Date.today-issue.due_date).to_i)
    end
    if issue.project.trackers.ids.size > 1
      s << "][#{issue.tracker.name}] "
    else
      s << "] "
    end
    s << "(#{issue.status.name}) "
    s << issue.subject

    get_host_port

    @author = issue.author
    @issue = issue
    @issue_url = url_for(:controller => 'issues', :action => 'show', :id => issue.id,
     :host => @host, :port => @port, :users => nil)
    @wiki_url = url_for(:controller => "wiki", :project_id => issue.project.id, :action => 'show',
      :host => @host, :port => @port, :users => nil)

    if recipients_is_empty(to, cc) == false
      mail :subject => s, :to => to, :cc => cc, :date => Time.zone.now
    end
  end

  def send_package_issue(ids, to, cc, cuckoo)
    # Generate the mail subject
    s = "[#{Project.find_by_id(cuckoo.project_id).name} - "
    if cuckoo.days == 0
      if ids.size == 1
        s << t('mail_subject_cuckoo_package_today_issue', count: 1)
      else
        s << t('mail_subject_cuckoo_package_today_issues', count: ids.size)
      end
    elsif cuckoo.days < 0
      if ids.size == 1 && cuckoo.days == -1
        s << t('mail_subject_cuckoo_package_future_issue1', count: 1, days: 1)
      elsif ids.size == 1 && cuckoo.days < -1
        s << t('mail_subject_cuckoo_package_future_issue2', count: 1, days: -cuckoo.days)
      elsif ids.size > 1 && cuckoo.days == -1
        s << t('mail_subject_cuckoo_package_future_issues1', count: ids.size, days: 1)
      else
        s << t('mail_subject_cuckoo_package_future_issues2', count: ids.size, days: -cuckoo.days)
      end
    else
      if ids.size == 1 && cuckoo.days == 1
        s << t('mail_subject_cuckoo_package_issue1', count: 1, days: 1)
      elsif ids.size == 1 && cuckoo.days > 1
        s << t('mail_subject_cuckoo_package_issue2', count: 1, days: cuckoo.days)
      elsif ids.size > 1 && cuckoo.days == 1
        s << t('mail_subject_cuckoo_package_issues1', count: ids.size, days: 1)
      else
        s << t('mail_subject_cuckoo_package_issues2', count: ids.size, days: cuckoo.days)
      end
    end
    s << "] #{cuckoo.email_tips}"

    get_host_port

    @project_id = cuckoo.project_id
    @ids = ids
    if recipients_is_empty(to, cc) == false
      mail :subject => s, :to => to, :cc => cc, :date => Time.zone.now
    end
  end

  def get_host_port()
    if Setting.host_name.to_s =~ /\A(https?\:\/\/)?(.+?)(\:(\d+))?(\/.+)?\z/i
      @host, @port = $2, $4
    end
  end

  def recipients_is_empty(to, cc)
    if to.size < 5
      if cc.size < 5
        return true
      else
        to = cc
        cc = nil
      end
    end
    return false
  end

  def self.get_custom_users(issue, cc)
    custom_user_values = issue.custom_field_values.select do |v|
      v.custom_field.field_format == 'user'
    end
    custom_user_ids    = custom_user_values.map(&:value).flatten
    custom_user_ids.reject! { |id| id.blank? }
    custom_user_ids.each do |id|
      cc.push(User.find_by_id(id).mail)
    end
  end

  def self.get_recipients(issue, cuckoo, to, cc)
    if cuckoo.sendto_assignee && issue.assigned_to_id != nil
      to.push(User.find_by_id(issue.assigned_to_id).mail)
    end
    if cuckoo.sendto_author
      cc.push(User.find_by_id(issue.author_id).mail)
    end
    if cuckoo.sendto_watcher && issue.notified_watchers.any?
      issue.notified_watchers.each do |w|
        cc.push(w.mail)
      end
    end
    if cuckoo.sendto_custom_user
      get_custom_users(issue, cc)
    end
    others = eval(cuckoo.other_users)
    if others.count > 1
      others.each do |i|
        cc.push(User.find_by_id(i).mail) if i.to_i > 0
      end
    end
  end

end
