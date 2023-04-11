$db = SQLite3::Database.new("db/products.db")
$db.results_as_hash = true

class DBexecutor
    # Attempts to insert a new row into computer list.
    #
    # @param [String] name, Name of computer
    # @param [Integer] time, Time of computer creation
    # @param [String] author_id, ID of user 
    # @param [Array] components, All components in an array
    #
    # @return [Method] function that inserts all components in relation table
    def insertIntoPCList(name, time, author_id, components)
        $db.execute("INSERT INTO computerList(computerName, creationTime, author_id) VALUES(?,?,?)", name, time, author_id)
        pcID = $db.execute("SELECT last_insert_rowid()")[0]["last_insert_rowid()"]
        return insertIntoPCRelation(pcID, components)
    end

    # Attemps to insert all components into computer and component relation table
    #
    # @param [Integer] pcID, ID of computer
    # @param [Array] components, Components in an array
    def insertIntoPCRelation(pcID, components)
        for component in components                 #clean code instead of one line SQL
            $db.execute("INSERT INTO computerList_component_rel(computerList_id, product_id) VALUES (?,?)", pcID, component)
        end
    end

    # Attemps to find and read computer list
    #
    # @param [Integer] id, ID of computer
    # 
    # @return [Hash] containing data of selected computer list
    #   * :error [Empty] whenever list is not found
    def readPCList(id)
        return $db.execute("SELECT * FROM computerList WHERE id = ?", id)
    end

    # Reads every computer lists
    #
    # @return [Hash] containing data of all components and computer list names
    #   * :error [Empty] whenever there is no computer list
    def readPCLists()
        return $db.execute("SELECT * FROM ((computerList_component_rel
            INNER JOIN computerList ON computerList_component_rel.computerList_id = computerList.id)
            INNER JOIN products ON computerList_component_rel.product_id = products.id)")
    end

    # Attemps to find computer list and returns all components and computer list information
    #
    # @param [Integer] id, ID of computer
    #
    # @return [Hash] containing data of all components in selected computer
    #   * :error [Empty] whenever there is no computer list
    # @return [Hash] containing data of all components and computer list names
    #   * :error [Empty] whenever there is no computer list
    def readPCListContent(id)
        pcComponents = $db.execute("SELECT * FROM (computerList_component_rel INNER JOIN products ON computerList_component_rel.product_id = products.id) WHERE computerList_id = ?", id)
        pcDescription = $db.execute("SELECT * FROM computerList WHERE id = ?", id)
        return pcComponents, pcDescription
    end

    # Attemps to delete computer list
    #
    # @param [Integer] id, ID of computer list
    #
    # @return [Method] function that deletes components from computer and component relation table 
    def deletePCList(id)
        $db.execute("DELETE FROM computerList WHERE id = ?", id)
        return deleteComponentPCRel(id)
    end

    # Attemps to delete computer from relation table
    #
    # @param [Integer] id, ID of computer list
    def deleteComponentPCRel(pcID)
        $db.execute("DELETE FROM computerList_component_rel WHERE computerList_id = ?", pcID)
    end

    # Attemps to find product
    #
    # @param [Integer] id, ID of product
    #
    # @return [Hash] contains information about the product
    #   * :error [Empty] whenever there is no product
    def readProduct(id)
        return $db.execute("SELECT * FROM products WHERE id = ?", id)
    end

    # Attemps to read all products
    #
    # @param [String] category, Category in products
    #
    # @return [Hash] contains information about all product within that category
    #   * :error [Empty] whenever the category is not found
    def readAllProducts(category)
        return $db.execute("SELECT * FROM products WHERE category = ?", category)
    end

    # Attemps to find and read infromation about user
    #
    # @param [String] username, The username 
    #
    # @return [Hash] contains information about selected user
    #   * :error [Empty] whenever the user is not found
    def readUserInfo(username)
        return $db.execute("SELECT id, password, isAdmin FROM users WHERE username = ?", username)
    end

    # Attemps to create a new user
    #
    # @param [String] username, The username 
    # @param [String] password_digest, Encrypted password 
    # @param [Integer] time, Time the user was created 
    # @param [Integer] isAdmin, Boolean if user is an admin
    def registerUser(username, password_digest, time, isAdmin)
        $db.execute("INSERT INTO users(username, password, creationTime, isAdmin) VALUES (?, ?, ?, ?)", username, password_digest, time, isAdmin)
    end

    # Attemps to update exsisting computer relation
    #
    # @param [Integer] id, ID of computer
    # @param [Array] components, All components 
    #
    # @return [Method] function that inserts all components in relation table
    def updateComputerRelation(id, components)
        $db.execute("DELETE FROM computerList_component_rel WHERE computerList_id = ?", id)
        return insertIntoPCRelation(id, components)
    end

    # Attemps to update computer name
    #
    # @param [String] name, New computer name
    # @param [Integer] id, ID of computer
    def updateComputer(name, id)
        $db.execute("UPDATE computerList SET computerName = ? WHERE id = ?", name, id)
    end

    # Attemps to insert new component into products table
    #
    # @param [String] name, Name of component
    # @param [String] category, Selected category name
    # @param [String] desc, Description of component
    def newComponent(name, category, desc)
        $db.execute("INSERT INTO products (name, category, desc) VALUES (?, ?, ?)", name, category, desc)
    end

    # Attemps to update component
    #
    # @param [String] name, New name of component
    # @param [String] desc, New description of component
    # @param [String] category, New category of component
    # @param [Integer] id, ID of component
    def updateComponent(name, desc, category, id)
        $db.execute("UPDATE products SET name = ?, desc = ?, category = ? WHERE id = ?", name, desc, category, id)
    end

    # Attemps to delete component from products table and also in already exsisting computers
    #
    # @param [Integer] id, ID of component
    def deleteComponent(id)
        $db.execute("DELETE FROM computerList_component_rel WHERE product_id = ?", id)
        $db.execute("DELETE FROM products WHERE id = ?", id)
    end

    # Reads all exsisting users
    #
    # @return [Hash] containing information about all users
    #   * :error [Empty] whenever there are no users 
    def readAllUsers()
        return $db.execute("SELECT username, id, creationTime, isAdmin FROM users")
    end
    
    # Attemps to read a single exsisting user
    #
    # @param [Integer] id, ID of user
    #
    # @return [Hash] containing information about selected user
    #   * :error [Empty] whenever there is no user
    def readUser(id)
        return $db.execute("SELECT id, username, creationTime, isAdmin FROM users WHERE id = ?", id)
    end

    # Attemps to update a users username
    #
    # @param [Integer] id, ID of user
    # @param [String] username, the new username
    def updateUsername(id, username)
        $db.execute("UPDATE users SET username = ? WHERE id = ?", username, id)
    end

    # Attemps to delete exsisting user
    #
    # @param [Integer] id, ID of user
    def deleteUser(id)
        $db.execute("DELETE FROM users WHERE id = ?", id)
    end

    # Attemps to delete all computers that a user has created
    # 
    # @param [Integer] author_id, ID of selected user
    def deleteAllUserPCList(author_id)
        userPCID = $db.execute("SELECT id FROM computerList WHERE author_id = ?", author_id)
        for pcID in userPCID
            deletePCList(pcID["id"])
        end
    end
end