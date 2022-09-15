require 'rails_helper'
require 'support/my_spec_helper' 

RSpec.describe GamesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:user, is_admin: true) }

  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }
  let(:question) { game_w_questions.current_game_question }
  let(:game) { assigns(:game) }

  describe '#show' do
    context 'when not logged in' do
      before { get :show, id: game_w_questions.id }

      it 'doesnt respond with 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirects to the sign in page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'displays alert flash' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before { sign_in user }

      context 'when opens his own game' do
        before { get :show, id: game_w_questions.id }

        it 'doesnt finish the game' do
          expect(game.finished?).to be false
        end

        it 'is created by the user' do
          expect(game.user).to eq(user)
        end

        it 'responds with status 200' do
          expect(response.status).to eq(200)
        end

        it 'renders show template' do
          expect(response).to render_template('show')
        end
      end

      context 'when opens alien game' do
        let(:alien_game) { FactoryGirl.create(:game_with_questions) }

        before { get :show, id: alien_game.id }

        it 'doesnt respond with status 200' do
          expect(response.status).not_to eq(200)
        end

        it 'redirects to main page' do
          expect(response).to redirect_to(root_path)
        end

        it 'displays alert flash' do
          expect(flash[:alert]).to be
        end
      end
    end
  end
  
  describe '#create' do
    context 'when not logged in' do
      before { post :create }

      it 'doesnt respond with status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirects to the sign in page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'displays alert flash' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before { sign_in user }

      context 'when creates a game' do
        before do
          generate_questions(15)
          post :create
        end
        
        it 'doesnt finish the game' do
          expect(game.finished?).to be false
        end

        it 'is created by the user' do
          expect(game.user).to eq(user)
        end

        it 'redirects to game page' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'dispays notice flash' do
          expect(flash[:notice]).to be
        end
      end

      context 'when tries to create second game' do
        before do
          expect(game_w_questions.finished?).to be false
          expect { post :create }.to change(Game, :count).by 0
        end

        it 'has nil in @game' do
          expect(game).to be_nil
        end

        it 'redirects to first game page' do
          expect(response).to redirect_to(game_path(game_w_questions))
        end

        it 'displays alert flash' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#answer' do
    context 'when not logged in' do
      before { put :answer, id: game_w_questions.id, letter: question.correct_answer_key }

      it 'doesnt respond with 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirects to the sign in page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'displays alert flash' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before { sign_in user }

      context 'when answer is correct' do
        before { put :answer, id: game_w_questions.id, letter: question.correct_answer_key }

        it 'doesnt finish the game' do
          expect(game.finished?).to be false
        end

        it 'moves to the next level' do
          expect(game.current_level).to be 1
        end

        it 'redirects to game page' do
          expect(response).to redirect_to(game_path(game))
        end

        it 'doesnt display flash' do
          expect(flash.empty?).to be true
        end
      end

      context 'when answer is wrong' do
        let(:wrong_answer) { (question.variants.keys - [question.correct_answer_key]).sample }

        before { put :answer, id: game_w_questions.id, letter: wrong_answer }

        it 'finishes the game' do 
          expect(game.finished?).to be true
        end
  
        it 'redirects to user profile page' do
          expect(response).to redirect_to user_path(user)
        end
  
        it 'displays alert flash' do
          expect(flash[:alert]).to be
        end
      end
    end
  end

  describe '#take_money' do
    context 'when not logged in' do
      before { put :take_money, id: game_w_questions.id; }
    
      it 'doesnt respond with status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirects to the sign in page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'displays alert flash' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before do
        sign_in user
        game_w_questions.update_attribute(:current_level, 2)
        put :take_money, id: game_w_questions.id
      end

      it 'finishes the game' do 
        expect(game.finished?).to be true
      end

      it 'sets won amount to the game prize' do
        expect(game.prize).to eq(Game::PRIZES.second)
      end

      it 'adds won amount to the user balance' do
        user.reload
        expect(user.balance).to eq(game.prize)
      end

      it 'redirects to user profile page' do
        expect(response).to redirect_to user_path(user)
      end

      it 'displays warning flash' do
        expect(flash[:warning]).to be
      end
    end
  end

  describe '#help' do
    context 'when not logged in' do
      before { put :help, id: game_w_questions.id, help_type: :audience_help }

      it 'doesnt respond with status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirects to the sign in page' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'displays alert flash' do
        expect(flash[:alert]).to be
      end
    end

    context 'when logged in' do
      before do
        sign_in user
        expect(question.help_hash[:audience_help]).not_to be
        expect(game_w_questions.audience_help_used).to be false
        put :help, id: game_w_questions.id, help_type: :audience_help
      end

      it 'doesnt finish the game' do
        expect(game.finished?).to be false
      end

      it 'sets audience_help_used to true' do
        expect(game.audience_help_used).to be true
      end

      it 'has right type help in help_hash' do
        expect(game.current_game_question.help_hash[:audience_help]).to be
      end
      
      it 'has correct keys in help_hash' do
        expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
      end

      it 'redirects to game page' do
        expect(response).to redirect_to(game_path(game))
      end
    end
  end
end
