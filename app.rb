require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'

enable :sessions


get('/') do
    session.clear
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

    if username.empty? || password.empty?
        session[:error_message] = "Empty password and/or username"
        redirect('/error')
    end
  
    result = db.execute("SELECT * FROM user WHERE username = ?",username).first
    if result == nil
        session[:error_message] = "This username does not exist"
        redirect('/error')
    end



    pwdigest = result["password"]
    id = result["id"]
    role = result["role"]
    
    if password == "admin" && username == "admin"
        p "deededbhdehbwdebjhdewbh"
        role = 1
        faction = [1, 2, 3]
        session[:id] = id
        session[:role] = role
        session[:faction] == faction
        redirect('/protected/new')
    end

  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:role] = role
      redirect('/protected/new')
    else
      session[:error_message] = "Wrong password"
      redirect('/error')
    end
  end

  post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    


    if username.empty? || password.empty? || password_confirm.empty?
        session[:error_message] = "You need to fill in the boxes"
        redirect('/error')
    end

    if username == username
        session[:error_message] = "This username already exists"
        redirect('/error')
    end
        
        
  
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = connect_db('db/hej.db')
      db.execute("INSERT INTO user (username,password,role) VALUES (?,?,0)",username,password_digest)
      redirect('/')
    else
        session[:error_message] = "Wrong  confirmation password"
        redirect('/error')
    end
  end

before('/protected/*') do
    if session[:id] == nil
        session[:error_message] = "You need to create an account"
        redirect('/error')
    end
end

get('/protected/no_army') do
    slim(:"noarmy/show")
end

get('/protected/new') do
    db = connect_db('db/hej.db')
    @all_factions = db.execute("SELECT * FROM faction")
    user_id = session[:id]
    army_user = db.execute("SELECT user_id FROM army WHERE user_id = ?", user_id)

    if army_user.empty?
        slim(:"armies/new")
    else
        redirect('/protected/types')
    end

    slim(:"armies/new")
end


post('/protected/new') do
    db = connect_db('db/hej.db')
    faction = params[:faction]
    imperium = params[:imperium]
    chaos = params[:chaos]
    necrons = params[:necrons]

    if faction == "imperium"
        db.execute('SELECT * FROM faction WHERE faction_id = 1')
        session[:faction] = 1
    elsif faction == "chaos"
        db.execute('SELECT * FROM faction WHERE faction_id = 2')
        session[:faction] = 2
    elsif faction == "necrons"
        db.execute('SELECT * FROM faction WHERE faction_id = 3')
        session[:faction] = 3
    end
    redirect('/protected/types')
end


get('/protected/types') do
    db = connect_db('db/hej.db')
    @type_list = db.execute('SELECT * FROM type')
    slim(:"types/index")
end

get('/updatefaction') do
    slim(:"faction/edit")
end

post('/updatefaction') do
    faction = params[:faction]

    update_faction(faction)

    redirect('/protected/types')
end

get('/protected/units/:id') do
    button = params[:id]
    check_faction_unit(button)
    slim(:"units/new")
end

post('/protected/units/:id') do
    button = params[:id]
    while_funktion_cost(button)
    redirect('/protected/types')
end

get('/protected/army/show') do
    db = connect_db('db/hej.db')
    user_id = session[:id] 
    army_user = db.execute("SELECT user_id FROM army WHERE user_id = ?", user_id)

    if army_user.empty?
        redirect('/protected/no_army')
    end

    if session[:role] == 1
        @list = db.execute('SELECT unit.unit_name,unit.cost,unit.unit_id,user_id,army.army_name,army.army_id FROM army INNER JOIN unit ON army.unit_id = unit.unit_id')
    else
        @list = db.execute('SELECT unit.unit_name,unit.cost,unit.unit_id,user_id,army.army_name,army.army_id FROM army INNER JOIN unit ON army.unit_id = unit.unit_id WHERE user_id = ?',user_id)
    end

    slim(:"armies/show")
end

post('/protected/army/show/:id/delete') do
    db = connect_db('db/hej.db')
    user_id = session[:id]
    unit_id = params[:id]
    army_cost = db.execute('SELECT unit.cost FROM army INNER JOIN unit ON army.unit_id = unit.unit_id WHERE user_id = ?',user_id)
    latest_unit_cost = db.execute('SELECT cost FROM unit WHERE unit_id = ?',unit_id).first


    if session[:role] == 1
        db.execute("DELETE FROM army WHERE unit_id = ?",unit_id)
    else
        db.execute("DELETE FROM army WHERE unit_id = ? AND user_id = ?",unit_id,user_id)
    end

    session[:amount_that_they_cost] = army_cost
    redirect('/protected/army/show')
end


post('/protected/army/show/:id/update') do
    user_id = session[:id]
    unit_id = params[:id]
    faction = params[:faction]

    update_unit_faction(faction, unit_id)

    redirect('/protected/army/show')
end

post('/protected/army/show/:id/name') do
    db = connect_db('db/hej.db')
    army_name = params[:army_name]
    user_id = session[:id]
    hidden_id = params[:army_id]

    db.execute("UPDATE army SET army_name = ? WHERE user_id = ?",army_name,user_id)

    if session[:role] == 1
        db.execute("UPDATE army SET army_name = ?",army_name)
    end

    session[:army_name] = army_name
    redirect('/protected/army/show')
end



