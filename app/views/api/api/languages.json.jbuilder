json.success true
json.data do
  @languages.each do |lang|
    json.set! lang.id, name: lang.name, locale: lang.locale
  end
end
