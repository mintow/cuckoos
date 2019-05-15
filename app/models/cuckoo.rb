require "date"

class Cuckoo < ActiveRecord::Base
  def self.cycles
    [:daily, :weekly, :monthly, :oneshot]
  end

  def self.weekly_cycle
    Date::DAYNAMES
  end

  def self.monthly_cycle
    (1..31).to_a
  end

  def self.trigger_points_for(interval)
    case interval.to_s.downcase
    when("daily")
      []
    when("weekly")
      weekly_cycle.enum_for(:each_with_index).collect {|val,idx| [trigger_point_display("weekly", val), idx]}
    when("monthly")
      monthly_cycle.enum_for(:each).collect {|val| [trigger_point_display("monthly", val), val]}
    when("oneshot")
      []
    else
      []
    end
  end

  def self.trigger_point_display(interval, value)
    case interval
    when("daily")
      []
    when("weekly")
      value = Date::DAYNAMES[value] if value.is_a? Integer
      l(:every_weekly_format) % l(value.downcase.to_sym)
    when("monthly")
      l(:every_of_month_format) % value
    when("oneshot")
      []
    else
      "Unknown"
    end
  end

  validates :project_id, :tracker_id, :days, :env, presence: true
end
