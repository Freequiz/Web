module ApplicationHelper
  def notifications
    notifications = session[:notifications]
    session[:notifications] = nil
    notifications.present? ? notifications : nil
  end

  def action_hash
    "#{controller_name}##{action_name}"
  end

  def nav_class(hash)
    "nav-dropdown#{"-current" if action_hash == hash}"
  end
end
