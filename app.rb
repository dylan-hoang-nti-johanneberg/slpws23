require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model'
enable :sessions

def isLoggedIn()
    if session[:user_id].nil?
        redirect('/login/')
    end
end

def authorizedUser(authorizedUserID)
    if session[:user_id] == nil
        redirect('/login/')
    elsif session[:user_id] != authorizedUserID
        denied("#{params[:id]} that is owned by User #{authorizedUserID}")
        redirect('/lists/')
    end
end

def denied(message)
    puts "Access Denied: User #{session[:user_id]} tried to access #{message}"
end

def trueAdmin(userID)
    user = DBexecutor.new.readUser(userID)
    return user[0]["isAdmin"] == 1
end

get('/') do
    slim(:home)
end

before('/lists/') do
    isLoggedIn()
end

get('/lists/') do
    @computers = DBexecutor.new.readPCLists()
    @users = DBexecutor.new.readAllUsers()
    @formatedComputers = []
    for computer in @computers
        if !@formatedComputers.include?({"computerName"=>computer["computerName"], "id"=>computer["computerList_id"], "author_id"=>computer["author_id"]})
            @formatedComputers.append({"computerName"=>computer["computerName"], "id"=>computer["computerList_id"], "author_id"=>computer["author_id"]}) 
        end
    end

    slim(:"computerLists/index")
end

before('/lists/new') do
    isLoggedIn()
end

get('/lists/new') do
    @partTypes = ['CPU', 'GPU','RAM']
    @categories = []
    for partType in @partTypes
        @categories.append(DBexecutor.new.readAllProducts(partType))
    end
    
    slim(:"computerLists/new")
end

before('/lists/:id/edit') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        authorID = DBexecutor.new.readPCList(params[:id])
        authorizedUser(authorID[0]["author_id"])
    end
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

before('/lists/:id/update') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        authorID = DBexecutor.new.readPCList(params[:id])
        authorizedUser(authorID[0]["author_id"])
    end
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

    redirect('/lists/')
end

before('/lists/:id') do
    isLoggedIn()
end

get('/lists/:id') do
    @components, @pcInfo= DBexecutor.new.readPCListContent(params[:id])
    p @pcInfo
    slim(:"computerLists/show")
end

before('/lists') do
    isLoggedIn()
end

post('/lists') do    
    author_id = session[:user_id]
    if author_id == nil
        redirect('/login/')
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
    redirect('/lists/')
end

before('/lists/:id/delete') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        authorID = DBexecutor.new.readPCList(params[:id])
        authorizedUser(authorID[0]["author_id"])
    end
end

post('/lists/:id/delete') do
    listID = params[:id]
    DBexecutor.new.deletePCList(listID)
    redirect('/lists/')
end

get('/login/') do
    slim(:login)
end

get('/login/error/:errorMSG') do
    @errors = ["Too many logins!", "Invalid credentials!"]
    @error = @errors[params[:errorMSG].to_i]
    slim(:login)
end

get('/register/') do 
    slim(:register)
end

get('/logout/') do
    session.destroy
    redirect('/')
end

post('/login') do
    result = DBexecutor.new.readUserInfo(params[:username])
    if session[:time].nil?
        session[:time] = Time.new()
    elsif (Time.new-session[:time]) < 4
        p "EEEEERR"
        redirect('/login/error/0')
    end

    if result == []
        redirect('/login/error/1')
    end

    
    user_id = result.first["id"]
    password_digest = result.first["password"]
    if BCrypt::Password.new(password_digest) == params[:password]
        session[:user_id] = user_id
        p "ID!!! = "
        p session[:user_id]

        if result.first["isAdmin"] == 1
            session[:isAdmin] = true
        else
            session[:isAdmin] = false
        end

        redirect('/lists/')
    else
        session[:time] = Time.new()
        redirect('/login/error/1')
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
            redirect('/login/')
        else
            redirect('/')
        end
    else
        redirect('/')
    end

end

get('/components/') do
    @partTypes = ['CPU', 'GPU', 'RAM']
    @categories = []
    for partType in @partTypes
        @categories.append(DBexecutor.new.readAllProducts(partType))
    end
    slim(:'components/index')
end

before('/components/new') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        redirect('/components/')
    end
end

get('/components/new') do
    @partTypes = ['CPU', 'GPU','RAM']
    @categories = []
    for partType in @partTypes
        @categories.append(DBexecutor.new.readAllProducts(partType))
    end
    slim(:'components/new')
end

before('/components') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        redirect('/components/')
    end
end

post('/components') do
    DBexecutor.new.newComponent(params[:name], params[:category], params[:desc])
    redirect('/components/')
end


get('/components/:id') do
    @product = DBexecutor.new.readProduct(params[:id])
    slim(:'components/show')
end

before('/components/:id/edit') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        redirect('/components/')
    end
end

get('/components/:id/edit') do
    @partTypes = ['CPU', 'GPU', 'RAM']
    @product = DBexecutor.new.readProduct(params[:id])
    slim(:'components/edit')
end

before('/components/:id/update') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        redirect('/components/')
    end
end

post('/components/:id/update') do
    DBexecutor.new.updateComponent(
        params[:name],
        params[:desc], 
        params[:category],
        params[:id]
    )

    redirect('/components/')
end

before('/components/:id/delete') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        redirect('/components/')
    end
end

post('/components/:id/delete') do
    DBexecutor.new.deleteComponent(params[:id])
    redirect('/components/')
end

before('/user/:id/edit') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        authorizedUser(params[:id].to_i)
    end
end

get('/user/:id/edit') do
    @user = DBexecutor.new.readUser(params[:id])
    slim(:'user/edit')
end

before('/user/:id/update') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        authorizedUser(params[:id].to_i)
    end
end

post('/user/:id/update') do
    DBexecutor.new.updateUsername(params[:id], params[:username])
    redirect('/lists/')
end

before('/user/') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        redirect('/lists/')
    end
end

get('/user/') do
    @users = DBexecutor.new.readAllUsers()
    slim(:'user/index')
end

before('/user/:id/delete') do
    isLoggedIn()
    if session[:isAdmin] == false && !trueAdmin(session[:user_id])
        redirect('/lists/')
    end
end

post('/user/:id/delete') do
    DBexecutor.new.deleteAllUserPCList(params[:id])
    DBexecutor.new.deleteUser(params[:id])
    redirect('/user/')
end