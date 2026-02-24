class FavoriteQuiz < ApplicationRecord
  belongs_to :user
  belongs_to :quiz

  validates_uniqueness_of :quiz_id, scope: :user_id
end
