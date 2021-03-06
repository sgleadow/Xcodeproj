module Xcodeproj
  class Project

    # This class represents relationships to other objects stored in a
    # Dictionary.
    #
    # It works in conjunction with the {AbstractObject} class to ensure that
    # the project is not serialized with unreachable objects by updating the
    # with reference count on modifications.
    #
    # @note This class is a stub currently only being used by
    #       {PBXProject#project_references}. It doesn't perform type cheeking
    #       and the keys of the dictionary are in camel-case. To provide full
    #       support as the other classes the dictionary should be able to
    #
    #       Give the following attribute:
    #
    #            has_many_references_by_keys :project_references, {
    #              :project_ref   => PBXFileReference,
    #              :product_group => PBXGroup
    #            }
    #
    #       This should be possible:
    #
    #            #=> Note the API:
    #            root_object.project_references.project_ref = file
    #
    #            #=> This should raise:
    #            root_object.project_references.product_group = file
    #
    #       generate setters and getters from the specification hash.
    #
    #       Also the interface is a dirty hybrid between the
    #       {AbstractObjectAttribute} and the {ObjectList}.
    #
    # @note Concerning the mutations methods it is safe to call only those
    #       which are overridden to inform objects reference count. Ideally all
    #       the hash methods should be covered, but this is not done yet.
    #       Moreover it is a moving target because the methods of array
    #       usually are implemented in C
    #
    # @todo Cover all the mutations methods of the {Hash} class.
    #
    class ObjectDictionary < Hash

      # {Xcodeproj} clients are not expected to create instances of
      # {ObjectDictionary}, it is always initialized empty and automatically by
      # the synthesized methods generated by {AbstractObject.has_many}.
      #
      def initialize(attribute, owner)
        @attribute = attribute
        @owner = owner
      end

      # @return [Array<Class>] The attribute that generated the list.
      #
      attr_reader :attribute

      # @return [Array<Class>] The object that owns the list.
      #
      attr_reader :owner

      #------------------------------------------------------------------------#

      # @!group Notification enabled methods

      # TODO: the overridden methods are incomplete.

      # Associates an object to the given key and updates its references count.
      #
      # @param [String] key
      #   the key
      #
      # @param [AbstractObject] object
      #   the object to add to the dictionary.
      #
      # @return [void]
      #
      def []=(key, object)
        if object
          perform_additions_operations(object)
        else
          perform_deletion_operations(self[key])
        end
        super
      end

      # Removes the given key from the dictionary and informs the object that
      # is not longer referenced by the owner.
      #
      # @param [String] key
      #   the key
      #
      # @return [void]
      #
      def delete(key)
        object = self[key]
        perform_deletion_operations(object)
        super
      end

      #------------------------------------------------------------------------#

      # @!group AbstractObject

      # The plist representation of the dictionary where the objects are
      # replaced by their UUIDs.
      #
      # @return [Hash<String => String>]
      #
      def to_hash
        result = {}
        each { |key, obj| result[key] = obj.uuid }
        result
      end

      # Returns a cascade representation of the object without UUIDs.
      #
      # @return [Hash<String => String>]
      #
      def to_tree_hash
        result = {}
        each { |key, obj| result[key] = obj.to_tree_hash }
        result
      end

      # Removes all the references to a given object.
      #
      # @return [void]
      #
      def remove_reference(object)
        each { |key, obj| self[key] = nil if obj == object }
      end

      #------------------------------------------------------------------------#

      # @!group ObjectList

      # Informs the objects contained in the dictionary that another object is
      # referencing them.
      #
      # @return [void]
      #
      def add_referrer(referrer)
        values.each { |obj| obj.add_referrer(referrer) }
      end

      # Informs the objects contained in the dictionary that another object
      # stopped referencing them.
      #
      # @return [void]
      #
      def remove_referrer(referrer)
        values.each { |obj| obj.remove_referrer(referrer) }
      end

      #------------------------------------------------------------------------#

      # @!group Notification Methods

      private

      # Informs an object that it was added to the dictionary. In practice it
      # adds the owner of the list as referrer to the objects. It also
      # validates the value.
      #
      # @return [void]
      #
      def perform_additions_operations(objects)
        objects = [objects] unless objects.is_a?(Array)
        objects.each do |obj|
          obj.add_referrer(owner)
          attribute.validate_value(obj)
        end
      end

      # Informs an object that it was removed from to the dictionary, so it can
      # remove it from its referrers and take the appropriate actions.
      #
      # @return [void]
      #
      def perform_deletion_operations(objects)
        objects = [objects] unless objects.is_a?(Array)
        objects.each do |obj|
          obj.remove_referrer(owner)
        end
      end
    end
  end
end

