module Admin::UsersHelper
  def display_field(field)
    field.present? ? field : "Not defined"
  end
end
