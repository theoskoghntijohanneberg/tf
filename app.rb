require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require './model.rb'

enable :sessions


get('/') do
    db = connect_db('db/hej.db')
   slim(:start) 
end

get('/buildarmy') do
    db = connect_db('db/hej.db')
    @all_factions = db.execute("SELECT * FROM faction")
    slim(:army)
end