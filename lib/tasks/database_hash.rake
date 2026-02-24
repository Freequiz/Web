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
      table_digest = Digest::SHA256.new

      table.order(id: :asc).all.each do |obj|
        text = JSON.dump(obj.attributes)
        digest << text
        table_digest << text
      end

      tab = table.to_s.length >= 11 ? "" : "\t"
      puts "Hashed #{table} with \t#{tab}#{table.count} entries: \t#{table_digest}"
    end

    puts "\nFinal digest: #{digest}"
  end
end
