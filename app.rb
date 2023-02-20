require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require_relative 'model'
enable :sessions

db = SQLite3::Database.new("db/data.db")

get('/') do
    slim(:home)
end

get('/lists') do
    @lists = DBexecutor.new.readPCList()
    slim(:"computerLists/lists")
end

get('/lists/new') do

    slim(:"computerLists/new")
end

get('/lists/:id') do
    @components = DBexecutor.new.readPCListContent(params[:id])
    slim(:"computerLists/showList")
end

post('/lists') do
    DBexecutor.new.insertIntoPCList(
        params[:listName],
        params[:cpu],
        params[:gpu],
        params[:ram],
        params[:mobo],
        params[:psu],
        params[:ssd]
    )
    redirect('/lists')
end

post('/lists/:id/delete') do
    listID = params[:id]
    DBexecutor.new.deletePCList(listID)
    redirect('/lists')
end

get('/login') do
end

get('/register') do 
end

