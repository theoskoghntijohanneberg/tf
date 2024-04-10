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
      redirect('/protected/buildarmy')
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

before('/protected/*') do
    if session[:id] == nil
        redirect('/error')
    end
end

# before('/protected/buildarmy') do
#     if session[:faction] != nil
#         redirect('/protected/types')
#     end
# end

get('/protected/no_army') do
    slim(:noarmy)
end

get('/protected/buildarmy') do
    db = connect_db('db/hej.db')
    @all_factions = db.execute("SELECT * FROM faction")
    user_id = session[:id]
    army_user = db.execute("SELECT user_id FROM army WHERE user_id = ?", user_id)

    if army_user.empty?
        slim(:army)
    else
        redirect('/protected/types')
    end

    slim(:army)
end


post('/protected/buildarmy') do
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
    redirect('/protected/types')
end


get('/protected/types') do
    db = connect_db('db/hej.db')
    @type_list = db.execute('SELECT * FROM type')
    slim(:types)
end

get('/protected/units/:id') do
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

post('/protected/units/:id') do
    db = connect_db('db/hej.db')
    button = params[:id]
    unit_list = db.execute('SELECT unit_id FROM army WHERE user_id = ?', session[:id])
    @amount_that_they_cost = 0
    i=0

    while i<unit_list.length
        unit_cost = db.execute('SELECT cost FROM unit WHERE unit_id = ?',unit_list[i]["unit_id"]).first
        puts("JDSAKJDSALKJDSAOJ")
        puts(unit_cost)
        @amount_that_they_cost += unit_cost["cost"]
        i+=1 
    end

    latest_unit_cost = db.execute('SELECT cost FROM unit WHERE unit_id = ?',button).first
    puts "COST #{@amount_that_they_cost}"

    if @amount_that_they_cost+latest_unit_cost["cost"] <= 3000
        puts "Current army size: #{@amount_that_they_cost+latest_unit_cost["cost"]}"
        db.execute('INSERT INTO army (unit_id, user_id) VALUES (?, ?)',button, session[:id])
    else
        session[:amount_that_they_cost] = @amount_that_they_cost+latest_unit_cost["cost"]
        puts ("Army is full current army size:")
        puts(@amount_that_they_cost+latest_unit_cost["cost"])
        redirect('/protected/types')
    end

    session[:amount_that_they_cost] = @amount_that_they_cost+latest_unit_cost["cost"]

    redirect('/protected/types')
end

get('/protected/armylist') do
    db = connect_db('db/hej.db')
    user_id = session[:id] 
    @list = db.execute('SELECT unit.unit_name,unit.cost,unit.unit_id FROM army INNER JOIN unit ON army.unit_id = unit.unit_id WHERE user_id = ?',user_id)
    army_user = db.execute("SELECT user_id FROM army WHERE user_id = ?", user_id)

    if army_user.empty?
        redirect('/protected/no_army')
    end

    slim(:armylist)
end

post('/protected/armylist/:id/delete') do
    db = connect_db('db/hej.db')
    user_id = session[:id]
    unit_id = params[:id]
    army_cost = db.execute('SELECT unit.cost FROM army INNER JOIN unit ON army.unit_id = unit.unit_id WHERE user_id = ?',user_id)
    db.execute("DELETE FROM army WHERE unit_id = ? AND user_id = ?",unit_id,user_id)
    session[:amount_that_they_cost] = army_cost
    redirect('/protected/armylist')
end


post('/protected/armylist/:id/update') do
    db = connect_db('db/hej.db')
    user_id = session[:id]
    unit_id = params[:id]
    imperium = params[:imperium]
    chaos = params[:chaos]
    necrons = params[:necrons]
    faction = params[:faction]

    if faction == "imperium"
        db.execute('UPDATE unit SET faction_id = 1 WHERE unit_id = ?', unit_id)
    elsif faction == "chaos"
        db.execute('UPDATE unit SET faction_id = 2 WHERE unit_id = ?', unit_id)
    elsif faction == "necrons"
        db.execute('UPDATE unit SET faction_id = 3 WHERE unit_id = ?', unit_id)
    end

    redirect('/protected/armylist')
end

post('/protected/armylist/:id/name') do
    db = connect_db('db/hej.db')
    army_name = params[:army_name]
    user_id = session[:id]

    db.execute("UPDATE army SET army_name = ? WHERE user_id = ?",army_name,user_id)

    session[:army_name] = army_name
    redirect('/protected/armylist')
end



