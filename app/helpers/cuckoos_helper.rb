module CuckoosHelper
  def get_user_names(cuckoo_id)
    if Cuckoo.find_by_id(cuckoo_id).other_users == nil ||
       Cuckoo.find_by_id(cuckoo_id).other_users.size == 0
      return l(:user_none)
    end

    names = Array.new
    eval(Cuckoo.find_by_id(cuckoo_id).other_users).each do |user_id|
      if user_id == nil
        next
      end

      user = User.find_by_id(user_id.to_i)
      if user != nil
        names.push(user.name)
      end
    end

    if names.length == 0
      return l(:user_none)
    end

    return names
  end

  def get_tracker_name(tracker_id)
    tracker_id == 0 ? l(:tracker_all) : Tracker.find(tracker_id).name
    rescue ActiveRecord::RecordNotFound
    "##{tracker_id}"
  end

  def cycles_for_options
    Cuckoo.cycles.collect {|i| [l(i).capitalize, i.to_s]}
  end

  def get_point_name(cycle, point)
    if point == nil
      return ''
    end

    point_name = Cuckoo.trigger_point_display(cycle, point)
    if point_name.size == 0
      return ''
    else
      return point_name
    end
  end

  def get_cycle_name(cycle)
    case cycle
    when ("daily")
      l(:daily)
    when ("weekly")
      l(:weekly)
    when ("monthly")
      l(:monthly)
    else
      l(:oneshot)
    end
  end
end
