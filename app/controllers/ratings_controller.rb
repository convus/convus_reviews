class RatingsController < ApplicationController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: %i[index]
  before_action :redirect_to_signup_unless_user_present!, except: %i[new index]
  before_action :find_and_authorize_rating, only: %i[edit update destroy]
  helper_method :viewing_display_name

  def index
    if current_user.blank?
      if params[:user] == "current_user" || viewing_display_name == "following"
        redirect_to_signup_unless_user_present!
        return
      end
    end
    page = params[:page] || 1
    @per_page = params[:per_page] || 50
    @ratings = viewable_ratings.reorder("ratings.#{sort_column} #{sort_direction}")
      .includes(:citation, :user).page(page).per(@per_page)
    if params[:search_assign_topic].present?
      @assign_topic = Topic.friendly_find(params[:search_assign_topic])
    end
    @action_display_name = viewing_display_name.titleize
  end

  def new
    @source = params[:source].presence || "web"
    @no_layout = @source != "web"
    @rating ||= Rating.new(source: @source)
    if @source == "web"
      redirect_to_signup_unless_user_present!
    elsif @source == "turbo_stream"
      render layout: false
    end
  end

  def create
    @rating = Rating.new(permitted_create_params)
    @rating.user = current_user
    if @rating.save
      respond_to do |format|
        format.html do
          flash[:success] = "Rating added"
          redirect_source = (@rating.source == "web") ? nil : @rating.source
          redirect_to new_rating_path(source: redirect_source), status: :see_other
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(@rating, partial: "ratings/form", locals: {rating: @rating}) }
        format.html do
          flash.now[:error] = "Rating not created"
          render :new
        end
      end
    end
  end

  def edit
  end

  def update
    if @rating.update(permitted_params)
      flash[:success] = "Rating updated"
      redirect_to new_rating_path, status: :see_other
    else
      render :edit
    end
  end

  def add_topic
    included_rating_ids = params[:included_ratings].split(",").map(&:to_i)
    @assign_topic = Topic.friendly_find(params[:search_assign_topic])
    if @assign_topic.blank?
      flash[:error] = "Unable to find topic: '#{params[:search_assign_topic]}'"
    else
      ratings_updated = 0
      included_ratings = current_user.ratings.where(id: included_rating_ids)
      ratings_with_topic = RatingTopic.where(topic_id: @assign_topic.id, rating_id: included_ratings)
      # These are the ratings to add topic to
      included_ratings.where(id: rating_ids_selected - ratings_with_topic.pluck(:rating_id)).each do |rating|
        ratings_updated += 1
        rating.add_topic(@assign_topic)
      end
      ratings_with_topic.where.not(rating_id: rating_ids_selected).each do |rating_topic|
        ratings_updated += 1
        rating_topic.rating.remove_topic(@assign_topic)
      end
      # included_ratings
      if ratings_updated > 0
        flash[:success] = "Added to #{@assign_topic.name}"
      else
        flash[:notice] = "No ratings were updated"
      end
    end
    redirect_back(fallback_location: ratings_path(user: current_user), status: :see_other)
  end

  def destroy
    if @rating.destroy
      flash[:success] = "Rating deleted"
      redirect_to ratings_path, status: :see_other
    else
      flash[:error] = "Unable to delete rating!"
      redirect_to edit_rating_path(@rating), status: :see_other
    end
  end

  private

  def permitted_params
    params.require(:rating).permit(*permitted_attrs)
  end

  def permitted_create_params
    params.require(:rating).permit(*(permitted_attrs + [:timezone]))
  end

  def permitted_attrs
    %i[agreement changed_my_opinion citation_title did_not_understand
      error_quotes learned_something quality significant_factual_error
      source submitted_url topics_text]
  end

  def sortable_columns
    %w[created_at] # TODO: Add agreement and quality
  end

  def multi_user_searches
    %w[recent following]
  end

  def viewable_ratings
    if params[:user].blank? || multi_user_searches.include?(params[:user].downcase)
      @viewing_single_user = false
      @can_view_ratings = true
    else
      raise ActiveRecord::RecordNotFound if user_subject.blank?
      @viewing_single_user = true
      @viewing_current_user = user_subject == current_user
      @ratings_private = user_subject.ratings_private
      @can_view_ratings = user_subject.account_public || @viewing_current_user ||
        user_subject.follower_approved?(current_user)
    end
    searched_ratings
  end

  def viewing_display_name
    @viewing_display_name ||= if user_subject.present?
      user_subject.username
    else
      (params[:user] || multi_user_searches.first).downcase
    end
  end

  def searched_ratings
    ratings = if viewing_display_name == "following"
      current_user&.following_ratings_visible || Rating.none
    elsif viewing_display_name == "recent"
      Rating
    else
      @can_view_ratings ? user_subject.ratings : Rating.none
    end

    if current_topics.present?
      ratings = Rating.matching_topics(current_topics)
    end

    @time_range_column = "created_at"
    ratings.where(@time_range_column => @time_range)
  end

  def find_and_authorize_rating
    rating = current_user.ratings.where(id: params[:id]).first
    if rating.present?
      @rating = rating
    else
      flash[:error] = "Unable to find that rating"
      redirect_to(user_root_url) && return
    end
  end

  def rating_ids_selected
    params.keys.map do |k|
      next unless k.match?(/rating_id_\d/)
      k.gsub("rating_id_", "")
    end.compact.map(&:to_i)
  end
end
