require_relative '../db/db_connection'
require 'active_support/inflector'
require_relative './associations'

class SQLObject
  def self.columns
    columns_str = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    columns_str.map { |col| col.to_sym }
  end

  def self.finalize!
    columns.each do |col|
      define_method("#{col}") do
        attributes[col]
      end

      define_method("#{col}=") do |col_val|
        attributes[col] = col_val
      end
    end
  end

  def self.table_name=(given_name)
    @table_name = given_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
       #{self.table_name}
    SQL

    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    row = DBConnection.execute(<<-SQL, id).first
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        id = ?
    SQL

    row ? self.new(row) : nil
  end

  def initialize(params = {})
    my_columns = self.class.columns
    params.each do |attr_name, val|
      unless my_columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end

      send("#{attr_name}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |attr_name| send("#{attr_name}") }
  end

  def insert
    col_names = self.class.columns.join(', ')
    question_marks = Array.new(self.class.columns.count) { '?' }.join(', ')

    DBConnection.execute(<<-SQL, self.attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = (DBConnection.last_insert_row_id)
  end

  def update
    #we don't want to change the id of the object, so we drop it
    set_string = self.class.columns.drop(1).map do |attr_name|
      "#{attr_name} = ?"
    end.join(', ')

    DBConnection.execute(<<-SQL, self.attribute_values.drop(1), id: self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_string}
    WHERE
      id = :id
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end

  def where(params)
    where_line = params.map do |attr_name, val|
      "#{attr_name} = ?"
    end.join(" AND ")

    found = DBConnection.execute(<<-SQL, params.values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    found ? found.map { |result| self.new(result) } : []
  end
end
