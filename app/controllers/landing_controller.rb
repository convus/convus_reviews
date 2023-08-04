class LandingController < ApplicationController
  helper_method :viewable_ratings

  def index
    @page_title = "Convus"
    @ratings = Rating.joins(:citation).reorder("ratings.created_at desc")
      .includes(:user).page(1).per(render_count)
  end

  def about
  end

  def privacy
  end

  def browser_extensions
  end

  def browser_extension_auth
    redirect_to_signup_unless_user_present!
    @render_api_token = true
    @skip_ga = true # Skip Google analytics, this is a private page
  end

  def support
  end

  private

  def render_count
    $prefab.enabled?('more_ratings') ? 10 : 5
  end

  def viewable_ratings
    @viewable_ratings ||= Rating.joins(:citation)
  end
end
