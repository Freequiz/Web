class Language < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }
  validates :locale, uniqueness: { case_sensitive: false }
  validates_presence_of :name, :locale
end
