require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'

enable :sessions


get('/') do
   slim(:start) 
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

    if faction == imperium
        db.execute('SELECT * faction WHERE faction_id = 1')
    elsif faction == chaos
        db.execute('SELECT * faction WHERE faction_id = 2')
    elsif faction == necrons
        db.execute('SELECT * faction WHERE faction_id = 3')
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
    @unit_list = db.execute('SELECT * FROM unit WHERE type_id = ?',button)
    slim(:units)
end

post('/units/:id_unit') do
    db = connect_db('db/hej.db')
    button = params[:id_unit]
    @army = db.execute('INSERT INTO army (unit_id) VALUES (?)',button) #Lägga till user_id
    redirect('/units/:id')
end

