require 'debug'
require 'byebug'

class App < Sinatra::Base
    enable :sessions
        def db
            if @db == nil
                @db = SQLite3::Database.new('./db/db.sqlite')
                @db.results_as_hash = true
            end
            return @db
        end

        before do
            @current_user_id = 1
            @current_user_access = db.execute('SELECT access FROM users WHERE id = ?', @current_user_id).first
        end

        get '/' do
            erb :'books/index'
        end

        post '/books/new' do 
            name = params['name'] 
            description = params['description']
            query = 'INSERT INTO books (name, description) VALUES (?, ?) RETURNING *'
            result = db.execute(query, name, description).first 
            redirect "/books/#{result['id']}" 
        end

        get '/books/:id/update' do |id|
            @book = db.execute('SELECT * FROM books WHERE id = ?', id).first
            #binding.break
            erb :'books/update'
        end

        post '/books/:id/update' do |id| 
            book_name = params['name']
            book_description = params['description']
            db.execute('UPDATE books SET name = ?, description = ? WHERE id = ?', book_name, book_description, id)
            redirect "/books/#{id}" 
        end

        post '/books/:id/delete' do |id| 
            db.execute('DELETE FROM books WHERE id = ?', id)
            redirect "/books"
        end

        post '/books/:id/rate' do |id|
            # hämta rating för boken
            # kolla om rating är nil
            # isf insert rating
            # annars update rating
            score = params['score'].to_i
            unique_rating = db.execute('SELECT ratings.book_id, ratings.user_id FROM books INNER JOIN ratings ON ratings.book_id = books.id INNER JOIN users ON users.id = ratings.user_id WHERE books.id = ? AND ratings.user_id = ?', id, @current_user_id)
            if db.execute('SELECT ratings.book_id, ratings.user_id FROM books INNER JOIN ratings ON ratings.book_id = books.id INNER JOIN users ON users.id = ratings.user_id WHERE books.id = ? AND ratings.user_id = ?', id, @current_user_id) == []
                if db.execute('SELECT * FROM books INNER JOIN ratings ON ratings.book_id = books.id WHERE ratings.user_id = ? AND ratings.book_id = ?', @current_user_id, id) == []
                    db_execute('INSERT INTO ratings (score, book_id, user_id) VALUES (?, ?, ?)', score, id, @current_user_id)
                end
            else
                db.execute('UPDATE ratings SET score = ? WHERE book_id = ? AND user_id = ?', score, unique_rating['book_id'], unique_rating['user_id'])
            end
            redirect "/books/#{id}"
        end

        get '/books' do
            @books = db.execute('SELECT * FROM books;')
            erb :'books/books'
        end

        get '/books/:id' do |id|
            @book = db.execute('SELECT * FROM books WHERE id = ?', id).first
            @rating = db.execute('SELECT * FROM ratings INNER JOIN books ON books.id = ratings.book_id WHERE ratings.user_id = ? AND books.id = ?', @current_user_id, id).first
            erb :'books/show'
        end

    
end