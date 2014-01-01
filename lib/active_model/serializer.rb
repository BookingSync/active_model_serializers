require 'active_model/array_serializer'
require 'active_model/serializable'
require 'active_model/serializer/associations'
require 'active_model/serializer/config'

require 'thread'

module ActiveModel
  class Serializer
    include Serializable

    @mutex = Mutex.new

    class << self
      def inherited(base)
        base._root = _root
        base._attributes = (_attributes || []).dup
        base._associations = (_associations || {}).dup
      end

      def setup
        @mutex.synchronize do
          yield CONFIG
        end
      end

      def embed(type, options={})
        CONFIG.embed = type
        CONFIG.embed_in_root = true if options[:embed_in_root] || options[:include]
        ActiveSupport::Deprecation.warn <<-WARN
** Notice: embed is deprecated. **
The use of .embed method on a Serializer will be soon removed, as this should have a global scope and not a class scope.
Please use the global .setup method instead:
ActiveModel::Serializer.setup do |config|
  config.embed = :#{type}
  config.embed_in_root = #{CONFIG.embed_in_root || false}
end
        WARN
      end

      if RUBY_VERSION >= '2.0'
        def serializer_for(resource)
          if resource.respond_to?(:to_ary)
            ArraySerializer
          else
            begin
              Object.const_get "#{resource.class.name}Serializer"
            rescue NameError
              nil
            end
          end
        end
      else
        def serializer_for(resource)
          if resource.respond_to?(:to_ary)
            ArraySerializer
          else
            "#{resource.class.name}Serializer".safe_constantize
          end
        end
      end

      attr_accessor :_root, :_attributes, :_associations
      alias root  _root=
      alias root= _root=

      def root_name
        name.demodulize.underscore.sub(/_serializer$/, '') if name
      end

      def attributes(*attrs)
        @_attributes.concat attrs

        attrs.each do |attr|
          define_method attr do
            object.read_attribute_for_serialization attr
          end unless method_defined?(attr)
        end
      end

      def has_one(*attrs)
        associate(Association::HasOne, *attrs)
      end

      def has_many(*attrs)
        associate(Association::HasMany, *attrs)
      end

      private

      def associate(klass, *attrs)
        options = attrs.extract_options!

        attrs.each do |attr|
          define_method attr do
            object.send attr
          end unless method_defined?(attr)

          @_associations[attr] = klass.new(attr, options)
        end
      end
    end

    def initialize(object, options={})
      @object               = object
      @scope                = options[:scope]
      @root                 = options.fetch(:root, self.class._root)
      @meta_key             = options[:meta_key] || :meta
      @meta                 = options[@meta_key]
      @only                 = Array(options[:only]) if options[:only]
      @except               = Array(options[:except]) if options[:except]
      @wrap_in_array        = options[:_wrap_in_array]
      @fields               = options[:fields]
      @include_associations = Array(options[:include])
      @url_options          = options[:url_options]
    end

    attr_accessor :object, :scope, :root, :meta_key, :meta, :fields
    attr_reader :url_options

    def json_key
      if root == true || root.nil?
        self.class.root_name
      else
        root
      end
    end

    def attributes
      filterize_keys(self.class._attributes.dup).each_with_object({}) do |name, hash|
        hash[name] = send(name)
      end
    end

    def associations
      associations = self.class._associations
      included_associations = filterize_associations(associations).keys
      associations.each_with_object({}) do |(name, association), hash|
        if included_associations.include? name
          if association.embed_ids?
            hash[association.key] = serialize_ids association
          elsif association.embed_objects?
            hash[association.embedded_key] = serialize association
          end
        end
      end
    end

    # First filters associations using #filter method
    # which can be overwritten by user
    # then removes all associations which are hidden e.g
    # with option visible: false
    def filterize_associations(associations)
      filtered_associations = filter(associations.keys)
      associations.reject do |name, association|
        next true if filtered_associations.exclude?(name)
        next false if @include_associations.include?(name)
        true if association.hidden?
      end
    end

    # First filters keys using #filter method which can be overwritten
    # by user, then if fields is present, shows only keys which are
    # in fields
    def filterize_keys(keys)
      filtered = filter(keys)
      if fields.present?
        filtered & fields
      else
        filtered
      end
    end

    # this method can be overwritten in serializer
    # and it's a part of AMS API that's why filterize_associations
    # and filterize_keys
    def filter(keys)
      if @only
        keys & @only
      elsif @except
        keys - @except
      else
        keys
      end
    end

    def embedded_in_root_associations
      associations = self.class._associations
      included_associations = filterize_associations(associations).keys
      associations.each_with_object({}) do |(name, association), hash|
        if included_associations.include? name
          if association.embed_in_root?
            association_serializer = build_serializer(association)
            hash.merge! association_serializer.embedded_in_root_associations

            serialized_data = association_serializer.serializable_object
            key = association.root_key
            if hash.has_key?(key)
              hash[key].concat(serialized_data).uniq!
            else
              hash[key] = serialized_data
            end
          end
        end
      end
    end

    def build_serializer(association)
      object = send(association.name)
      association.build_serializer(object, scope: scope, url_options: url_options)
    end

    def serialize(association)
      build_serializer(association).serializable_object
    end

    def serialize_ids(association)
      associated_data = send(association.name)
      if associated_data.respond_to?(:to_ary)
        associated_data.map { |elem| elem.read_attribute_for_serialization(association.embed_key) }
      else
        associated_data.read_attribute_for_serialization(association.embed_key) if associated_data
      end
    end

    def serializable_object(options={})
      return @wrap_in_array ? [] : nil if @object.nil?
      hash = attributes
      hash.merge! associations
      if respond_to?(:_links_templates) && _links_templates.present?
        hash.merge!("_links_templates" => _links_templates)
      end
      @wrap_in_array ? [hash] : hash
    end
    alias_method :serializable_hash, :serializable_object
  end
end
