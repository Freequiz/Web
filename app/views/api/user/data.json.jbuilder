# {
#     "success": true,
#     "data": {
#         "username": "<%= @api_user.username %>",
#         "avatar_url": "<%= @api_user.avatar_url %>",
#         "email": "<%= @api_user.email %>",
#         "unconfirmed_email": "<%= @api_user.unconfirmed_email %>",
#         "role": "<%= @api_user.role %>",
#         "quizzes": <%= @api_user.quizzes.count %>,
#         "created_at": "<%= @api_user.created_at.to_i %>",
#         "updated_at": "<%= @api_user.updated_at.to_i %>",
#         "settings": <%= @settings.to_json.html_safe %>,
#         "confirmation": {
#             "confirmed": "<%= @api_user.confirmed %>",
#             "confirmed_at": "<%= @api_user.confirmed_at %>"
#         },
#         "logins": {
#             "count": "<%= @api_user.sign_in_count %>",
#             "current_login_at": "<%= @api_user.current_sign_in_at.to_i %>",
#             "last_login_at": "<%= @api_user.last_sign_in_at.to_i %>"
#         }
#     }
# }

json.success true
json.data do
  json.username @api_user.username
  json.avatar_url @api_user.avatar_url
  json.email @api_user.email
  json.unconfirmed_email @api_user.unconfirmed_email
  json.role @api_user.role
  json.quizzes @api_user.quizzes.count
  json.created_at @api_user.created_at.to_i
  json.updated_at @api_user.updated_at.to_i
  json.settings @settings
  json.confirmation do
    json.confirmed @api_user.confirmed
    json.confirmed_at @api_user.confirmed_at
  end
  json.logins do
    json.count @api_user.sign_in_count
    json.current_login_at @api_user.current_sign_in_at.to_i
    json.last_login_at @api_user.last_sign_in_at.to_i

    json.sessions @sessions do |session|
      json.purpose session.purpose
      json.expires session.expires.to_i
      json.last_activity session.updated_at.to_i
      json.current_session session.session_id == @active_session_id
      json.session_id session.session_id
    end
  end
end
