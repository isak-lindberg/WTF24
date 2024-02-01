require 'sqlite3'

def db
    if @db == nil
        @db = SQLite3::Database.new('./db/db.sqlite')
        @db.results_as_hash = true
    end
    return @db
end

def drop_tables
    db.execute('DROP TABLE IF EXISTS books')
end

def create_tables
    db.execute('CREATE TABLE books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
    )')

end

def seed_tables

    books = [
        
    ]

    books.each do |book|
        db.execute('INSERT INTO books (name, description) VALUES (?,?)', book[:name], book[:description])
    end

end

drop_tables
create_tables
seed_tables