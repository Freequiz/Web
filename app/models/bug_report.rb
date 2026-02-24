class BugReport < ApplicationRecord
  belongs_to :user, optional: true

  STATUSES = %w[new open solved closed duplicate].freeze

  validates :title, length: { maximum: 255 }
  validates :body, length: { maximum: 30_000 }
  validates :status, inclusion: { in: BugReport::STATUSES }

  def get(field)
    self[field].present? ? self[field] : "Not defined"
  end

  def get_title
    get :title
  end

  def status_color
    BugReport.status_color status
  end

  def self.status_color(status)
    case status
    when "new"
      "bg-gray-50 dark:bg-gray-700"
    when "open"
      "bg-blue-600 text-white"
    when "solved"
      "bg-green-500 dark:bg-teal-700"
    else
      "bg-gray-100 dark:bg-gray-700"
    end
  end

  def status_buttons
    case status
    when "new"
      [
        %w[Open open],
        %w[Close closed],
        %w[Duplicate duplicate]
      ]
    when "open"
      [
        %w[Solved solved],
        %w[Close closed]
      ]
    else
      [%w[Reopen open]]
    end
  end

  def fields
    [
      ["Title", get_title],
      ["Created by", user.present? ? user.username : "Deleted user"],
      ["URL", get(:url)],
      ["Created from", get(:created_from)],
      ["Platform", get(:platform)],
      ["User agent", get(:user_agent)],
      ["IP", get(:ip)],
      ["Request method", get(:request_method)],
      ["Media type", get(:media_type)]
    ]
  end
end
