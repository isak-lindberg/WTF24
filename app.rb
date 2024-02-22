require 'debug'

class App < Sinatra::Base
    enable :sessions
        def db
            if @db == nil
                @db = SQLite3::Database.new('./db/db.sqlite')
                @db.results_as_hash = true
            end
            return @db

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
            rating = params['rating'].to_i 
            query = 'INSERT INTO ratings (rating) VALUES (?) RETURNING id'
            result = db.execute(query, rating).first 
            # Att fixa nästa gång:
            # Varje unik användare måste kunna ha en egen rating av varje unik bok. Försök fixa detta. 
        end

        get '/books' do
            @books = db.execute('SELECT * FROM books;')
            erb :'books/books'
        end

        get '/books/:id' do |id|
            @book = db.execute('SELECT * FROM books WHERE id = ?', id).first
            erb :'books/show'
        end

    
end