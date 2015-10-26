require 'active_support/inflector'

# Phase IIIa
class AssocOptions

  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    defaults = {
      class_name: "#{name}".camelcase,
      foreign_key: "#{name}_id".downcase.to_sym,
      primary_key: :id
    }

    options = defaults.merge(options)

    self.foreign_key = options[:foreign_key]
    self.primary_key = options[:primary_key]
    self.class_name = options[:class_name]
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    defaults = {
      class_name: "#{name}".singularize.camelcase,
      foreign_key: "#{self_class_name}_id".downcase.to_sym,
      primary_key: :id
    }

    options = defaults.merge(options)

    self.foreign_key = options[:foreign_key]
    self.class_name = options[:class_name]
    self.primary_key = options[:primary_key]
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, opts = {})
    assoc_options[name] = BelongsToOptions.new(name, opts)
    options = assoc_options[name]

    define_method "#{name}" do
      target_id = self.send("#{options.foreign_key}")
      params = { "#{options.primary_key}" => target_id }
      options.model_class.where(params).first
    end
  end

  def has_many(name, opts = {})
    assoc_options[name] = HasManyOptions.new(name, self.name, opts)
    options = assoc_options[name]

    define_method "#{name}" do
      target_id = self.send("#{options.primary_key}")
      params = { "#{options.foreign_key}" => target_id }
      options.model_class.where(params)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end

  def has_one_through(name, through_name, source_name)

    define_method "#{name}" do
      through_opts = self.class.assoc_options[through_name]
      source_opts = through_opts.model_class.assoc_options[source_name]

      source_table = source_opts.model_class.table_name
      through_table = through_opts.model_class.table_name
      target_id = self.send("#{through_opts.foreign_key}")

      result = DBConnection.execute(<<-SQL, target_id).first
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table} ON #{through_table}.#{source_opts.foreign_key}  = #{source_table}.#{source_opts.primary_key}
        WHERE
          #{through_table}.id = ?
      SQL

      source_opts.model_class.new(result)
    end
  end
end
