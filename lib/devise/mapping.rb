module Devise
  # Responsible for handling devise mappings and routes configuration. Each
  # resource configured by devise_for in routes is actually creating a mapping
  # object. You can refer to devise_for in routes for usage options.
  #
  # The required value in devise_for is actually not used internally, but it's
  # inflected to find all other values.
  #
  #   map.devise_for :users
  #   mapping = Devise.mappings[:user]
  #
  #   mapping.name #=> :user
  #   # is the scope used in controllers and warden, given in the route as :singular.
  #
  #   mapping.as   #=> "users"
  #   # how the mapping should be search in the path, given in the route as :as.
  #
  #   mapping.to   #=> User
  #   # is the class to be loaded from routes, given in the route as :class_name.
  #
  #   mapping.modules  #=> [:authenticatable]
  #   # is the modules included in the class
  #
  class Mapping #:nodoc:
    attr_reader :name, :as, :controllers, :path_names, :path_prefix

    # Loop through all mappings looking for a map that matches with the requested
    # path (ie /users/sign_in). If a path prefix is given, it's taken into account.
    def self.find_by_path(path)
      Devise.mappings.each_value do |mapping|
        route = path.split("/")[mapping.as_position]
        return mapping if route && mapping.as == route.to_sym
      end
      nil
    end

    # Find a mapping by a given class. It takes into account single table inheritance as well.
    def self.find_by_class(klass)
      Devise.mappings.each_value do |mapping|
        return mapping if klass <= mapping.to
      end
      nil
    end

    # Receives an object and find a scope for it. If a scope cannot be found,
    # raises an error. If a symbol is given, it's considered to be the scope.
    def self.find_scope!(duck)
      case duck
      when String, Symbol
        duck
      else
        klass = duck.is_a?(Class) ? duck : duck.class
        mapping = Devise::Mapping.find_by_class(klass)
        raise "Could not find a valid mapping for #{duck}" unless mapping
        mapping.name
      end
    end

    def initialize(name, options) #:nodoc:
      @as    = (options.delete(:as) || name).to_sym
      @klass = (options.delete(:class_name) || name.to_s.classify).to_s
      @name  = (options.delete(:scope) || name.to_s.singularize).to_sym

      @path_prefix = "/#{options.delete(:path_prefix)}/".squeeze("/")

      @controllers = Hash.new { |h,k| h[k] = "devise/#{k}" }
      @controllers.merge!(options.delete(:controllers) || {})

      @path_names  = Hash.new { |h,k| h[k] = k.to_s }
      @path_names.merge!(options.delete(:path_names) || {})
    end

    # Return modules for the mapping.
    def modules
      @modules ||= to.devise_modules
    end

    # Gives the class the mapping points to.
    # Reload mapped class each time when cache_classes is false.
    def to
      return @to if @to
      klass = @klass.constantize
      @to = klass if Rails.configuration.cache_classes
      klass
    end

    # Keep a list of allowed controllers for this mapping. It's useful to ensure
    # that an Admin cannot access the registrations controller unless it has
    # :registerable in the model.
    def allowed_controllers
      @allowed_controllers ||= begin
        canonical = CONTROLLERS.values_at(*self.modules).compact
        @controllers.values_at(*canonical)
      end
    end

    # Return in which position in the path prefix devise should find the as mapping.
    def as_position
      self.path_prefix.count("/")
    end

    # Returns the raw path using path_prefix and as.
    def path
      path_prefix + as.to_s
    end

    # Create magic predicates for verifying what module is activated by this map.
    # Example:
    #
    #   def confirmable?
    #     self.modules.include?(:confirmable)
    #   end
    #
    def self.register(*modules)
      modules.each do |m|
        class_eval <<-METHOD, __FILE__, __LINE__ + 1
          def #{m}?
            self.modules.include?(:#{m})
          end
        METHOD
      end
    end
    Devise::Mapping.register *ALL
  end
end
