require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model'
enable :sessions

# Function to verify if client is logged in and if not redirects to '/login/'
#
# @param [Integer] :user_id, ID of user
#  
def isLoggedIn()
    if session[:user_id].nil?
        redirect('/login/')
    end
end

# Function to verify if client userID corresponds to a resource with an userID and if ture redirects to '/lists/'
#
# @param [Integer] :user_id, ID of user
#  
def authorizedUser(authorizedUserID)
    if session[:user_id] == nil
        redirect('/login/')
    elsif session[:user_id] != authorizedUserID
        denied("#{params[:id]} that is owned by User #{authorizedUserID}")
        redirect('/lists/')
    end
end

# Debug alert function for console 
def denied(message)
    puts "Access Denied: User #{session[:user_id]} tried to access #{message}"
end

# Function to verify if client userID sent is an admin on server side
#
# @see DBexecutor#readUser
def trueAdmin(userID)
    user = DBexecutor.new.readUser(userID)
    return user[0]["isAdmin"] == 1
end

['/lists/', '/lists/new', '/lists/:id', '/lists'].each do |route|
    before(route) do
        isLoggedIn()
    end
end

['/lists/:id/edit', '/lists/:id/update', '/lists/:id/delete'].each do |route|
    before(route) do
        isLoggedIn()
        if session[:isAdmin] == false && !trueAdmin(session[:user_id])
            authorID = DBexecutor.new.readPCList(params[:id])
            authorizedUser(authorID[0]["author_id"])
        end
    end
end

['/components/new', '/components', '/components/:id/edit', '/components/:id/update', '/components/:id/delete'].each do |route|
    before(route) do
        isLoggedIn()
        if session[:isAdmin] == false && !trueAdmin(session[:user_id])
            redirect('/components/')
        end
    end
end

['/user/:id/update', '/user/:id/edit'].each do |route|
    before(route) do
        isLoggedIn()
        if session[:isAdmin] == false && !trueAdmin(session[:user_id])
            authorizedUser(params[:id].to_i)
        end
    end
end

['/user/', '/users/', '/user/:id/delete'].each do |route|
    before(route) do
        isLoggedIn()
        if session[:isAdmin] == false && !trueAdmin(session[:user_id])
            redirect('/lists/')
        end
    end
end

# Display Landing Page
#
get('/') do
    slim(:home)
end

# Displays a index of all computer lists
#
# @see DBexecutor#readPCLists
# @see DBexecutor#readAllUsers
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

# Displays a creation form for a computer list
#
# @see DBexecutor#readAllProducts
get('/lists/new') do
    @partTypes = ['CPU', 'GPU','RAM']
    @categories = []
    for partType in @partTypes
        @categories.append(DBexecutor.new.readAllProducts(partType))
    end
    
    slim(:"computerLists/new")
end

# Display a form to edit a specific computer list
#
# @param [Integer] :id, ID of the computer list
#
# @see DBexecutor#readPCListContent
# @see DBexecutor#readAllProducts
get('/lists/:id/edit') do
    p params[:id]
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

# Updates an existing computer list and redirects to '/lists/'
#
# @param [Integer] :id, ID of the computer list
# @param [Integer] :cpu_id, The new CPU component ID
# @param [Integer] :gpu_id, The new GPU component ID
# @param [Integer] :ram_id, The new RAM component ID
# @param [Integer] :mobo_id, The new motherboard component ID
# @param [Integer] :psu_id, The new powersupply component ID
# @param [Integer] :ssd_id, The new solid state drive component ID
# @param [String] :listName, The new name of the computer
#
# @see DBexecutor#updateComputer
# @see DBexecutor#updateComputerRelation
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

# Displays components and name in a computer list
#
# @param [Integer] :id, ID of the computer list
#
# @see DBexecutor#readPCListContent
get('/lists/:id') do
    @components, @pcInfo= DBexecutor.new.readPCListContent(params[:id])
    p @pcInfo
    slim(:"computerLists/show")
end

# Creates a new computer list with components and redirects to '/lists/'
#
# @param [Integer] :id, ID of the computer list
# @param [Integer] :cpu_id, The new CPU component ID
# @param [Integer] :gpu_id, The new GPU component ID
# @param [Integer] :ram_id, The new RAM component ID
# @param [Integer] :mobo_id, The new motherboard component ID
# @param [Integer] :psu_id, The new powersupply component ID
# @param [Integer] :ssd_id, The new solid state drive component ID
# @param [String] :listName, The new name of the computer
# @param [Integer] :user_id, ID of user that creates the computer list that is stored in session
#
# @see DBexecutor#insertIntoPCList
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

# Deletes a computer list and redirects to '/lists/'
#
# @param [Integer] :id, ID of the computer list
#
# @see DBexecutor#deletePCList
post('/lists/:id/delete') do
    listID = params[:id]
    DBexecutor.new.deletePCList(listID)
    redirect('/lists/')
