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

        get '/' do
            erb :'books/index'
        end

        post '/new' do
            username = params['username']
            cleartext_password = params['cleartext_password'] 
            access = "user"
            password = BCrypt::Password.create(cleartext_password)
            query = 'INSERT INTO users (username, password, access) VALUES (?, ?, ?) RETURNING *'
            result = db.execute(query, username, password, access).first 
            redirect "/"
        end
    
        post '/login' do
            username = params['username']
            cleartext_password = params['cleartext_password'] 
    
            @user = db.execute('SELECT * FROM users WHERE username = ?', username).first

            password_from_db = BCrypt::Password.new(@user['password'])
    
            if password_from_db == cleartext_password 
                session[:user_id] = @user['id'] 
                redirect "/books"
            else
            redirect "/"
            end
            
        end

        post '/books/new' do 
            @user = db.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
            if @user['access'] == 'admin'
                name = params['name'] 
                description = params['description']
                query = 'INSERT INTO books (name, description) VALUES (?, ?) RETURNING *'
                result = db.execute(query, name, description).first 
                redirect "/books/#{result['id']}" 
            end
        end

        get '/books/:id/update' do |id|
            @book = db.execute('SELECT * FROM books WHERE id = ?', id).first
            @user = db.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
            erb :'books/update'
        end

        post '/books/:id/update' do |id|
            @user = db.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
            if @user['access'] == 'admin'
                book_name = params['name']
                book_description = params['description']
                db.execute('UPDATE books SET name = ?, description = ? WHERE id = ?', book_name, book_description, id)
                redirect "/books/#{id}" 
            end
        end

        post '/books/:id/delete' do |id|
            @user = db.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
            if @user['access'] == 'admin'
                db.execute('DELETE FROM books WHERE id = ?', id)
                redirect "/books"
            end
        end

        post '/books/:id/rate' do |id|
            score = params['score'].to_i
            @user = db.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
            unique_rating = db.execute('SELECT ratings.book_id, ratings.user_id FROM books INNER JOIN ratings ON ratings.book_id = books.id INNER JOIN users ON users.id = ratings.user_id WHERE books.id = ? AND ratings.user_id = ?', id, @user['id']).first
            if db.execute('SELECT ratings.book_id, ratings.user_id FROM books INNER JOIN ratings ON ratings.book_id = books.id INNER JOIN users ON users.id = ratings.user_id WHERE books.id = ? AND ratings.user_id = ?', id, @user['id']) == []
                if db.execute('SELECT * FROM books INNER JOIN ratings ON ratings.book_id = books.id WHERE ratings.user_id = ? AND ratings.book_id = ?', @user['id'], id) == []
                    db.execute('INSERT INTO ratings (score, book_id, user_id) VALUES (?, ?, ?)', score, id, @user['id'])
                end
            else
                db.execute('UPDATE ratings SET score = ? WHERE book_id = ? AND user_id = ?', score, unique_rating['book_id'], unique_rating['user_id'])
            end
            redirect "/books/#{id}"
        end

        get '/books' do
            @books = db.execute('SELECT * FROM books;')
            @user = db.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
            erb :'books/books'
        end

        get '/books/:id' do |id|
            @book = db.execute('SELECT * FROM books WHERE id = ?', id).first
            @user = db.execute('SELECT * FROM users WHERE id = ?', session[:user_id]).first
            @rating = db.execute('SELECT * FROM ratings INNER JOIN books ON books.id = ratings.book_id WHERE ratings.user_id = ? AND books.id = ?', @user['id'], id).first
            erb :'books/show'
        end


end