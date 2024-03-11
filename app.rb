require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'

enable :sessions


get('/') do
    slim(:login)
end

get('/error') do
    slim(:error)
end

get('/showregister') do
    slim(:register)
end

post('/login') do
    username = params[:username]
    password = params[:password]
  
    db = connect_db('db/hej.db')
    db.results_as_hash = true

    if password.empty? || username.empty?
        redirect('/error')
    end
  
    result = db.execute("SELECT * FROM user WHERE username = ?",username).first
    pwdigest = result["password"]
    id = result["id"]
    role = result["role"]

  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:role] = role
      redirect('/buildarmy')
    else
      redirect('/error')
    end
  end

  post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]

    if username.empty? || password.empty? || password_confirm.empty?
        redirect('/error')
    end
  
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = connect_db('db/hej.db')
      db.execute("INSERT INTO user (username,password,role) VALUES (?,?,0)",username,password_digest) #Lägga till värde på role
      redirect('/')
    else
      "Wrong Password"
    end
  end

get('/buildarmy') do
    db = connect_db('db/hej.db')
    @all_factions = db.execute("SELECT * FROM faction")
    slim(:army)
end


post('/buildarmy') do
    db = connect_db('db/hej.db')
    faction = params[:faction]
    imperium = params[:imperium]
    chaos = params[:chaos]
    necrons = params[:necrons]

    if faction == "imperium"
        db.execute('SELECT * FROM faction WHERE faction_id = 1')
        session[:faction] = 1
        # db.execute('SELECT * FROM army INNER JOIN unit ON army.unit_id = unit.unit_id')
    elsif faction == "chaos"
        db.execute('SELECT * FROM faction WHERE faction_id = 2')
        session[:faction] = 2
    elsif faction == "necrons"
        db.execute('SELECT * FROM faction WHERE faction_id = 3')
        session[:faction] = 3
    end
    redirect('/types')
end

get('/types') do
    db = connect_db('db/hej.db')
    @type_list = db.execute('SELECT * FROM type')
    slim(:types)
end

get('/units/:id') do
    db = connect_db('db/hej.db')
    button = params[:id]

    if session[:faction] == 1
        @unit_list = db.execute('SELECT * FROM unit WHERE faction_id = 1 AND type_id = ?',button)
    elsif session[:faction] == 2
        @unit_list = db.execute('SELECT * FROM unit WHERE faction_id = 2 AND type_id = ?',button)
    elsif session[:faction] == 3
        @unit_list = db.execute('SELECT * FROM unit WHERE faction_id = 3 AND type_id = ?',button)
    end
    # @unit_list = db.execute('SELECT * FROM unit WHERE type_id = ?',button,)
    slim(:units)
end

post('/units/:id') do
    db = connect_db('db/hej.db')
    button = params[:id]
    @unit_list = db.execute('INSERT INTO army (unit_id, user_id, amount) VALUES (?, 0, 0)',button) #Lägga till user_id
    
    redirect('/units/' + params[:id])
end

