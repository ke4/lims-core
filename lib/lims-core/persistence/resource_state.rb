# vi: ts=2:sts=2:et:sw=2 spell:spelllang=en
require 'virtus'

require 'lims-core/resource'
require 'lims-core/persistence/persistor'

module Lims::Core
  module Persistence
    # Hold different information relateed particular resource
    # within a {Session}/{Persistor}.
    # This could be the database id, the current saving state etc ...
    class ResourceState
      include Virtus
      attribute :id, Object
      attribute :resource, Object, :writer => :private, :required => true
      attribute :persistor, Persistor, :writer => :private, :required => true
      attribute :to_delete, Object, :writer => :private

      def initialize(resource, persistor, id=nil)
        @resource=resource
        @persistor=persistor
        self.id=id if id
        @to_delete = false
        update_dirty_key
        reset

      end

      def dirty_key
        @persistor.dirty_key_for(resource)
      end

      def update_dirty_key
        @last_dirty_key = @persistor.dirty_key_for(resource)
      end

      def new?
        @id == nil
      end

      def dirty?
       @body_saved == false && dirty_key != @last_dirty_key
      end

      def id=(new_id)
        raise RuntimeError, "modifing existing id not allowed. #{self}"   if @id
        @id = new_id
        # link the new id in th id_to_state map
        @persistor.bind_state_to_id(self)
      end

      def mark_for_deletion
        @to_delete = true
      end

      # @todo use state machine ?
      def save_action
        case
        when to_delete && !new? then :delete
        when new? then :insert
        when dirty? then :update
        end
      end

      def inserted(new_id=nil)
        self.id = new_id
        update_dirty_key
      end

      def parents_saved!
        @parents_saved = true
      end
      def parents
        !@parents_saved && @persistor.parents_for(resource)
      end
      def parents!
        parents.tap { parents_saved! }
      end
      def children_saved!
        @children_saved = true
      end
      def children
        !@children_saved && @persistor.children_for(resource)
      end
      def children!
        children.tap { children_saved! }
      end
      def body_saved!
        @body_saved = true
      end

        def reset
          @parents_saved = nil
          @children_saved = nil
          @body_saved= nil
        end
      end
    end
  end

