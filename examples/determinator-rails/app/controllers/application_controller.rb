class ApplicationController < ActionController::API
  def current_user
    # DETERMINATOR: This would return a User object in most applications
    # http://guides.rubyonrails.org/action_controller_overview.html#accessing-the-session
    nil
  end

  def guid
    session[:guid] ||= SecureRandom.uuid
  end

  def determinator
    # DETERMINATOR: A memoized instance of the ActorControl helper class
    # which allows simple use throughout the app
    @_determinator ||= Determinator.instance.for_actor(
      id: current_user && current_user.id || nil,
      guid: guid,
      default_properties: {
        # Clearly this would return real information about whether the
        # user is an employee.
        employee: false
      }
    )
  end
end
