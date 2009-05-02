module Sequel
  module Plugins
    module StiNestedSet
      class Error < ::Sequel::Error; end

      def self.apply(model, options={})
        def model.nested_set_options
          @nested_set_options
        end

        def model.nested_set_options=(options)
          @nested_set_options = options
        end

        model.nested_set_options = {
          :parent_id_column => :parent_id,
          :left_column      => :left,
          :right_column     => :right,
          :sti_key          => nil
        }.merge(options)

        model.set_dataset(
          model.dataset.order(
            model.nested_set_options[:left_column]
          )
        )

        if key = model.nested_set_options[:sti_key]
          m = model.method(:constantize)
          model.dataset.row_proc = Proc.new do |r|
            m.call(r[key]).load(r)
          end
        end
      end

      module ClassMethods
        def inherited(subclass)
          super

          def subclass.nested_set_options
            @nested_set_options
          end

          def subclass.nested_set_options=(options)
            @nested_set_options = options
          end

          subclass.nested_set_options = nested_set_options

          if subclass.nested_set_options[:sti_key]
            subclass.dataset.row_proc = dataset.row_proc
          end
        end

        def parent_id_column
          @nested_set_options[:parent_id_column]
        end

        def left_column
          @nested_set_options[:left_column]
        end

        def right_column
          @nested_set_options[:right_column]
        end

        def root
          dataset.filter(parent_id_column => nil).first
        end

        def roots
          dataset.filter(parent_id_column => nil).all
        end
      end

      module InstanceMethods
        def before_create
          super

          self.left  = model.dataset.max(self.class.right_column).to_i + 1
          self.right = self.left + 1

          if model.nested_set_options[:sti_key]
            send("#{model.nested_set_options[:sti_key]}=", model.name.to_s)
          end
        end

        def parent
          model.dataset.filter(primary_key => parent_id).first
        end

        def parent=(node)
          move_to_child_of(node)
        end

        def parent_id
          self[self.class.parent_id_column]
        end

        def left
          self[self.class.left_column]
        end

        def right
          self[self.class.right_column]
        end

        def ancestors
          return nil unless exists?

          model.dataset.filter((
            self.class.left_column < left
          ) & (
            self.class.right_column > right
          ))
        end

        def self_and_ancestors
          return nil unless exists?

          model.dataset.filter((
            self.class.left_column <= left
          ) & (
            self.class.right_column >= right
          ))
        end

        def siblings
          return nil unless exists?

          model.dataset.filter(~{
            self.class.primary_key => self.id
          } & {
            self.class.parent_id_column => parent_id
          })
        end

        def self_and_siblings
          return nil unless exists?

          model.dataset.filter({
            self.primary_key => self.id
          } | {
            self.class.parent_id_column => parent_id
          })
        end

        def level
          return nil unless exists?

          if self[self.class.parent_id_column].nil?
            0
          else
            ancestors.count
          end
        end

        def children_count
          return nil unless exists?

          (right - left - 1) / 2
        end

        def children
          return nil unless exists?

          model.dataset.filter(self.class.parent_id_column => self.id)
        end

        def all_children
          return nil unless exists?

          model.dataset.filter((
            self.class.left_column > left
          ) & (
            self.class.right_column < right
          ))
        end

        def full_set
          return nil unless exists?

          model.dataset.filter((
            self.class.left_column >= left
          ) & (
            self.class.right_column <= right
          ))
        end

        def move_to_child_of(node)
          move_to(node, :child)
        end

        def move_to_right_of(node)
          move_to(node, :right)
        end

        def move_to_left_of(node)
          move_to(node, :left)
        end

        def move_to(target, position)
          raise Sequel::Plugins::StiNestedSet::Error,
            'You cannot move a new node' unless exists?

          db.transaction do
            reload
            cur_left  = left
            cur_right = right

            target.reload
            target_left  = target.left
            target_right = target.right

            extent = cur_right - cur_left + 1

            if ((cur_left <= target_left ) && (target_left  <= cur_right)) ||
               ((cur_left <= target_right) && (target_right <= cur_right))
              raise Sequel::Plugins::StiNestedSet::Error,
                'Impossible move, target node cannot be inside moved tree.'
            end

            case position
            when :child
              if target_left < cur_left
                new_left  = target_left + 1
                new_right = target_left + extent
              else
                new_left  = target_left - extent + 1
                new_right = target_left
              end
            when :left
              if target_left < cur_left
                new_left  = target_left
                new_right = target_left + extent - 1
              else
                new_left  = target_left - extent
                new_right = target_left - 1
              end
            when :right
              if target_right < cur_right
                new_left  = target_right + 1
                new_right = target_right + extent 
              else
                new_left  = target_right - extent + 1
                new_right = target_right
              end
            else
              raise Sequel::Plugins::StiNestedSet::Error,
                "Position should be either child, left or right "
                "('#{position}' received)."
            end

            b_left  = [cur_left,  new_left ].min
            b_right = [cur_right, new_right].max
            
            shift = new_left - cur_left
            
            updown = (shift > 0) ? -extent : extent

            new_parent = if position == :child
              target.id
            else
              if target.parent_id.nil?
                'NULL'
              else
                target.parent_id
              end
            end

            model.dataset.update <<END_OF_SQL
  #{self.class.left_column} = CASE
  WHEN #{self.class.left_column} BETWEEN #{cur_left} AND #{cur_right}
    THEN #{self.class.left_column} + #{shift}
  WHEN #{self.class.left_column} BETWEEN #{b_left} AND #{b_right}
    THEN #{self.class.left_column} + #{updown}
    ELSE #{self.class.left_column} END,
  #{self.class.right_column} = CASE
  WHEN #{self.class.right_column} BETWEEN #{cur_left} AND #{cur_right}
    THEN #{self.class.right_column} + #{shift}
  WHEN #{self.class.right_column} BETWEEN #{b_left} AND #{b_right}
    THEN #{self.class.right_column} + #{updown}
    ELSE #{self.class.right_column}
  END,

  #{self.class.parent_id_column} = CASE
  WHEN #{self.primary_key} = #{self.id}
    THEN #{new_parent}
    ELSE #{self.class.parent_id_column}
  END
END_OF_SQL

            target.reload
            reload
          end
        end
      end

      #module DatasetMethods
      #end
    end
  end
end
