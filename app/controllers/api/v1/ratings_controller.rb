module API
  module V1
    class RatingsController < APIV1Controller
      before_action :ensure_current_user!

      def show
        rating = Rating.find_for_url(params[:url], current_user.id)
        render json: rating_serialized(rating)
      end

      def create
        pparams = permitted_params
        # I don't understand why this needs to be overridden, but otherwise it's ignored
        pparams[:citation_metadata_str] = params[:citation_metadata_str]
        rating = Rating.find_or_build_for(pparams.merge(skip_rating_created_event: true))
        if rating.save
          RatingCreatedEventJob.new.perform(rating.id, rating)
          share_msg = ShareFormatter.share_user(current_user.reload, rating.timezone)
          render json: {message: "Rating added", share: share_msg}
        else
          render(json: {message: rating.errors.full_messages}, status: 400)
        end
      end

      protected

      def rating_serialized(rating = nil)
        return {} unless rating.present?
        {
          agreement: rating.agreement,
          quality: rating.quality,
          changed_opinion: rating.changed_opinion,
          significant_factual_error: rating.significant_factual_error,
          error_quotes: rating.error_quotes,
          topics_text: rating.topics_text,
          citation_title: rating.citation_title,
          learned_something: rating.learned_something,
          not_understood: rating.not_understood,
          not_finished: rating.not_finished
        }
      end

      def permitted_params
        params.require(:rating)
          .permit(:agreement,
            :changed_opinion,
            :citation_metadata_str,
            :citation_title,
            :error_quotes,
            :learned_something,
            :not_finished,
            :not_understood,
            :quality,
            :significant_factual_error,
            :source,
            :submitted_url,
            :timezone,
            :topics_text)
          .merge(user_id: current_user.id)
      end
    end
  end
end
