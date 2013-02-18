module HydraAttribute
  module Model
    module Cacheable
      extend ActiveSupport::Concern

      included do
        register_nested_cache :model
      end

      module ClassMethods
        # Finds all records and store them into the cache
        #
        # @return [Array<HydraAttribute::Cacheable>]
        def all
          return identity_map[:all] if identity_map.has_key?(:all)

          ids = nested_identity_map(:model).keys
          ids.present? ? where_not(id: ids) : where

          identity_map[:all] = []
          nested_identity_map(:model).each do |_, model|
            add_to_cache(model)
          end
          identity_map[:all]
        end

        # Find record by ID and store it into the cache
        #
        # @return [HydraAttribute::Cacheable]
        def find(id)
          model = get_from_nested_cache_or_load_all_models(:model, id.to_i)
          raise RecordNotFound, "Couldn't find #{name} with id=#{id}" unless model
          model
        end

        # Gets data from cache or load all models and repeats the operation
        #
        # @param [Symbol] nested_cache_key
        # @param [Object] identifier
        # @return [Object]
        def get_from_nested_cache_or_load_all_models(nested_cache_key, identifier)
          return nested_identity_map(nested_cache_key)[identifier] if nested_identity_map(nested_cache_key).has_key?(identifier)
          all # preload all models
          nested_identity_map(nested_cache_key)[identifier]
        end

        # Add model to all cache objects
        # This method should not be used outside the model
        #
        # @param [HydraAttribute::Model::Cacheable]
        # @return [NilClass]
        def add_to_cache(model)
          ([:all] + nested_cache_keys).each do |nested_cache_key|
            method = "add_to_#{nested_cache_key}_cache"
            send(method, model) if respond_to?(method, true)
          end
        end

        # Delete model from all cache objects
        # This method should not be used outside the model
        #
        # @param [HydraAttribute::Model::Cacheable]
        # @return [NilClass]
        def delete_from_cache(model)
          ([:all] + nested_cache_keys).each do |nested_cache_key|
            method = "delete_from_#{nested_cache_key}_cache"
            send(method, model) if respond_to?(method, true)
          end
        end

        private
          # Add model to the :all cache storage
          #
          # @param [HydraAttribute::Model::Cacheable]
          # @return [NilClass]
          def add_to_all_cache(model)
            return unless identity_map[:all]
            identity_map[:all].push(model)
          end

          # Delete from :all cache storage
          #
          # @param [HydraAttribute::Model::Cacheable]
          # @return [NilClass]
          def delete_from_all_cache(model)
            return unless identity_map[:all]
            identity_map[:all].delete(model)
          end

          # Add model to the cache
          #
          # @param [HydraAttribute::Model::Cacheable] model
          # @return [NilClass]
          def add_to_model_cache(model)
            nested_identity_map(:model)[model.id] = model
          end

          # Delete model from the cache
          #
          # @param [HydraAttribute::Model::Cacheable] model
          # @return [NilClass]
          def delete_from_model_cache(model)
            nested_identity_map(:model).delete(model.id)
          end
      end

      # Initialize a model
      # Save it into the cache if it is persisted
      def initialize(attributes = {})
        super(attributes)
        self.class.add_to_cache(self) if persisted?
      end

      private
        # Create new model and store it into the cache
        #
        # @return [Fixnum]
        def create
          id = super
          self.class.add_to_cache(self)
          id
        end

        # Delete model and remove it from the cache
        #
        # @return [TrueClass]
        def delete
          result = super
          self.class.delete_from_cache(self)
          result
        end
    end
  end
end