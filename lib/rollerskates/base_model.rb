require "rollerskates/helpers/model_helper"

module Rollerskates
  class BaseModel < Rollerskates::ModelHelper
    def initialize(values = {})
      hash_to_properties(values) unless values.empty?
    end

    def hash_to_properties(hash)
      hash.each do |column, value|
        instance_variable_set("@#{column}", value)
      end
    end

    def update(hash)
      hash_to_properties(hash)
      @updated_at = Time.now.to_s
    end

    def save
      create_columns_placeholders_values
      if id
        @@db.execute(update_query, values_for_update)
      else
        add_created_at_and_updated_at
        @@db.execute "INSERT INTO #{table_name} (#{@columns.join(', ')})\
          VALUES (#{@placeholders.join(', ')})", @values
      end
    end

    def placeholders_for_update
      placeholders = @columns.map { |col| col + " = ?" }
      placeholders.join(", ")
    end

    def values_for_update
      @values << id
    end

    def create_columns_placeholders_values
      @model = self
      @columns = []
      @placeholders = []
      @values = []

      all_columns.each do |column|
        value = @model.send(column)
        next unless value
        @columns << column.to_s
        @placeholders << "?"
        @values << value
      end
    end

    def add_created_at_and_updated_at
      @columns << %w(created_at updated_at)
      @placeholders << ["?", "?"]
      @values << [Time.now.to_s, Time.now.to_s]
    end

    def self.all
      data = @@db.execute "SELECT #{all_columns.join(', ')} FROM #{table_name}"
      data.map do |row|
        row_to_object(row)
      end
    end

    def self.find(id)
      data = @@db.execute "SELECT #{all_columns.join(', ')} FROM #{table_name}\
        WHERE id = ?", id
      row_to_object data.flatten
    end

    def destroy
      @@db.execute "DELETE FROM #{table_name} WHERE id = ?", id
    end

    def self.destroy(id)
      @@db.execute "DELETE FROM #{table_name} WHERE id = ?", id
    end

    def self.destroy_all
      @@db.execute "DELETE FROM #{table_name}"
    end

    def self.row_to_object(row)
      model = model_name.new
      all_columns.each_with_index do |attribute, index|
        model.send("#{attribute}=", row[index])
      end
      model
    end
  end
end