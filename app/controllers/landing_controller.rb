class LandingController < ApplicationController
  def index
    @page_title = "Convus"
  end

  def about
  end

  def privacy
  end

  def browser_extensions
  end

  def browser_extension_auth
    redirect_to_signup_unless_user_present!
    @skip_ga = true # Skip Google analytics, this is a private page
  end

  def support
  end
end
