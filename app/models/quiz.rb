class Quiz < ApplicationRecord
  belongs_to :user, optional: true
  has_many :translations, dependent: :destroy
  has_many :favorite_quizzes, dependent: :destroy
  has_many :quiz_reports, dependent: :nullify

  belongs_to :from_lang, class_name: :Language, foreign_key: :from
  belongs_to :to_lang, class_name: :Language, foreign_key: :to

  accepts_nested_attributes_for :translations, allow_destroy: true, reject_if: proc { |t| t[:word].blank? || t[:translation].blank? }

  VISIBILITIES = %w[public private hidden].freeze

  validates :title, length: { minimum: 3, maximum: 255 }
  validates :description, length: { maximum: 30_000 }
  validates :visibility, inclusion: { in: VISIBILITIES }

  validate :validate_translations_count

  before_create do
    id_char_num = 5
    self.uuid = SecureRandom.base58(id_char_num)
    while Quiz.exists? uuid
      id_char_num += 1
      self.uuid = SecureRandom.base58(id_char_num)
    end
  end

  def self.search_quizzes(quiz_collection, params)
    title = ActiveRecord::Base.connection.quote_string params[:title] if params[:title].present?
    quizzes = if params[:title]
                quiz_collection.order(Arel.sql("SIMILARITY(title, '#{title}') DESC"))
              else
                quiz_collection
              end

    quizzes = case params[:sort]
              when "oldest"
                quizzes.order(created_at: :asc)
              when "most_translations"
                quizzes.order(translations_count: :desc)
              when "least_translations"
                quizzes.order(translations_count: :asc)
              else
                quizzes.order(created_at: :desc)
              end

    pages = quiz_collection.count.fdiv(50).ceil
    quizzes = quizzes.limit(50).offset(((params[:page] || 1).to_i - 1) * 50)
    [quizzes, pages]
  end

  def self.search_all_quizzes(params)
    Quiz.search_quizzes(Quiz.where(visibility: "public"), params)
  end

  def self.search_user_quizzes(user, params)
    Quiz.search_quizzes(user.quizzes, params)
  end

  def data(user)
    {
      id: uuid,
      title:,
      description:,
      visibility:,
      translations: translations.count,
      favorite: user.present? ? user.favorite_quiz?(self) : false,
      from: from_lang.as_json(except: %i[created_at updated_at]),
      to: to_lang.as_json(except: %i[created_at updated_at])
    }
  end

  def learn_data(user)
    if user.present?
      scores_to_create = translations.map do |translation|
        {
          user_id: user.id,
          translation_id: translation.id,
          word: translation.word,
          translation: translation.translation
        }
      end

      score_data = user.scores.where("translation.quiz_id": id).includes(:translation).map do |score|
        translation = score.translation
        scores_to_create -= [scores_to_create.find { |s| s[:translation_id] == translation.id }]

        {
          id: translation.id,
          score_id: score.id,
          word: translation.word,
          translation: translation.translation,
          favorite: score.favorite,
          score: score.as_json(only: %i[smart write multi cards])
        }
      end

      new_score_data = scores_to_create.map { |s| s.slice(:user_id, :translation_id) }
      new_score_ids = Score.insert_all(new_score_data) unless scores_to_create.empty?

      score_data += scores_to_create.each_with_index.map do |new_score, i|
        data = {
          id: new_score[:translation_id],
          score_id: new_score_ids[i]&.dig("id"),
          favorite: false,
          score: {
            smart: 0,
            write: 0,
            multi: 0,
            cards: 0
          }
        }
        new_score.slice(:word, :translation).merge(data)
      end
      score_data.sort_by { |s| s[:id] }
    else
      translations.sort_by(&:id).map { |t| { word: t.word, translation: t.translation } }
    end
  end

  def sync_score(sync_params, user)
    if sync_params[:favorite].present? && user.favorite_quiz?(self) != sync_params[:favorite]
      if sync_params[:favorite]
        user.favorite_quizzes.create quiz_id: id
      else
        user.favorite_quizzes.find_by(quiz_id: id)&.destroy
      end
    end

    sync_params = sync_params.to_h[:data].sort_by { |s| s[:score_id] }
    scores = Score.joins(:translation).where("translation.quiz_id": id, user_id: user.id).order(id: :asc)

    scores.each do |s|
      sync_score = sync_params.find { |p| p[:score_id] == s.id }
      next unless sync_score.present?

      update = sync_score[:updated].present? && s.updated_at.to_i < sync_score[:updated]
      next unless update

      s.update({
                 favorite: sync_score[:favorite],
                 smart: sync_score[:score][:smart],
                 multi: sync_score[:score][:multi],
                 cards: sync_score[:score][:cards],
                 write: sync_score[:score][:write]
               })
    end
  end

  def user_allowed_to_view?(user)
    return(visibility == "public" || visibility == "hidden") unless user.present?

    visibility == "public" || visibility == "hidden" ||
      self.user == user || user.admin?
  end

  def get_errors
    errors.full_messages
  end

  private

  def validate_translations_count
    errors.add(:translations, I18n.t("errors.not_enough_translations")) if translations.length.zero?
  end
end
