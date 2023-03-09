require "rails_helper"

base_url = "/reviews"
RSpec.describe base_url, type: :request do
  let(:full_params) do
    {
      submitted_url: "http://example.com",
      agreement: "disagree",
      quality: "quality_high",
      citation_title: "something",
      changed_my_opinion: "true",
      significant_factual_error: "1",
      error_quotes: "Quote goes here",
      topics_text: "A topic\n\nAnd another topic",
      source: "chrome_extension",
      timezone: "America/Bogota"
    }
  end
  let(:user_public) { FactoryBot.create(:user, reviews_public: true) }
  let(:user_private) { FactoryBot.create(:user, reviews_public: false) }

  describe "new" do
    it "redirects" do
      get "#{base_url}/new"
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "#{base_url}/new"
    end
    context "with source chrome" do
      it "renders without layout" do
        get "#{base_url}/new?source=chrome_extension"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/new")
        expect(response).to render_template("layouts/application")
      end
    end
  end

  context "index" do
    it "redirects" do
      get base_url
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq base_url
    end
    context "with private user" do
      it "renders" do
        expect(user_private.reviews_public).to be_falsey
        get "#{base_url}?user=#{user_private.username}"
        expect(response).to redirect_to new_user_registration_path
        expect(session[:user_return_to]).to eq "#{base_url}?user=#{user_private.username}"
      end
    end
    context "with public user" do
      it "renders" do
        expect(user_public.reviews_public).to be_truthy
        get "#{base_url}?user=#{user_public.username}"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/index")
        expect(assigns(:user_subject)&.id).to eq user_public.id
      end
    end
  end

  context "current_user present" do
    include_context :logged_in_as_user
    describe "new" do
      it "renders with layout" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/new")
        expect(response).to render_template("layouts/application")
        expect(assigns(:review).source).to eq "web"
        expect(assigns(:no_layout)).to be_falsey
      end
      context "source safari" do
        it "renders without layout" do
          get "#{base_url}/new?source=safari_extension", headers: {"HTTP_ORIGIN" => "*"}
          expect(response.code).to eq "200"
          expect(response).to render_template("reviews/new")
          expect(response).to render_template("layouts/application")
          expect(assigns(:review).source).to eq "safari_extension"
          expect(assigns(:no_layout)).to be_truthy
          # It doesn't do CORS
          expect(response.headers["access-control-allow-origin"]).to be_blank
        end
      end
      context "source turbo_stream" do
        it "renders without layout" do
          get "#{base_url}/new?source=turbo_stream"
          expect(response.code).to eq "200"
          expect(response).to render_template("reviews/new")
          expect(response).to_not render_template("layouts/application")
          expect(assigns(:review).source).to eq "turbo_stream"
          expect(assigns(:no_layout)).to be_truthy
        end
      end
    end

    describe "index" do
      it "redirects" do
        # This will be updated eventually to render somethiing
        get base_url
        expect(response).to redirect_to("#{base_url}?user=#{current_user.username}")
      end
      context "with current_user" do
        let!(:review1) { FactoryBot.create(:review) }
        let!(:review2) { FactoryBot.create(:review, user: current_user) }
        it "renders" do
          expect(current_user.reviews_private).to be_truthy
          get "#{base_url}?user=#{current_user.username}"
          expect(response.code).to eq "200"
          expect(response).to render_template("reviews/index")
          expect(assigns(:reviews).pluck(:id)).to eq([review2.id])
        end
      end
    end

    describe "create" do
      let(:create_params) do
        {
          submitted_url: "http://example.com",
          agreement: "agree",
          quality: "quality_low",
          source: "web"
        }
      end

      it "creates with basic params" do
        expect(Review.count).to eq 0
        expect {
          post base_url, params: {review: create_params}
        }.to change(Review, :count).by 1
        expect(response).to redirect_to(new_review_path)
        expect(flash[:success]).to be_present
        review = Review.last
        expect(review.user_id).to eq current_user.id
        expect_attrs_to_match_hash(review, create_params)
        expect(review.citation).to be_present
        expect(review.timezone).to be_blank
        expect(review.created_date).to eq Time.current.to_date
        citation = review.citation
        expect(citation.url).to eq "http://example.com"
        expect(citation.title).to be_blank
      end

      context "turbo_stream" do
        it "creates, not turbo_stream" do
          expect {
            post base_url, as: :turbo_stream, params: {review: create_params}
            expect(response.media_type).to_not eq Mime[:turbo_stream]
          }.to change(Review, :count).by 1
          expect(response).to redirect_to(new_review_path)
          review = Review.last
          expect_attrs_to_match_hash(review, create_params)
          expect(review.citation).to be_present
          citation = review.citation
          expect(citation.url).to eq "http://example.com"
          expect(citation.title).to be_blank
        end
        context "with error" do
          let(:error_params) { create_params.merge(submitted_url: "ERROR") }
          it "errors" do
            expect(Review.count).to eq 0
            expect {
              post base_url, as: :turbo_stream, params: {review: error_params}
              expect(response.media_type).to eq Mime[:turbo_stream]
            }.to change(Review, :count).by 0
            expect_attrs_to_match_hash(assigns(:review), error_params)
          end
        end
      end

      context "no csrf" do
        include_context :test_csrf_token
        it "succeeds" do
          expect(Review.count).to eq 0
          expect {
            post base_url, params: {review: create_params}, as: :turbo_stream
          }.to raise_error(/csrf/i)
          expect(Review.count).to eq 0
        end
      end

      context "full params" do
        let(:create_params) { full_params }
        it "creates with full params" do
          expect(Review.count).to eq 0

          expect {
            post base_url, params: {review: create_params.merge(user_id: 12111)}
          }.to change(Review, :count).by 1
          expect(response).to redirect_to(new_review_path(source: "chrome_extension"))
          expect(flash[:success]).to be_present
          review = Review.last
          expect(review.user_id).to eq current_user.id
          expect_attrs_to_match_hash(review, create_params)
          expect(review.timezone).to be_present
          expect(review.citation).to be_present
          citation = review.citation
          expect(citation.url).to eq "http://example.com"
          expect(citation.title).to eq "something"
        end
      end
    end

    describe "edit" do
      let(:review) { FactoryBot.create(:review, user: current_user) }
      it "renders" do
        get "#{base_url}/#{review.to_param}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("reviews/edit")
      end
      context "not user's" do
        let(:review) { FactoryBot.create(:review) }
        it "redirects" do
          expect(review.user_id).to_not eq current_user.id
          get "#{base_url}/#{review.to_param}/edit"
          expect(response).to redirect_to root_path
          expect(flash[:error]).to be_present
        end
      end
    end

    describe "update" do
      let(:review) { FactoryBot.create(:review, user: current_user) }
      let(:citation) { review.citation }
      it "updates" do
        expect(citation).to be_valid
        expect(review.reload.timezone).to be_blank
        expect {
          patch "#{base_url}/#{review.to_param}", params: {
            review: full_params
          }
        }.to_not change(Review, :count)
        expect(flash[:success]).to be_present
        review.reload
        expect_attrs_to_match_hash(review, full_params.except("timezone"))
        expect(review.timezone).to be_blank
        expect(review.citation_id).to_not eq citation.id
        expect(review.citation.url).to eq "http://example.com"
        expect(review.citation.title).to eq "something"
      end
      context "no csrf" do
        include_context :test_csrf_token
        it "fails" do
          expect(citation).to be_valid
          expect {
            patch "#{base_url}/#{review.to_param}", params: {
              review: full_params
            }
          }.to raise_error(/csrf/i)
          expect(review.reload.submitted_url).to_not eq full_params[:submitted_url]
        end
      end
    end

    describe "delete" do
      let(:review) { FactoryBot.create(:review, user: current_user) }
      let(:citation) { review.citation }
      it "updates" do
        expect(review.user_id).to eq current_user.id
        expect(citation).to be_valid
        expect(Citation.count).to eq 1
        expect {
          delete "#{base_url}/#{review.to_param}"
        }.to change(Review, :count).by(-1)
        expect(flash[:success]).to be_present
        expect(Citation.count).to eq 1
      end
      context "not users" do
        let!(:review) { FactoryBot.create(:review) }
        it "fails" do
          expect(review.user_id).to_not eq current_user.id
          expect(Review.count).to eq 1
          expect(Citation.count).to eq 1
          delete "#{base_url}/#{review.to_param}"
          expect(flash[:error]).to be_present
          expect(Review.count).to eq 1
          expect(Citation.count).to eq 1
        end
      end
    end
  end
end
