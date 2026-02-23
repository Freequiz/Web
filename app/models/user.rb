class User < ApplicationRecord
    has_secure_password

    has_one :setting, dependent: :destroy
    has_many :quizzes, dependent: :nullify
    has_many :scores, dependent: :destroy
    has_many :bug_reports, dependent: :nullify
    has_many :transactions, dependent: :nullify
    has_many :favorite_quizzes, dependent: :destroy
    has_many :get_favorite_quizzes, through: :favorite_quizzes, source: :quiz
    has_many :quiz_reports, dependent: :nullify

    ROLES = %w[user admin].freeze

    validates :username,
              uniqueness: {
                  case_sensitive: false
              },
              format: {
                  with: /\A[\w-]{3,16}\z/
              }
    validate :blocked_username_validation, unless: :admin?
    validates :role, inclusion: { in: ROLES }
    validates :email,
              uniqueness: {
                  case_sensitive: false
              },
              format: {
                  with: URI::MailTo::EMAIL_REGEXP
              }
    validates :password, format: { with: /\A(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{8,}\z/ }, allow_nil: true
    validates :agb, acceptance: true

    before_create do
        self.email = email.downcase
    end

    after_create do
        create_setting
        send_verification_email
    end

    def self.find_by_username_or_email(username_or_email)
        user = User.where("lower(username) = ?", username_or_email.downcase).first
        return user if user.present?

        User.find_by(email: username_or_email.downcase)
    end

    def favorite_quiz?(quiz)
        get_favorite_quizzes.exists?(quiz.id)
    end

    def admin?
        role == "admin"
    end

    def self.admins
        User.where(role: "admin")
    end

    def avatar_url
        seed = Digest::SHA1.hexdigest created_at.to_s
        "https://api.dicebear.com/8.x/shapes/svg?&seed=#{seed}"
    end

    def change(params)
        errors = []
        self.username = params[:username] if params[:username].present?

        email_changed = false
        if params[:email].present? &&
           params[:email].match?(URI::MailTo::EMAIL_REGEXP)
            user_with_email =
                User.find_by(email: params[:email]) ||
                User.find_by(unconfirmed_email: params[:email])

            if !user_with_email.present? || user_with_email == self
                if params[:email].present? && params[:email] != email
                    self.unconfirmed_email = params[:email]
                    email_changed = true
                    unless send_verification_email
                        self.unconfirmed_email = nil
                        email_changed = false
                    end
                elsif params[:email] == email && unconfirmed_email.present?
                    self.unconfirmed_email = nil
                end
            else
                errors.append(I18n.t("errors.email_in_use"))
            end
        elsif params[:email].present?
            errors.append(I18n.t("errors.email_invalid"))
        end

        if params[:password].present?
            self.password = params[:password]
            self.password_confirmation = params[:password_confirmation]
            self.password_challenge = params[:password_challenge]
        end

        save
        [email_changed, get_errors.concat(errors)]
    end

    def send_reset_password_email
        token = signed_id purpose: :reset_password, expires_in: 1.day
        UserMailer
            .with(email:, username:, token:)
            .password_reset_email
            .deliver_later
    end

    def send_verification_email
        if verified? &&
           (
               !unconfirmed_email.present? ||
                   unconfirmed_email == email
           )
            return false
        end

        token = signed_id purpose: :verify_email, expires_in: 7.days

        if verified? && unconfirmed_email.present?
            UserMailer
                .with(
                    email: unconfirmed_email,
                    username:,
                    token:
                )
                .verification_email
                .deliver_later
        else
            UserMailer
                .with(email:, username:, token:)
                .verification_email
                .deliver_later
        end
        true
    end

    def verified?
        confirmed
    end

    def banned?
        return false if admin?

        banned
    end

    def get_ban_reason
        ban_reason
    end

    def sign_in
        self.sign_in_count += 1

        self.last_sign_in_at = current_sign_in_at
        self.current_sign_in_at = Time.now

        save
    end

    def get_errors
        errors.full_messages
    end

    def bugs_smashed
        bug_reports.where(status: "solved").count
    end

    private

    def blocked_username_validation
        return unless BlockedUserDatum.username_blocked?(username) && !admin?

        errors.add(:username, I18n.t("activerecord.errors.models.user.attributes.username.blocked"))
    end
end
