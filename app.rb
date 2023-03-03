require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
# require_relative 'model'
enable :sessions

$db = SQLite3::Database.new("db/data.db")
$db.results_as_hash = true

$dbProducts = SQLite3::Database.new("db/products.db")
$dbProducts.results_as_hash = true

class DBexecutor
    def insertIntoPCList(name, cpu, gpu, ram, mobo, psu, ssd)
        $db.execute("INSERT INTO computerList(name, cpu, gpu, ram, mobo, psu, ssd) VALUES(?,?,?,?,?,?,?)", name, cpu, gpu, ram, mobo, psu, ssd)
    end

    def readPCList()
        return $db.execute("SELECT id, name FROM computerList")
    end

    def readPCListContent(id)
        pcComponents = $db.execute("SELECT cpu, gpu, ram, mobo psu, ssd FROM computerList WHERE id = ?", id)
        pcDescription = $db.execute("SELECT * FROM computerList WHERE id = ?", id)
        return pcComponents, pcDescription
    end

    def deletePCList(id)
        $db.execute("DELETE FROM computerList WHERE id = ?", id)
    end

    def readAllProducts(category)
        selectTable = "SELECT * FROM #{category}"
        $dbProducts.execute(selectTable)
    end
end

get('/') do
    slim(:home)
end

get('/lists') do
    @lists = DBexecutor.new.readPCList()
    slim(:"computerLists/lists")
end

get('/lists/new') do
    @partTypes = ['CPU', 'GPU', 'RAM']
    @components = DBexecutor.new.readAllProducts(@partTypes[0])
    for component in @components
        component["Model"] = component["Model"].split(/ /, 3)
        if component["Model"][1] == "Ryzen"
            component["Model"] = "AMD #{component["Model"][1]} #{component["Model"][2]}"
        elsif component["Model"][1] == "Core"
            component["Model"] = "Intel #{component["Model"][1]} #{component["Model"][2]}"
        end
    end
    slim(:"computerLists/new")
end

get('/lists/:id') do
    @components, @pcInfo= DBexecutor.new.readPCListContent(params[:id])
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

