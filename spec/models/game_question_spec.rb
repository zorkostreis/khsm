# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели игрового вопроса,
# в идеале весь наш функционал (все методы) должны быть протестированы.
RSpec.describe GameQuestion, type: :model do

  # задаем локальную переменную game_question, доступную во всех тестах этого сценария
  # она будет создана на фабрике заново для каждого блока it, где она вызывается
  let(:game_question) { FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3) }

  # группа тестов на игровое состояние объекта вопроса
  context 'game status' do
    # тест на правильную генерацию хэша с вариантами
    it 'correct .variants' do
      expect(game_question.variants).to eq({'a' => game_question.question.answer2,
                                            'b' => game_question.question.answer1,
                                            'c' => game_question.question.answer4,
                                            'd' => game_question.question.answer3})
    end

    it 'correct .answer_correct?' do
      # именно под буквой b в тесте мы спрятали указатель на верный ответ
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    it 'correct .level and .text delegates' do
      expect(game_question.text).to eq game_question.question.text
      expect(game_question.level).to eq game_question.question.level
    end
  end

  context 'before using helpers' do
    it 'doesnt include audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)
    end

    it 'doesnt include fifty_fifty' do
      expect(game_question.help_hash).not_to include(:fifty_fifty)
    end

    it 'doesnt include friend_call' do
      expect(game_question.help_hash).not_to include(:friend_call)
    end
  end
 
  describe '#audience_help' do
    let(:audience_help) { game_question.help_hash[:audience_help] }
    
    before { game_question.add_audience_help }

    it 'is included in help_hash' do
      expect(game_question.help_hash).to include(:audience_help)
    end

    it 'contains correct keys' do
      expect(audience_help.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  describe '#fifty_fifty' do
    let(:fifty_fifty) { game_question.help_hash[:fifty_fifty] }

    before { game_question.add_fifty_fifty }

    it 'is included in help_hash' do
      expect(game_question.help_hash).to include(:fifty_fifty)
    end

    it 'includes b' do
      expect(fifty_fifty).to include('b')
    end

    it 'has 2 strings' do
      expect(fifty_fifty.size).to eq 2
    end
  end

  describe '#friend_call' do
    let(:friend_call) { game_question.help_hash[:friend_call] }

    before { game_question.add_friend_call }

    it 'is included in help_hash' do
      expect(game_question.help_hash).to include(:friend_call)
    end

    it 'contains a string' do
      expect(friend_call).to be_a(String)
    end

    it 'contains A B C or D' do
      expect(friend_call).to match(/[ABCD]/)
    end
  end
 
  describe '#correct_answer_key' do
    it 'returns correct answer key (b)' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end
end
