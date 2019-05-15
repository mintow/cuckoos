Redmine::Plugin.register :cuckoos do
  name 'Cuckoos plugin'
  author 'matteo duan'
  description 'This is a reminder plugin like cuckoos in the wall clock.
    It provides a ui for remind some users in some time according the due days.'
  version '0.1.0'
  url 'https://github.com/mintow/cuckoos'
  author_url ''
  requires_redmine version_or_higher: '3.4'

  menu :project_menu, :cuckoos, { :controller => 'cuckoos', :action => 'index' }, :caption => :cuckoo_menu_title, :before => :settings, :param => :project_id

  project_module :cuckoos do
    permission :manage_cuckoos, :cuckoos => [:index, :new, :create, :edit, :destroy, :send_now, :update, :update_trigger_points], :require => :member
  end
end
