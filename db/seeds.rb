# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

Language.create(
  [
    { id: 1, name: "german", locale: "de" },
    { id: 2, name: "french", locale: "fr" },
    { id: 3, name: "english", locale: "en" },
    { id: 4, name: "spanish", locale: "es" },
    { id: 5, name: "italian", locale: "it" },
    { id: 6, name: "latin", locale: "la" },
    { id: 7, name: "greek", locale: "el" },
    { id: 8, name: "romansh", locale: "rm" },
    { id: 9, name: "japanese", locale: "ja" },
    { id: 10, name: "korean", locale: "ko" },
    { id: 11, name: "chinese", locale: "zh" }
  ]
)

username_data = %w[freequiz admin moderator administrator administration]

username_data.each do |username|
  BlockedUserDatum.create(username:) unless BlockedUserDatum.exists? username:
end
