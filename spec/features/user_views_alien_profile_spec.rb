require 'rails_helper'

RSpec.feature "USER views someone else's profile", type: :feature do
  let(:current_user) { FactoryGirl.create :user, name: 'Ева' }
  let(:some_user) { FactoryGirl.create :user, name: 'Дима' }

  let!(:games) {[
    FactoryGirl.create(:game, user: some_user, created_at: Time.parse('2022.09.15, 13:00'), current_level: 10, prize: 1000),
    FactoryGirl.create(:game, user: some_user, created_at: Time.parse('2022.09.14, 11:00'),
     finished_at: Time.parse('2022.09.14, 11:15'), is_failed: true)
  ]}

  before { login_as current_user }

  scenario 'successfully' do
    visit '/'

    click_link some_user.name

    expect(page).to have_current_path '/users/1'

    expect(page).to have_content some_user.name
    expect(page).not_to have_content 'Сменить имя и пароль'

    expect(page).to have_content 'в процессе'
    expect(page).to have_content '15 сент., 13:00'
    expect(page).to have_content '50/50'
    expect(page).to have_content '1 000 ₽'
    expect(page).to have_content '10'

    expect(page).to have_content 'проигрыш'
    expect(page).to have_content '14 сент., 11:00'
    expect(page).to have_content '0 ₽'
  end
end
