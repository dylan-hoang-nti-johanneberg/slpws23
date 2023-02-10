require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

get('/') do
    slim(:home)
end

get('/lists') do

    slim(:lists)
end

get('/login') do
end

get('/register') do 
end

