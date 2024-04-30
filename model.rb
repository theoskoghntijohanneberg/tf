def connect_db(database)
    db = SQLite3::Database.new(database)
    db.results_as_hash = true
    return db
end

def select(table,column,row, first=false)
    db = connect_db('db/hej.db')
    if first
        return db.execute("SELECT * FROM #{table} WHERE #{column} = ?",row).first
    else
        return db.execute("SELECT * FROM #{table} WHERE #{column} = ?",row)
    end
end

def check_faction_unit(button)
    db = connect_db('db/hej.db')
    if session[:faction] == 1
        @unit_list = db.execute('SELECT * FROM unit WHERE faction_id = 1 AND type_id = ?',button)
    elsif session[:faction] == 2
        @unit_list = db.execute('SELECT * FROM unit WHERE faction_id = 2 AND type_id = ?',button)
    elsif session[:faction] == 3
        @unit_list = db.execute('SELECT * FROM unit WHERE faction_id = 3 AND type_id = ?',button)
    end

    if session[:faction] == nil
        redirect('/updatefaction')
    end
end


def update_faction(faction)
    db = connect_db('db/hej.db')
    if faction == "imperium"
        db.execute('SELECT * FROM faction WHERE faction_id = 1')
        session[:faction] = 1
    elsif faction == "chaos"
        db.execute('SELECT * FROM faction WHERE faction_id = 2')
        session[:faction] = 2
    elsif faction == "necrons"
        db.execute('SELECT * FROM faction WHERE faction_id = 3')
        session[:faction] = 3
    end
end

def while_funktion_cost(button)
    db = connect_db('db/hej.db')
    @amount_that_they_cost = 0
    unit_list = db.execute('SELECT unit_id FROM army WHERE user_id = ?', session[:id])
    i=0
    while i<unit_list.length
        unit_cost = db.execute('SELECT cost FROM unit WHERE unit_id = ?',unit_list[i]["unit_id"]).first
        puts("JDSAKJDSALKJDSAOJ")
        puts(unit_cost)
        @amount_that_they_cost += unit_cost["cost"]
        i+=1 
    end

    latest_unit_cost = db.execute('SELECT cost FROM unit WHERE unit_id = ?',button).first
    puts "COST #{@amount_that_they_cost}"
    session[:amount_that_they_cost] = @amount_that_they_cost+latest_unit_cost["cost"]

    if @amount_that_they_cost+latest_unit_cost["cost"] <= 3000
        puts "Current army size: #{@amount_that_they_cost+latest_unit_cost["cost"]}"
        db.execute('INSERT INTO army (unit_id, user_id) VALUES (?, ?)',button, session[:id])
    else
        session[:amount_that_they_cost] = @amount_that_they_cost+latest_unit_cost["cost"]
        puts ("Army is full current army size:")
        puts(@amount_that_they_cost+latest_unit_cost["cost"])
        redirect('/protected/types')
    end

    
end