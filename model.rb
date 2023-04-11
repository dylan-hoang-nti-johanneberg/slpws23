# require 'sinatra/reloader'
# require 'sqlite3'
# require 'bcrypt'
$db = SQLite3::Database.new("db/products.db")
$db.results_as_hash = true

class DBexecutor
    def insertIntoPCList(name, time, author_id, components)
        $db.execute("INSERT INTO computerList(computerName, creationTime, author_id) VALUES(?,?,?)", name, time, author_id)
        pcID = $db.execute("SELECT last_insert_rowid()")[0]["last_insert_rowid()"]
        return insertIntoPCRelation(pcID, components)
    end

    def insertIntoPCRelation(pcID, components)
        for component in components                 #clean code instead of one line SQL
            $db.execute("INSERT INTO computerList_component_rel(computerList_id, product_id) VALUES (?,?)", pcID, component)
        end
    end

    def readPCList(id)
        return $db.execute("SELECT * FROM computerList WHERE id = ?", id)
    end

    def readPCLists()
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
        return deleteComponentPCRel(id)
    end

    def deleteComponentPCRel(pcID)
        $db.execute("DELETE FROM computerList_component_rel WHERE computerList_id = ?", pcID)
    end

    def readProduct(id)
        return $db.execute("SELECT * FROM products WHERE id = ?", id)
    end

    def readAllProducts(category)
        return $db.execute("SELECT * FROM products WHERE category = ?", category)
    end

    def readUserInfo(username)
        return $db.execute("SELECT id, password, isAdmin FROM users WHERE username = ?", username)
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

    def newComponent(name, category, desc)
        return $db.execute("INSERT INTO products (name, category, desc) VALUES (?, ?, ?)", name, category, desc)
    end

    def updateComponent(name, desc, category, id)
        return $db.execute("UPDATE products SET name = ?, desc = ?, category = ? WHERE id = ?", name, desc, category, id)
    end

    def deleteComponent(id)
        $db.execute("DELETE FROM computerList_component_rel WHERE product_id = ?", id)
        $db.execute("DELETE FROM products WHERE id = ?", id)
    end

    def readAllUsers()
        return $db.execute("SELECT username, id, creationTime, isAdmin FROM users")
    end
    
    def readUser(id)
        return $db.execute("SELECT id, username, creationTime, isAdmin FROM users WHERE id = ?", id)
    end

    def updateUsername(id, username)
        return $db.execute("UPDATE users SET username = ? WHERE id = ?", username, id)
    end

    def deleteUser(id)
        return $db.execute("DELETE FROM users WHERE id = ?", id)
    end

    def deleteAllUserPCList(author_id)
        userPCID = $db.execute("SELECT id FROM computerList WHERE author_id = ?", author_id)
        for pcID in userPCID
            deletePCList(pcID["id"])
        end
    end
end