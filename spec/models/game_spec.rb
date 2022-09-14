# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryGirl.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryGirl.create(:game_with_questions, user: user) }

  let(:question) { game_w_questions.current_game_question }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do

    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take_money! finishes game and replenishes user balance' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      game_w_questions.take_money!

      prize = game_w_questions.prize
      expect(prize).to be > 0

      expect(game_w_questions.status).to be :money
      expect(game_w_questions.finished?).to be_truthy
      expect(user.balance).to eq prize
    end
  end

  context '.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now

      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1

      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true

      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true

      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  describe '#current_game_question' do
    it 'returns correct current game question' do
      expect(game_w_questions.current_game_question).to eq game_w_questions.game_questions.first
    end
  end

  describe '#previous_level' do
    it 'returns correct previous level' do
      expect(game_w_questions.previous_level).to eq(game_w_questions.current_level - 1)
    end
  end

  describe '#answer_current_question!' do
    context 'user answers correctly' do
      context 'and it is not the last question' do
        let(:correcty_answered_game) do
          expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be(true)
          game_w_questions
        end

        it 'does not finish the game' do
          expect(correcty_answered_game.finished?).to be(false)
        end

        it 'moves game to the next level' do
          expect(correcty_answered_game.current_level).to be(1)
        end

        it '.status returns :in_progress' do
          expect(correcty_answered_game.status).to be(:in_progress)
        end
      end

      context 'and it is the last question' do
        let(:last_question_answered_game) do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max
          expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be(true)
          game_w_questions
        end

        it 'finishes the game' do
          expect(last_question_answered_game.finished?).to be(true)
        end

        it 'changes status to :won' do
          expect(last_question_answered_game.status).to be(:won)
        end

        it 'adds prize amount to user balance' do
          expect(user.balance).to eq(game_w_questions.prize)
        end
      end

      context 'but after timeout' do
        before { game_w_questions.created_at = 1.hour.ago }
  
        let(:late_answered_game) do
          expect(game_w_questions.answer_current_question!(question.correct_answer_key)).to be(false)
          game_w_questions
        end
  
        it 'finishes the game' do
          expect(late_answered_game.finished?).to be(true)
        end
  
        it 'changes status to :timeout' do
          expect(late_answered_game.status).to be(:timeout)
        end
      end
    end

    context 'user gives wrong answer' do
      let(:wrongly_answered_game) do
        expect(game_w_questions.answer_current_question!('e')).to be(false)
        game_w_questions
      end

      it 'finishes the game' do
        expect(wrongly_answered_game.finished?).to be(true)
      end

      it 'sets is_failed to true' do
        expect(wrongly_answered_game.is_failed).to be(true)
      end

      it 'changes status to :fail' do
        expect(wrongly_answered_game.status).to be(:fail)
      end
    end
  end
end
