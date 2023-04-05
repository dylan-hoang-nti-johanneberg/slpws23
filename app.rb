require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

# require_relative 'model'
enable :sessions

# $db = SQLite3::Database.new("db/data.db")
# $db.results_as_hash = true

$db = SQLite3::Database.new("db/products.db")
$db.results_as_hash = true

class DBexecutor
    def insertIntoPCList(name, time, author_id)
        $db.execute("INSERT INTO computerList(computerName, creationTime, author_id) VALUES(?,?,?)", name, time, author_id)
        pcID = $db.execute("SELECT last_insert_rowid()")[0]["last_insert_rowid()"]
        return insertIntoPCRelation(pcID)
    end

    def insertIntoPCRelation(pcID, components)
        for component in components                 #clean code instead of one line SQL
            $db.execute("INSERT INTO computerList_component_rel(computerList_id, product_id) VALUES (?,?)", pcID, component)
        end
    end

    def readPCList()
        return $db.execute("SELECT * FROM ((computerList_component_rel
            INNER JOIN computerList ON computerList_component_rel.computerList_id = computerList.id)
            INNER JOIN products ON computerList_component_rel.product_id = products.id)")
    end

    def readPCListContent(id)
        pcComponents = $db.execute("SELECT * FROM (computerList_component_rel INNER JOIN products ON computerList_component_rel.product_id = products.id) WHERE computerList_id = ?", id)
        pcDescription = $db.execute("SELECT * FROM computerList WHERE id = ?", id)
        return pcComponents, pcDescription
    end

    def deletePCList(id)
        $db.execute("DELETE FROM computerList WHERE id = ?", id)
    end

    def readAllProducts(category)
        return $db.execute("SELECT * FROM products WHERE category = ?", category)
    end

    def readUserInfo(username)
        return $db.execute("SELECT id, password FROM users WHERE username = ?", username)
    end

    def registerUser(username, password_digest, time, isAdmin)
        return $db.execute("INSERT INTO users(username, password, creationTime, isAdmin) VALUES (?, ?, ?, ?)", username, password_digest, time, isAdmin)
    end

    def updateComputerRelation(id, components)
        $db.execute("DELETE FROM computerList_component_rel WHERE computerList_id = ?", id)
        return insertIntoPCRelation(id, components)
    end

    def updateComputer(name, id)
        return $db.execute("UPDATE computerList SET computerName = ? WHERE id = ?", name, id)
    end
end

get('/') do
    slim(:home)
end

get('/lists') do
    @computers = DBexecutor.new.readPCList()
    @formatedComputers = []
    for computer in @computers
        if !@formatedComputers.include?({"computerName"=>computer["computerName"], "id"=>computer["computerList_id"]})
            @formatedComputers.append({"computerName"=>computer["computerName"], "id"=>computer["computerList_id"]}) 
        end
    end

    slim(:"computerLists/index")
end

get('/lists/new') do
    @partTypes = ['CPU', 'GPU','RAM']
    @categories = []
    for partType in @partTypes
        @categories.append(DBexecutor.new.readAllProducts(partType))
    end
    
    p @categories
    slim(:"computerLists/new")
end

get('/lists/:id/edit') do
    @components, @pcInfo= DBexecutor.new.readPCListContent(params[:id])
    @partTypes = ['CPU', 'GPU','RAM']
    @categories = []

    @componentsFormated = []
    @componentsID = []
    i = 0
    while i < 6
        if @components[i]!= nil
            @componentsFormated.append(@components[i]["name"])
            @componentsID.append(@components[i]["product_id"])
        else
            @componentsFormated.append("")
            @componentsID.append("")
        end
        i += 1
    end

    for partType in @partTypes
        @categories.append(DBexecutor.new.readAllProducts(partType))
    end
    slim(:"computerLists/edit")
end

post('/lists/:id/update') do
    components = [
        params[:cpu_id],
        params[:gpu_id],
        params[:ram_id],
        params[:mobo_id],
        params[:psu_id],
        params[:ssd_id]]
    
    DBexecutor.new.updateComputer(
        params[:listName],
        params[:id]
    )
    DBexecutor.new.updateComputerRelation(
        params[:id], 
        components
    )

    redirect('/lists')
end

get('/lists/:id') do
    @components, @pcInfo= DBexecutor.new.readPCListContent(params[:id])
    p @pcInfo
    slim(:"computerLists/show")
end

post('/lists') do    
    author_id = params[:author_id]
    if params[:author_id] == nil
        author_id = 0
    end

    components = [
    params[:cpu_id],
    params[:gpu_id],
    params[:ram_id],
    params[:mobo_id],
    params[:psu_id],
    params[:ssd_id]]

    DBexecutor.new.insertIntoPCList(
        params[:listName],
        Time.new().to_i,
        author_id,
        components
    )
    redirect('/lists')
end

post('/lists/:id/delete') do
    listID = params[:id]
    DBexecutor.new.deletePCList(listID)
    redirect('/lists')

end

get('/login') do
    slim(:login)
end

get('/register') do 
    slim(:register)
end

get('/logout') do
    session.destroy
    redirect('/')
end

post('/login') do
    result = DBexecutor.new.readUserInfo(params[:username])
    user_id = result.first["id"]
    password_digest = result.first["password"]
    if BCrypt::Password.new(password_digest) == params[:password]
        session[:user_id] = user_id
        p "ID!!! = "
        p session[:user_id]
        redirect('/lists')
    else
        redirect('/')
    end

end

post('/register') do
    password = params[:password]
    passwordConfirm = params[:passwordConfirm]
    result = DBexecutor.new.readUserInfo(params[:username])

    if result.empty?
        if password == passwordConfirm
            password_digest = BCrypt::Password.create(password)
            DBexecutor.new.registerUser(params[:username], password_digest, Time.new().to_i, 0)
            redirect('/')
        else
            redirect('/')
        end
    else
        redirect('/')
    end

end