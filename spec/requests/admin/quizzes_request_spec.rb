require "rails_helper"

base_url = "/admin/quizzes"
RSpec.describe base_url, type: :request do
  let(:citation) { FactoryBot.create(:citation) }
  let(:quiz) { FactoryBot.create(:quiz, citation: citation) }
  let(:valid_params) { {input_text: "some text", citation_id: citation.id} }

  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/quizzes"
    end
  end

  context "signed in" do
    include_context :logged_in_as_admin
    describe "index" do
      it "renders" do
        expect(quiz).to be_valid
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/quizzes/index")
        expect(assigns(:quizzes).pluck(:id)).to eq([quiz.id])
      end
    end

    describe "new" do
      it "redirects and flash errors" do
        get "#{base_url}/new"
        expect(flash[:error]).to be_present
      end
      context "with citation_id" do
        it "renders" do
          get "#{base_url}/new?citation_id=#{citation.url}"
          expect(response.code).to eq "200"
          expect(assigns(:citation)&.id).to eq citation.id
          expect(response).to render_template("admin/quizzes/new")
        end
      end
    end

    describe "create" do
      let(:citation) { FactoryBot.create(:citation) }
      it "creates" do
        expect {
          post base_url, params: {quiz: valid_params}
        }.to change(Quiz, :count).by 1
        expect(flash[:success]).to be_present
        new_quiz = Quiz.last
        expect_attrs_to_match_hash(new_quiz, valid_params)
        expect(new_quiz.status).to eq "pending"
      end
    end

    describe "show" do
      it "renders" do
        get "#{base_url}/#{quiz.id}"
        expect(response.code).to eq "200"
        expect(assigns(:quiz)&.id).to eq quiz.id
        expect(response).to render_template("admin/quizzes/show")
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{quiz.id}/edit"
        expect(response.code).to eq "200"
        expect(assigns(:quiz)&.id).to eq quiz.id
        expect(response).to render_template("admin/quizzes/edit")
      end
      context "id: citation slug" do
        it "renders" do
          expect(quiz).to be_valid
          get "#{base_url}/citation/edit?citation_id=#{citation.url}"
          expect(response.code).to eq "200"
          expect(assigns(:quiz)&.id).to eq quiz.id
          expect(response).to render_template("admin/quizzes/edit")
        end
      end
    end

    describe "update" do
      it "creates a new quiz" do
        expect(quiz).to be_valid
        expect {
          patch "#{base_url}/#{quiz.id}", params: {quiz: valid_params}
        }.to change(Quiz, :count).by 1
        expect(flash[:success]).to be_present

        new_quiz = Quiz.last
        expect_attrs_to_match_hash(new_quiz, valid_params)
        expect(new_quiz.status).to eq "pending"
        expect(new_quiz.version).to eq 2
      end
    end
  end
end
