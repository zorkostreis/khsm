require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryGirl.create(:user, name: 'Ева') }
  let(:different_user) { FactoryGirl.create(:user, name: 'Дима') }

  before { assign(:user, user) }

  context "seeing user's name" do
    before { render }

    it "renders user's name" do
      expect(rendered).to match user.name
    end
  end

  context 'seeing change password link' do
    context 'when logged in' do
      context 'when on own profile page' do
        before do
          sign_in user
          render
        end

        it 'renders change password' do
          expect(rendered).to match 'Сменить имя и пароль'
        end
      end

      context 'when not on own profile page' do
        before do
          sign_in different_user
          render
        end

        it 'doesnt render change password' do
          expect(rendered).not_to match 'Сменить имя и пароль'
        end
      end
    end
    
    context 'when not logged in' do
      before { render }
      
      it 'doesnt render change password' do
        expect(rendered).not_to match 'Сменить имя и пароль'
      end
    end
  end

  context 'when user has games' do 
    before do
      assign(:games, [FactoryGirl.build_stubbed(:game)])
      stub_template 'users/_game.html.erb' => 'Игра'

      render
    end

    it "renders user's game" do
      expect(rendered).to have_content 'Игра'
    end
  end
end