end

# Displays a login form
#
get('/login/') do
    slim(:login)
end

# Displays a login form with an error message
#
# @param [Integer] :errorMSG, Index of error message in Array
#
get('/login/error/:errorMSG') do
    @errors = ["Too many logins!", "Invalid credentials!"]
    @error = @errors[params[:errorMSG].to_i]
    slim(:login)
end

# Displays a register form
#
get('/register/') do 
    slim(:register)
end

# Logs out user by destorying session and redirects to '/'
#
get('/logout/') do
    session.destroy
    redirect('/')
end

# Attempts login and updates the session and if successful redirects to '/lists/'
#
# @param [Integer] :time, latest login time in UNIX time stored in session
# @param [String] :username, The username
# @param [String] :password, The password
#
# @see DBexecutor#readUserInfo
post('/login') do
    result = DBexecutor.new.readUserInfo(params[:username])
    if session[:time].nil?
        session[:time] = Time.new()
    elsif (Time.new-session[:time]) < 4
        redirect('/login/error/0')
    end

    if result == []
        redirect('/login/error/1')
    end

    user_id = result.first["id"]
    password_digest = result.first["password"]
    if BCrypt::Password.new(password_digest) == params[:password]
        session[:user_id] = user_id
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

# Attemps to creates a new user and if successful redirects to '/login/'
#
# @param [String] :username, The username
# @param [String] :password, The password
# @param [String] :passwordConfirm, Password confirmation
#
# @see DBexecutor#readUserInfo
# @see DBexecutor#registerUser
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

# Displays an index of all components from every category
#
# @see DBexecutor#readAllProducts
get('/components/') do
    @partTypes = ['CPU', 'GPU', 'RAM']
    @categories = []
    for partType in @partTypes
        @categories.append(DBexecutor.new.readAllProducts(partType))
    end
    slim(:'components/index')
end

# Displays a creation form to create a new component
#
# @see DBexecutor#readAllProducts
get('/components/new') do
    @partTypes = ['CPU', 'GPU','RAM']
    @categories = []
    for partType in @partTypes
        @categories.append(DBexecutor.new.readAllProducts(partType))
    end
    slim(:'components/new')
end

# Creates a new component and redirects to '/components/'
#
# @param [String] :name, Name of component
# @param [String] :category, Category of component
# @param [String] :desc, Description of component
#
# @see DBexecutor#newComponent
post('/components') do
    DBexecutor.new.newComponent(params[:name], params[:category], params[:desc])
    redirect('/components/')
end

# Displays a component with name and description
#
# @param [Integer] :id, ID of the component
#
# @see DBexecutor#readProduct
get('/components/:id') do
    @product = DBexecutor.new.readProduct(params[:id])
    slim(:'components/show')
end

# Displays an edit form to update a component
#
# @param [Integer] :id, ID of the component
#
# @see DBexecutor#readProduct
get('/components/:id/edit') do
    @partTypes = ['CPU', 'GPU', 'RAM']
    @product = DBexecutor.new.readProduct(params[:id])
    slim(:'components/edit')
end

# Updates an existing component and redirects to '/components/'
#
# @param [Integer] :id, ID of the component
# @param [String] :name, Name of component
# @param [String] :name, Description of component
# @param [String] :name, Category of component
#
# @see DBexecutor#updateComponent
post('/components/:id/update') do
    DBexecutor.new.updateComponent(
        params[:name],
        params[:desc], 
        params[:category],
        params[:id]
    )

    redirect('/components/')
end

# Deletes a component and redirects to '/components/'
#
# @param [Integer] :id, ID of the component
#
# @see DBexecutor#deleteComponent
post('/components/:id/delete') do
    DBexecutor.new.deleteComponent(params[:id])
    redirect('/components/')
end

# Displays an edit form to update a user
#
# @param [Integer] :id, ID of the user
#
# @see DBexecutor#readUser
get('/user/:id/edit') do
    @user = DBexecutor.new.readUser(params[:id])
    slim(:'user/edit')
end

# Updates an existing user and redirects to '/lists/'
#
# @param [Integer] :id, ID of the user
# @param [String] :username, New Username
#
# @see DBexecutor#updateUsername
post('/user/:id/update') do
    DBexecutor.new.updateUsername(params[:id], params[:username])
    redirect('/lists/')
end

# Displays an index of all registered users
#
# @see DBexecutor#readAllUsers
get('/user/') do
    @users = DBexecutor.new.readAllUsers()
    slim(:'user/index')
end

# Deletes an user and redirects to '/user/'
#
# @param [Integer] :id, ID of the user
#
# @see DBexecutor#deleteAllUserPCList
# @see DBexecutor#deleteUser
post('/user/:id/delete') do
    DBexecutor.new.deleteAllUserPCList(params[:id])
    DBexecutor.new.deleteUser(params[:id])
    redirect('/user/')
end