def connect_db(database)
    db = SQLite3::Database.new(database)
    db.results_as_hash = true
    return db
end