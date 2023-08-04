class ApplicationController < ActionController::Base
  include TranzitoUtils::SetPeriod
  ESBUILD_ERROR_RENDERED = Rails.env.development?
  include RenderEsbuildErrors if ESBUILD_ERROR_RENDERED

  before_action do
    if Rails.env.production? && current_user.present?
      Honeybadger.context(user_id: current_user.id, user_email: current_user.email)
    end
  end

  around_action do |_, block|
    $prefab.with_context({user: {id: current_user&.id}}, &block)
  end

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :enable_rack_profiler

  helper_method :display_dev_info?, :user_subject, :user_root_url, :controller_namespace,
    :current_topics, :primary_topic_review, :default_direction, :default_column,
    :ratings_landing_url, :viewing_current_user?

  def append_info_to_payload(payload)
    super
    payload[:ip] = forwarded_ip_address
  end

  def forwarded_ip_address
    @forwarded_ip_address ||= ForwardedIpAddress.parse(request)
  end

  def enable_rack_profiler
    return false if !current_user&.developer? || Rails.env.test?
    Rack::MiniProfiler.authorize_request
  end

  def display_dev_info?
    return @display_dev_info if defined?(@display_dev_info)
    # Tie display_dev_info to the rack mini profiler display
    @display_dev_info = !Rails.env.test? && current_user&.developer? &&
      Rack::MiniProfiler.current.present?
  end

  def user_subject
    return @user_subject if defined?(@user_subject)
    user_param = params.permit(:user)[:user]
    @user_subject = if user_param == "current_user"
      current_user
    else
      User.friendly_find(user_param)
    end
  end

  def viewing_current_user?
    @viewing_current_user || (@user || user_subject)&.id == current_user&.id
  end

  def current_topics
    return @current_topics if defined?(@current_topics)
    # IDK a better way of handling permitting both string and array? This works...
    t_param = params.permit(:search_topics, search_topics: [])[:search_topics]
    @current_topics = if t_param.blank?
      []
    else
      arr = t_param
      arr = arr.split(/[\n,]/) unless arr.is_a?(Array)
      Topic.friendly_find_all(arr)
    end
  end

  def primary_topic_review
    return @primary_topic_review if defined?(@primary_topic_review)
    @primary_topic_review = TopicReview.primary
  end

  def ratings_landing_url
    ratings_url # In the future, probably have a user configurable option for this
  end

  def user_root_url
    return root_url if current_user.blank?
    root_url # TODO: make this something else
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || user_root_url
  end

  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource) || user_root_url
  end

  def default_direction
    "desc"
  end

  def default_column
    sortable_columns&.first
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
  end

  def redirect_to_signup_unless_user_present!
    if current_user.present?
      user_redirect_to = permitted_user_redirect_path(session.delete(:user_return_to))
      if user_redirect_to.present?
        redirect_to(user_redirect_to, status: :see_other)
        return
      end
      return current_user
    end
    store_return_to
    redirect_to new_user_session_path, status: :see_other
    false
  end

  def ensure_user_admin!
    if current_user.blank?
      redirect_to_signup_unless_user_present!
    elsif !current_user.admin?
      flash[:error] = "Not authorized"
      redirect_to user_root_url, status: :see_other
    end
  end

  def store_return_to
    return if request.xhr? || not_stored_paths.include?(request.path)
    # Don't overwrite existing unless it's for an admin path
    if session[:user_return_to].blank? || request.path.start_with?("/admin")
      session[:user_return_to] = request.fullpath
    end
    session[:user_return_to]
  end

  def not_stored_paths
    ["/", "/users/sign_in", "/users/sign_up", "/users/password", "/users/sign_out"]
  end

  # TODO: actually clean things.
  def permitted_user_redirect_path(path = nil)
    return nil if path.blank? || path.start_with?("/")
    path
  end

  def controller_namespace
    @controller_namespace ||= (self.class.module_parent.name != "Object") ? self.class.module_parent.name.downcase : nil
  end
end
