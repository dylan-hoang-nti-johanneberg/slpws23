require 'sinatra/reloader'
require 'sqlite3'
# require 'bcrypt'
$db = SQLite3::Database.new("db/data.db")
$db.results_as_hash = true

class DBexecutor
    def insertIntoPCList(name, cpu, gpu, ram, mobo, psu, ssd)
        # arr = [name, cpu, gpu, ram, mobo, psu, ssd]
        # for x in 1..7 do
        #     if 
        # end
        $db.execute("INSERT INTO computerList(name, cpu, gpu, ram, mobo, psu, ssd) VALUES(?,?,?,?,?,?,?)", name, cpu, gpu, ram, mobo, psu, ssd)
    end

    def readPCList()
        return $db.execute("SELECT id, name FROM computerList")
    end

    def readPCListContent(id)
        return $db.execute("SELECT * FROM computerList WHERE id = ?", id)
    end

    def deletePCList(id)
        $db.execute("DELETE FROM computerList WHERE id = ?", id)
    end
end