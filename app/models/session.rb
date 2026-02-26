class Session < ApplicationRecord
  SESSION_ID_LENGTH = 64
  SESSION_TOKEN_LENGTH = 64

  belongs_to :user

  has_secure_password :session_token

  def expired?
    expires < Time.now
  end

  def self.authenticate(session_id, session_token, auth_for)
    session = Session.find_by(session_id:)&.authenticate_session_token(session_token)

    return false unless session.present?

    return false if session.expired?

    return false unless session.from == auth_for

    # Update updated_at to show last used
    session.touch

    session.user
  end

  def self.create_new_session(user, expires, from)
    session_id = SecureRandom.alphanumeric(SESSION_ID_LENGTH)
    session_token = SecureRandom.alphanumeric(SESSION_TOKEN_LENGTH)

    session = Session.new(
      session_id:,
      session_token:,
      user:,
      expires:,
      from:
    )

    raise "Could not create Session" unless session.save

    { session:, session_id:, session_token: }
  end
end
