class CuckoosController < ApplicationController
  before_filter :find_project_by_project_id ,:authorize
  include CuckoosHelper

  def index
    @cuckoos = Cuckoo.where(project_id: @project.id)
  end

  def new
    @cuckoo = Cuckoo.new
    getUserOptions
    getTrackerOptions
  end

  def create
    @cuckoo = Cuckoo.new(:project_id => @project.id,
              :tracker_id => params[:item][:tracker_id].blank? ? 0 : params[:item][:tracker_id].to_i,
              :days => params[:cuckoo][:days],
              :sendto_author => params[:cuckoo][:sendto_author],
              :sendto_assignee => params[:cuckoo][:sendto_assignee],
              :sendto_watcher => params[:cuckoo][:sendto_watcher],
              :sendto_custom_user => params[:cuckoo][:sendto_custom_user],
              :trigger_cycle => params[:item][:trigger_cycle],
              :trigger_point => params[:item][:trigger_point],
              :send_by_package => params[:cuckoo][:send_by_package],
              :email_tips => params[:cuckoo][:email_tips],
              :env => Rails.env)

    if @cuckoo.days < 0
      @cuckoo.trigger_cycle = 'oneshot'
    end

    @cuckoo.other_users = params[:item][:other_users]
    if @cuckoo.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_cuckoos_path(:project_id => @project.id)
    else
      flash[:error] = l(:cuckoo_not_saved)
      Rails.logger.info(@cuckoo.errors.inspect)
      render new_project_cuckoos_path(:project_id => @project.id)
    end
  end

  def edit
    getUserOptions
    getTrackerOptions
    @cuckoo = Cuckoo.find(id = params[:cuckoo_id])
  end

  def update
    @cuckoo = Cuckoo.find(id = params[:id])
    @cuckoo.trigger_point = params[:item][:trigger_point]
    @cuckoo.other_users = params[:item][:other_users]
    @cuckoo.tracker_id = params[:item][:tracker_id].blank? ? 0 : params[:item][:tracker_id].to_i

    @cuckoo.days = params[:cuckoo][:days]
    if @cuckoo.days < 0
      @cuckoo.trigger_cycle = 'oneshot'
    else
      @cuckoo.trigger_cycle = params[:item][:trigger_cycle]
    end

    if @cuckoo.update_attributes(cuckoo_params)
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = l(:cuckoo_not_updated)
    end
    redirect_to project_cuckoos_path
  end

  def send_now
    @cuckoo = Cuckoo.find(params[:cuckoo_id])

    count = CuckoosController.process_one_cuckoo(@cuckoo, true)
    if count == 0
      flash[:notice] = l(:have_no_suitable_issue)
    else
      if count == 1
        flash[:notice] = l(:have_send_some_email, count: 1)
      else
        flash[:notice] = l(:have_send_some_emails, count: count)
      end
    end
    redirect_to project_cuckoos_path(:project_id => @project.id)
  end

  def self.process_one_cuckoo(cuckoo, rightnow=true)
    # Search the trackers
    scope = Issue.open.where(:project_id => cuckoo.project_id)
    if cuckoo.tracker_id != 0
      scope = scope.where(:tracker_id => cuckoo.tracker_id)
    end
    if scope.count == 0
      return 0
    end

    # trigger_cycle must be ‘oneshot' when days < 0.
    days = -cuckoo.days
    if cuckoo.trigger_cycle == 'oneshot' || days >= 0
      scope = scope.where("due_date = ?", days.day.from_now.to_date)
    else
      scope = scope.where("due_date <= ?", days.day.from_now.to_date)
    end
    if scope.count == 0
      return 0
    end

    if rightnow == false
      if cuckoo.trigger_cycle == "monthly" && cuckoo.trigger_point != Date.today.day
        return 0
      end
      if cuckoo.trigger_cycle == "weekly" && cuckoo.trigger_point != Date.today.wday
        return 0
      end
    end

    scope = scope.order('assigned_to_id').order('due_date')
    CuckooMailer.send_one_cuckoo(scope, cuckoo)
    if cuckoo.send_by_package
      return 1
    else
      return scope.count
    end
  end

  def update_trigger_points
    vals = Cuckoo.trigger_points_for(params[:trigger_cycle])
    if params[:cuckoo_id] == 'new'
      cuckoo = Cuckoo.new
    else
      cuckoo = Cuckoo.find(params[:cuckoo_id])
    end

    logger.warn "cuckoo_id: #{params[:cuckoo_id]}"
    logger.warn "trigger_cycle: #{params[:trigger_cycle]}"
    logger.warn "vals: #{vals}"
    logger.warn "cuckoo: #{cuckoo}"

    render :update do |page|
      page.replace_html "trigger_point-#{params[:cuckoo_id]}",
      :partial => 'trigger_points',
      :locals => { :possible_values => vals, :selected_value => cuckoo.trigger_point, :cuckoo => cuckoo}
    end
  end

  def destroy
    @cuckoo = Cuckoo.find(params[:id])

    if @cuckoo.destroy
      flash[:notice] = l(:notice_successful_delete)
      redirect_to project_cuckoos_path
    else
      flash[:error] = l(:cuckoo_not_removed)
      render project_cuckoos_path
    end
  end

  def getUserOptions
    project_member_ids = @project.users.collect{|u| u.id}

    @useroptions = Array.new
    project_member_ids.each do |project_member_id|
      user = User.find_by_id(project_member_id)
      name = user.name()
      @useroptions.push([name, project_member_id])
    end
  end

  def getTrackerOptions
    @trackeroptions = Tracker.where(:id => @project.trackers.ids).pluck(:name, :id)
  end

  def cuckoo_params
    # tracker_id, days, trigger_cycle, trigger_point, other_users mustn't be updated in this method.
    params.require(:cuckoo).permit(
                   :sendto_author, :sendto_assignee, :sendto_watcher, :sendto_custom_user,
                   :send_by_package, :email_tips)
  end
end
