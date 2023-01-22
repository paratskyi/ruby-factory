# * Here you must define your `Factory` class.
# * Each instance of Factory could be stored into variable. The name of this variable is the name of created Class
# * Arguments of creatable Factory instance are fields/attributes of created class
# * The ability to add some methods to this class must be provided while creating a Factory
# * We must have an ability to get/set the value of attribute like [0], ['attribute_name'], [:attribute_name]
#
# * Instance of creatable Factory class should correctly respond to main methods of Struct
# - each
# - each_pair
# - dig
# - size/length
# - members
# - select
# - to_a
# - values_at
# - ==, eql?
class Factory
  def self.new(*arguments, &block)
    @class_name = arguments.delete_at(0) if arguments.first.is_a? String
    @arguments = arguments
    if @class_name
      const_set(@class_name, create_class(@arguments, &block))
    else
      create_class(@arguments, &block)
    end
  end

  def self.create_class(arguments, &block)
    Class.new do
      attr_accessor(*arguments)

      define_method :initialize do |*values|
        raise ArgumentError if values.length > arguments.length

        Hash[arguments.zip(values)].each { |argument, value| instance_variable_set("@#{argument}", value) }
      end

      def ==(other)
        if other.is_a? self.class
          instance_variables.each do |variable|
            return false if instance_variable_get(variable) != other.instance_variable_get(variable)
          end
          true
        else
          false
        end
      end

      def [](variable)
        return instance_variable_get("@#{variable}") if variable.is_a? String
        return instance_variable_get("@#{variable}") if variable.is_a? Symbol
        return instance_variable_get(instance_variables[variable]) if variable.is_a? Integer
      end

      def []=(variable, value)
        instance_variable_set("@#{variable}", value) if variable.is_a? String
        instance_variable_set("@#{variable}", value) if variable.is_a? Symbol
        instance_variable_set(instance_variables[variable], value) if variable.is_a? Integer
      end

      def dig(key, *rest)
        value = self[key]
        if value.nil?
          value
        elsif value.respond_to?(:dig)
          value.dig(*rest)
        end
      end

      def each
        instance_variables.map { |attribute| yield(instance_variable_get(attribute)) }
      end

      def each_pair
        instance_variables.map { |attribute| yield(attribute.to_s.delete('@'), instance_variable_get(attribute)) }
      end

      def length
        instance_variables.length
      end

      def members
        instance_variables.map { |attribute| attribute.to_s.delete('@').to_sym }
      end

      def select
        result = instance_variables.map do |attribute|
          instance_variable_get(attribute) if yield(instance_variable_get(attribute))
        end
        result.compact
      end

      def to_a
        instance_variables.map { |attribute| instance_variable_get(attribute) }
      end

      def values_at(*selectors)
        result = instance_variables.map { |attribute| instance_variable_get(attribute) }
        selectors.map { |selector| result[selector] }
      end

      alias_method :size, :length
      alias_method :eql, :==

      class_eval(&block) if block_given?
    end
  end
end
