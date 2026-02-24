namespace :db do
  desc "Creates a hash of all non rails tables"
  task hash: :environment do
    tables = [
      BannedIp,
      BlockedUserDatum,
      BugReport,
      FavoriteQuiz,
      Language,
      QuizReport,
      Quiz,
      Score,
      Setting,
      Transaction,
      Translation,
      User
    ]

    digest = Digest::SHA256.new

    tables.each do |table|
      table.all.each do |obj|
        digest << JSON.dump(obj.attributes)
      end
    end

    puts digest
  end
end
