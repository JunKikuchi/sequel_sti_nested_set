require 'rubygems'
require 'sequel'
require 'lib/sequel_sti_nested_set'
require 'spec/spec_config'

class Node < Sequel::Model
  plugin :sti_nested_set, :sti_key => :class
  plugin :schema

  set_schema do
    primary_key :id
    column :parent_id, :integer
    column :left,      :integer
    column :right,     :integer
    column :class,     :string
  end
end

class ExNode < Node
end

shared_examples_for 'インターフェース' do
  it 'クラス' do
    %w'nested_set_options nested_set_options= parent_id_column left_column right_column root roots'.each do |val|
      @class1.should respond_to val.to_sym
    end
  end

  it 'インスタンス' do
    %w'parent parent= left right ancestors self_and_ancestors siblings self_and_ancestors full_set move_to_child_of move_to_left_of move_to_right_of'.each do |val|
      @obj.should respond_to val.to_sym
    end
  end
end

shared_examples_for 'save 前の値' do
  it 'クラス' do
    @class1.root.should be_nil
    @class1.roots.should == []
  end

  it 'インスタンス' do
    %w'parent left right ancestors self_and_ancestors siblings self_and_siblings level children_count children all_children full_set'.each do |val|
      @obj.send(val.to_sym).should be_nil
    end

    %w'parent= move_to_child_of move_to_left_of move_to_right_of'.each do |val|
      lambda do
        @obj.send(val.to_sym, Node.new)
      end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
    end
  end
end

shared_examples_for 'save 後の値' do
  it 'クラス' do
    @class1.root.should == @obj
    @class1.roots.should == [@obj]
  end

  it 'class.root == self' do
    @obj.class.root.should == @obj
    @obj.class.root.should == @obj.class.roots.first
  end

  it 'class.roots == [self]' do
    @obj.class.roots.should == [@obj]
  end

  it 'parent == nil' do
    @obj.parent.should be_nil
  end

  it 'left == 1' do
    @obj.left.should == 1
  end

  it 'right == 2' do
    @obj.right.should == 2
  end

  it 'ancestors.all == []' do
    @obj.ancestors.all.should == []
  end

  it 'self_and_ancestors.all == [self]' do
    @obj.self_and_ancestors.all.should == [@obj]
  end

  it 'siblings == []' do
    @obj.siblings.all.should == []
  end

  it 'self_and_siblings == [self]' do
    @obj.self_and_siblings.all.should == [@obj]
  end

  it 'level == 0' do
    @obj.level.should be_zero
  end

  it 'children_count == 0' do
    @obj.children_count.should be_zero
  end

  it 'all_children.all == []' do
    @obj.all_children.all.should == []
  end

  it 'full_set.all == [self]' do
    @obj.full_set.all.should == [@obj]
  end
end

shared_examples_for '[@node1], [@node2], [@node3]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1, @node2, @node3]
  end

  it 'parent, left, right の値' do
    @node1.parent.should be_nil
    @node2.parent.should be_nil
    @node3.parent.should be_nil

    @node1.left.should  == 1
    @node1.right.should == 2
    @node2.left.should  == 3
    @node2.right.should == 4
    @node3.left.should  == 5
    @node3.right.should == 6
  end

  it 'ancestors.all == []' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all == [self]' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings == []' do
    @node1.siblings.all.should == [@node2, @node3]
    @node2.siblings.all.should == [@node1, @node3]
    @node3.siblings.all.should == [@node1, @node2]
  end

  it 'self_and_siblings == [self]' do
    @node1.self_and_siblings.all.should == [@node1, @node2, @node3]
    @node2.self_and_siblings.all.should == [@node1, @node2, @node3]
    @node3.self_and_siblings.all.should == [@node1, @node2, @node3]
  end

  it 'level == 0' do
    @node1.level.should be_zero
    @node2.level.should be_zero
    @node3.level.should be_zero
  end

  it 'children_count == 0' do
    @node1.children_count.should be_zero
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all == []' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all == [self]' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node1], [@node3], [@node2]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1, @node3, @node2]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should be_nil
    @node3.parent.should be_nil

    @node1.left.should  == 1
    @node1.right.should == 2
    @node3.left.should  == 3
    @node3.right.should == 4
    @node2.left.should  == 5
    @node2.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node3, @node2]
    @node2.siblings.all.should == [@node1, @node3]
    @node3.siblings.all.should == [@node1, @node2]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1, @node3, @node2]
    @node2.self_and_siblings.all.should == [@node1, @node3, @node2]
    @node3.self_and_siblings.all.should == [@node1, @node3, @node2]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should be_zero
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node2], [@node3], [@node1]' do
  it 'class.root' do
    @node1.class.root.should == @node2
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node2, @node3, @node1]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should be_nil
    @node3.parent.should be_nil

    @node2.left.should  == 1
    @node2.right.should == 2
    @node3.left.should  == 3
    @node3.right.should == 4
    @node1.left.should  == 5
    @node1.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node2, @node3]
    @node2.siblings.all.should == [@node3, @node1]
    @node3.siblings.all.should == [@node2, @node1]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node2, @node3, @node1]
    @node2.self_and_siblings.all.should == [@node2, @node3, @node1]
    @node3.self_and_siblings.all.should == [@node2, @node3, @node1]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should be_zero
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node2], [@node1], [@node3]' do
  it 'class.root' do
    @node1.class.root.should == @node2
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node2, @node1, @node3]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should be_nil
    @node3.parent.should be_nil

    @node2.left.should  == 1
    @node2.right.should == 2
    @node1.left.should  == 3
    @node1.right.should == 4
    @node3.left.should  == 5
    @node3.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node2, @node3]
    @node2.siblings.all.should == [@node1, @node3]
    @node3.siblings.all.should == [@node2, @node1]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node2, @node1, @node3]
    @node2.self_and_siblings.all.should == [@node2, @node1, @node3]
    @node3.self_and_siblings.all.should == [@node2, @node1, @node3]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should be_zero
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node3], [@node2], [@node1]' do
  it 'class.root' do
    @node1.class.root.should == @node3
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node3, @node2, @node1]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should be_nil
    @node3.parent.should be_nil

    @node3.left.should  == 1
    @node3.right.should == 2
    @node2.left.should  == 3
    @node2.right.should == 4
    @node1.left.should  == 5
    @node1.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node3, @node2]
    @node2.siblings.all.should == [@node3, @node1]
    @node3.siblings.all.should == [@node2, @node1]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node3, @node2, @node1]
    @node2.self_and_siblings.all.should == [@node3, @node2, @node1]
    @node3.self_and_siblings.all.should == [@node3, @node2, @node1]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should be_zero
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node3], [@node1], [@node2]' do
  it 'class.root' do
    @node1.class.root.should == @node3
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node3, @node1, @node2]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should be_nil
    @node3.parent.should be_nil

    @node3.left.should  == 1
    @node3.right.should == 2
    @node1.left.should  == 3
    @node1.right.should == 4
    @node2.left.should  == 5
    @node2.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node3, @node2]
    @node2.siblings.all.should == [@node3, @node1]
    @node3.siblings.all.should == [@node1, @node2]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node3, @node1, @node2]
    @node2.self_and_siblings.all.should == [@node3, @node1, @node2]
    @node3.self_and_siblings.all.should == [@node3, @node1, @node2]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should be_zero
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node1, [@node3]], [@node2]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1, @node2]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should be_nil
    @node3.parent.should == @node1

    @node1.left.should  == 1
    @node3.left.should  == 2
    @node3.right.should == 3
    @node1.right.should == 4
    @node2.left.should  == 5
    @node2.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == [@node1]
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node1, @node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node2]
    @node2.siblings.all.should == [@node1]
    @node3.siblings.all.should == []
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1, @node2]
    @node2.self_and_siblings.all.should == [@node1, @node2]
    @node3.self_and_siblings.all.should == [@node3]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should be_zero
    @node3.level.should == 1
  end

  it 'children_count' do
    @node1.children_count.should == 1
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == [@node3]
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1, @node3]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node1], [@node2, [@node3]]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1, @node2]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should be_nil
    @node3.parent.should == @node2

    @node1.left.should  == 1
    @node1.right.should == 2
    @node2.left.should  == 3
    @node3.left.should  == 4
    @node3.right.should == 5
    @node2.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == [@node2]
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node2, @node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node2]
    @node2.siblings.all.should == [@node1]
    @node3.siblings.all.should == []
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1, @node2]
    @node2.self_and_siblings.all.should == [@node1, @node2]
    @node3.self_and_siblings.all.should == [@node3]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should be_zero
    @node3.level.should == 1
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should == 1
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == [@node3]
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2, @node3]
    @node3.full_set.all.should == [@node3]
  end
end

=begin
shared_examples_for '[@node2, [@node3]], [@node1]' do
end

shared_examples_for '[@node2], [@node1, [@node3]]' do
end
=end

shared_examples_for '[@node1, [@node2]], [@node3]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1, @node3]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should == @node1
    @node3.parent.should be_nil

    @node1.left.should  == 1
    @node2.left.should  == 2
    @node2.right.should == 3
    @node1.right.should == 4
    @node3.left.should  == 5
    @node3.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == [@node1]
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node1, @node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node3]
    @node2.siblings.all.should == []
    @node3.siblings.all.should == [@node1]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1, @node3]
    @node2.self_and_siblings.all.should == [@node2]
    @node3.self_and_siblings.all.should == [@node1, @node3]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should == 1
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should == 1
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == [@node2]
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1, @node2]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node1], [@node3, [@node2]]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1, @node3]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should == @node3
    @node3.parent.should be_nil

    @node1.left.should  == 1
    @node1.right.should == 2
    @node3.left.should  == 3
    @node2.left.should  == 4
    @node2.right.should == 5
    @node3.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == [@node3]
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node3, @node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node3]
    @node2.siblings.all.should == []
    @node3.siblings.all.should == [@node1]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1, @node3]
    @node2.self_and_siblings.all.should == [@node2]
    @node3.self_and_siblings.all.should == [@node1, @node3]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should == 1
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should be_zero
    @node3.children_count.should == 1
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == []
    @node3.all_children.all.should == [@node2]
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3, @node2]
  end
end

=begin
shared_examples_for '[@node3, [@node2]], [@node1]' do
end
=end

shared_examples_for '[@node3], [@node1, [@node2]]' do
  it 'class.root' do
    @node1.class.root.should == @node3
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node3, @node1]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should == @node1
    @node3.parent.should be_nil

    @node3.left.should  == 1
    @node3.right.should == 2
    @node1.left.should  == 3
    @node2.left.should  == 4
    @node2.right.should == 5
    @node1.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == [@node1]
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node1, @node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == [@node3]
    @node2.siblings.all.should == []
    @node3.siblings.all.should == [@node1]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node3, @node1]
    @node2.self_and_siblings.all.should == [@node2]
    @node3.self_and_siblings.all.should == [@node3, @node1]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should == 1
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should == 1
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == [@node2]
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1, @node2]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node2, [@node1]], [@node3]' do
  it 'class.root' do
    @node1.class.root.should == @node2
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node2, @node3]
  end

  it 'parent, left, right' do
    @node1.parent.should == @node2
    @node2.parent.should be_nil
    @node3.parent.should be_nil

    @node2.left.should  == 1
    @node1.left.should  == 2
    @node1.right.should == 3
    @node2.right.should == 4
    @node3.left.should  == 5
    @node3.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == [@node2]
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node2, @node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == []
    @node2.siblings.all.should == [@node3]
    @node3.siblings.all.should == [@node2]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1]
    @node2.self_and_siblings.all.should == [@node2, @node3]
    @node3.self_and_siblings.all.should == [@node2, @node3]
  end

  it 'level' do
    @node1.level.should == 1
    @node2.level.should be_zero
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should == 1
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == [@node1]
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2, @node1]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node2], [@node3, [@node1]]' do
  it 'class.root' do
    @node1.class.root.should == @node2
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node2, @node3]
  end

  it 'parent, left, right' do
    @node1.parent.should == @node3
    @node2.parent.should be_nil
    @node3.parent.should be_nil

    @node2.left.should  == 1
    @node2.right.should == 2
    @node3.left.should  == 3
    @node1.left.should  == 4
    @node1.right.should == 5
    @node3.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == [@node3]
    @node2.ancestors.all.should == []
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node3, @node1]
    @node2.self_and_ancestors.all.should == [@node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == []
    @node2.siblings.all.should == [@node3]
    @node3.siblings.all.should == [@node2]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1]
    @node2.self_and_siblings.all.should == [@node2, @node3]
    @node3.self_and_siblings.all.should == [@node2, @node3]
  end

  it 'level' do
    @node1.level.should == 1
    @node2.level.should be_zero
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should be_zero
    @node2.children_count.should be_zero
    @node3.children_count.should == 1
  end

  it 'all_children.all' do
    @node1.all_children.all.should == []
    @node2.all_children.all.should == []
    @node3.all_children.all.should == [@node1]
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3, @node1]
  end
end

=begin
shared_examples_for '[@node3, [@node1]], [@node2]' do
end

shared_examples_for '[@node3], [@node2, [@node1]]' do
end
=end

shared_examples_for '[@node1, [@node2, @node3]]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should == @node1
    @node3.parent.should == @node1

    @node1.left.should  == 1
    @node2.left.should  == 2
    @node2.right.should == 3
    @node3.left.should  == 4
    @node3.right.should == 5
    @node1.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == [@node1]
    @node3.ancestors.all.should == [@node1]
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node1, @node2]
    @node3.self_and_ancestors.all.should == [@node1, @node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == []
    @node2.siblings.all.should == [@node3]
    @node3.siblings.all.should == [@node2]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1]
    @node2.self_and_siblings.all.should == [@node2, @node3]
    @node3.self_and_siblings.all.should == [@node2, @node3]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should == 1
    @node3.level.should == 1
  end

  it 'children_count' do
    @node1.children_count.should == 2
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == [@node2, @node3]
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1, @node2, @node3]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for '[@node1, [@node3, @node2]]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should == @node1
    @node3.parent.should == @node1

    @node1.left.should  == 1
    @node3.left.should  == 2
    @node3.right.should == 3
    @node2.left.should  == 4
    @node2.right.should == 5
    @node1.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == [@node1]
    @node3.ancestors.all.should == [@node1]
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node1, @node2]
    @node3.self_and_ancestors.all.should == [@node1, @node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == []
    @node2.siblings.all.should == [@node3]
    @node3.siblings.all.should == [@node2]
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1]
    @node2.self_and_siblings.all.should == [@node3, @node2]
    @node3.self_and_siblings.all.should == [@node3, @node2]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should == 1
    @node3.level.should == 1
  end

  it 'children_count' do
    @node1.children_count.should == 2
    @node2.children_count.should be_zero
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == [@node3, @node2]
    @node2.all_children.all.should == []
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1, @node3, @node2]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3]
  end
end

=begin
shared_examples_for '[@node2, [@node1, @node3]]' do
end

shared_examples_for '[@node2, [@node3, @node1]]' do
end

shared_examples_for '[@node3, [@node1, @node2]]' do
end

shared_examples_for '[@node3, [@node2, @node1]]' do
end
=end

shared_examples_for '[@node3, [@node1, [@node2]]]' do
  it 'class.root' do
    @node1.class.root.should == @node3
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node3]
  end

  it 'parent, left, right' do
    @node1.parent.should == @node3
    @node2.parent.should == @node1
    @node3.parent.should be_nil

    @node3.left.should  == 1
    @node1.left.should  == 2
    @node2.left.should  == 3
    @node2.right.should == 4
    @node1.right.should == 5
    @node3.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == [@node3]
    @node2.ancestors.all.should == [@node3, @node1]
    @node3.ancestors.all.should == []
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node3, @node1]
    @node2.self_and_ancestors.all.should == [@node3, @node1, @node2]
    @node3.self_and_ancestors.all.should == [@node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == []
    @node2.siblings.all.should == []
    @node3.siblings.all.should == []
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1]
    @node2.self_and_siblings.all.should == [@node2]
    @node3.self_and_siblings.all.should == [@node3]
  end

  it 'level' do
    @node1.level.should == 1
    @node2.level.should == 2
    @node3.level.should be_zero
  end

  it 'children_count' do
    @node1.children_count.should == 1
    @node2.children_count.should be_zero
    @node3.children_count.should == 2
  end

  it 'all_children.all' do
    @node1.all_children.all.should == [@node2]
    @node2.all_children.all.should == []
    @node3.all_children.all.should == [@node1, @node2]
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1, @node2]
    @node2.full_set.all.should == [@node2]
    @node3.full_set.all.should == [@node3, @node1, @node2]
  end
end

shared_examples_for '[@node1, [@node2, [@node3]]]' do
  it 'class.root' do
    @node1.class.root.should == @node1
    @node1.class.root.should == @node1.class.roots.first
  end

  it 'class.roots' do
    @node1.class.roots.should == [@node1]
  end

  it 'parent, left, right' do
    @node1.parent.should be_nil
    @node2.parent.should == @node1
    @node3.parent.should == @node2

    @node1.left.should  == 1
    @node2.left.should  == 2
    @node3.left.should  == 3
    @node3.right.should == 4
    @node2.right.should == 5
    @node1.right.should == 6
  end

  it 'ancestors.all' do
    @node1.ancestors.all.should == []
    @node2.ancestors.all.should == [@node1]
    @node3.ancestors.all.should == [@node1, @node2]
  end

  it 'self_and_ancestors.all' do
    @node1.self_and_ancestors.all.should == [@node1]
    @node2.self_and_ancestors.all.should == [@node1, @node2]
    @node3.self_and_ancestors.all.should == [@node1, @node2, @node3]
  end

  it 'siblings' do
    @node1.siblings.all.should == []
    @node2.siblings.all.should == []
    @node3.siblings.all.should == []
  end

  it 'self_and_siblings' do
    @node1.self_and_siblings.all.should == [@node1]
    @node2.self_and_siblings.all.should == [@node2]
    @node3.self_and_siblings.all.should == [@node3]
  end

  it 'level' do
    @node1.level.should be_zero
    @node2.level.should == 1
    @node3.level.should == 2
  end

  it 'children_count' do
    @node1.children_count.should == 2
    @node2.children_count.should == 1
    @node3.children_count.should be_zero
  end

  it 'all_children.all' do
    @node1.all_children.all.should == [@node2, @node3]
    @node2.all_children.all.should == [@node3]
    @node3.all_children.all.should == []
  end

  it 'full_set.all' do
    @node1.full_set.all.should == [@node1, @node2, @node3]
    @node2.full_set.all.should == [@node2, @node3]
    @node3.full_set.all.should == [@node3]
  end
end

shared_examples_for 'StiNestedSet' do
  describe 'インターフェース' do
    before do
      @obj = @class1.new
    end

    it_should_behave_like 'インターフェース'

    describe 'セーブ前' do
      it_should_behave_like 'save 前の値'
    end

    describe 'セーブ後' do
      before do
        @obj.save
      end

      it_should_behave_like 'save 後の値'
    end
  end
  describe '[@node1], [@node2], [@node3] からの操作' do
    before do
      @node1 = @class1.new
      @node1.save

      @node2 = @class2.new
      @node2.save

      @node3 = @class3.new
      @node3.save
    end

    it_should_behave_like '[@node1], [@node2], [@node3]'

    describe 'parent=' do
      it '@node1.parent = @node1' do
        lambda do
          @node1.parent = @node1
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node1.parent = @node2' do
        before do
          @node1.parent = @node2
          @node3.reload
        end

        it_should_behave_like '[@node2, [@node1]], [@node3]'
      end

      describe '@node1.parent = @node3' do
        before do
          @node1.parent = @node3
          @node2.reload
        end

        it_should_behave_like '[@node2], [@node3, [@node1]]'
      end

      describe '@node2.parent = @node1' do
        before do
          @node2.parent = @node1
          @node3.reload
        end

        it_should_behave_like '[@node1, [@node2]], [@node3]'
      end

      describe '@node2.parent = @node3' do
        before do
          @node2.parent = @node3
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node3, [@node2]]'
      end

      describe '@node3.parent = @node1' do
        before do
          @node3.parent = @node1
          @node2.reload
        end

        it_should_behave_like '[@node1, [@node3]], [@node2]'
      end

      describe '@node3.parnet = @node2' do
        before do
          @node3.parent = @node2
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node2, [@node3]]'
      end
    end

    describe 'move_to_child_of' do
      it '@node1.move_to_child_of @node1' do
        lambda do
          @node1.move_to_child_of @node1
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node1.move_to_child_of @node2' do
        before do
          @node1.move_to_child_of @node2
          @node3.reload
        end

        it_should_behave_like '[@node2, [@node1]], [@node3]'
      end

      describe '@node1.move_to_child_of @node3' do
        before do
          @node1.move_to_child_of @node3
          @node2.reload
        end

        it_should_behave_like '[@node2], [@node3, [@node1]]'
      end

      describe '@node2.move_to_child_of @node1' do
        before do
          @node2.move_to_child_of @node1
          @node3.reload
        end

        it_should_behave_like '[@node1, [@node2]], [@node3]'
      end

      describe '@node2.move_to_child_of @node3' do
        before do
          @node2.move_to_child_of @node3
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node3, [@node2]]'
      end

      describe '@node3.move_to_child_of @node1' do
        before do
          @node3.move_to_child_of @node1
          @node2.reload
        end

        it_should_behave_like '[@node1, [@node3]], [@node2]'
      end

      describe '@node3.move_to_child_of @node2' do
        before do
          @node3.move_to_child_of @node2
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node2, [@node3]]'
      end
    end

    describe 'move_to_left_of' do
      it '@node1.move_to_left_of @node1' do
        lambda do
          @node1.move_to_left_of @node1
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node1.move_to_left_of @node2' do
        before do
          @node1.move_to_left_of @node2
          @node3.reload
        end

        it_should_behave_like '[@node1], [@node2], [@node3]'
      end

      describe '@node1.move_to_left_of @node3' do
        before do
          @node1.move_to_left_of @node3
          @node2.reload
        end

        it_should_behave_like '[@node2], [@node1], [@node3]'
      end

      describe '@node2.move_to_left_of @node1' do
        before do
          @node2.move_to_left_of @node1
          @node3.reload
        end

        it_should_behave_like '[@node2], [@node1], [@node3]'
      end

      it '@node2.move_to_left_of @node2' do
        lambda do
          @node2.move_to_left_of @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node2.move_to_left_of @node3' do
        before do
          @node2.move_to_left_of @node3
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node2], [@node3]'
      end

      describe '@node3.move_to_left_of @node1' do
        before do
          @node3.move_to_left_of @node1
          @node2.reload
        end

        it_should_behave_like '[@node3], [@node1], [@node2]'
      end

      describe '@node3.move_to_left_of @node2' do
        before do
          @node3.move_to_left_of @node2
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node3], [@node2]'
      end

      it '@node3.move_to_left_of @node3' do
        lambda do
          @node3.move_to_left_of @node3
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end
    end

    describe 'move_to_right_of' do
      it '@node1.move_to_right_of @node1' do
        lambda do
          @node1.move_to_right_of @node1
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node1.move_to_right_of @node2' do
        before do
          @node1.move_to_right_of @node2
          @node3.reload
        end

        it_should_behave_like '[@node2], [@node1], [@node3]'
      end

      describe '@node1.move_to_right_of @node3' do
        before do
          @node1.move_to_right_of @node3
          @node2.reload
        end

        it_should_behave_like '[@node2], [@node3], [@node1]'
      end

      describe '@node2.move_to_right_of @node1' do
        before do
          @node2.move_to_right_of @node1
          @node3.reload
        end

        it_should_behave_like '[@node1], [@node2], [@node3]'
      end

      it '@node2.move_to_right_of @node2' do
        lambda do
          @node2.move_to_right_of @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node2.move_to_right_of @node3' do
        before do
          @node2.move_to_right_of @node3
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node3], [@node2]'
      end

      describe '@node3.move_to_right_of @node1' do
        before do
          @node3.move_to_right_of @node1
          @node2.reload
        end

        it_should_behave_like '[@node1], [@node3], [@node2]'
      end

      describe '@node3.move_to_right_of @node2' do
        before do
          @node3.move_to_right_of @node2
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node2], [@node3]'
      end

      it '@node3.move_to_right_of @node3' do
        lambda do
          @node3.move_to_right_of @node3
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end
    end
  end

  describe '[@node1, [@node2]], [@node3] からの操作' do
    before do
      @node1 = Node.new
      @node1.save

      @node2 = Node.new
      @node2.save

      @node2.parent = @node1

      @node3 = Node.new
      @node3.save

      @node1.reload
      @node2.reload
      @node3.reload
    end

    it_should_behave_like '[@node1, [@node2]], [@node3]'

    describe 'parent=' do
      it '@node1.parent = @node1' do
        lambda do
          @node1.parent = @node1
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      it'@node1.parent = @node2' do
        lambda do
          @node1.parent = @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node1.parent = @node3' do
        before do
          @node1.parent = @node3
          @node2.reload
        end

        it_should_behave_like '[@node3, [@node1, [@node2]]]'
      end

      describe '@node2.parent = @node1' do
        before do
          @node2.parent = @node1
          @node3.reload
        end

        it_should_behave_like '[@node1, [@node2]], [@node3]'
      end

      it '@node2.parent = @node2' do
        lambda do
          @node2.parent = @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node2.parent = @node3' do
        before do
          @node2.parent = @node3
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node3, [@node2]]'
      end

      describe '@node3.parent = @node1' do
        before do
          @node3.parent = @node1
          @node2.reload
        end

        it_should_behave_like '[@node1, [@node3, @node2]]'
      end

      describe '@node3.parent = @node2' do
        before do
          @node3.parent = @node2
          @node1.reload
        end

        it_should_behave_like '[@node1, [@node2, [@node3]]]'
      end

      it '@node3.parent = @node3' do
        lambda do
          @node3.parent = @node3
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end
    end

    describe 'move_to_child_of' do
      it '@node1.move_to_child_of @node1' do
        lambda do
          @node1.move_to_child_of @node1
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      it '@node1.move_to_child_of @node2' do
        lambda do
          @node1.move_to_child_of @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node1.move_to_child_of @node3' do
        before do
          @node1.move_to_child_of @node3
          @node2.reload
        end

        it_should_behave_like '[@node3, [@node1, [@node2]]]'
      end

      describe '@node2.move_to_child_of @node1' do
        before do
          @node2.move_to_child_of @node1
          @node3.reload
        end

        it_should_behave_like '[@node1, [@node2]], [@node3]'
      end

      it '@node2.move_to_child_of @node2' do
        lambda do
          @node2.move_to_child_of @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node2.move_to_child_of @node3' do
        before do
          @node2.move_to_child_of @node3
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node3, [@node2]]'
      end

      describe '@node3.move_to_child_of @node1' do
        before do
          @node3.move_to_child_of @node1
          @node2.reload
        end

        it_should_behave_like '[@node1, [@node3, @node2]]'
      end

      describe '@node3.move_to_child_of @node2' do
        before do
          @node3.move_to_child_of @node2
          @node1.reload
        end

        it_should_behave_like '[@node1, [@node2, [@node3]]]'
      end

      it '@node3.move_to_child_of @node3' do
        lambda do
          @node3.move_to_child_of @node3
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end
    end

    describe 'move_to_left_of' do
      it '@node1.move_to_left_of @node1' do
        lambda do
          @node1.move_to_left_of @node1
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      it '@node1.move_to_left_of @node2' do
        lambda do
          @node1.move_to_left_of @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node1.move_to_left_of @node3' do
        before do
          @node1.move_to_left_of @node3
          @node2.reload
        end

        it_should_behave_like '[@node1, [@node2]], [@node3]'
      end

      describe '@node2.move_to_left_of @node1' do
        before do
          @node2.move_to_left_of @node1
          @node3.reload
        end

        it_should_behave_like '[@node2], [@node1], [@node3]'
      end

      it '@node2.move_to_left_of @node2' do
        lambda do
          @node2.move_to_left_of @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node2.move_to_left_of @node3' do
        before do
          @node2.move_to_left_of @node3
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node2], [@node3]'
      end

      describe '@node3.move_to_left_of @node1' do
        before do
          @node3.move_to_left_of @node1
          @node2.reload
        end

        it_should_behave_like '[@node3], [@node1, [@node2]]'
      end

      describe '@node3.move_to_left_of @node2' do
        before do
          @node3.move_to_left_of @node2
          @node1.reload
        end

        it_should_behave_like '[@node1, [@node3, @node2]]'
      end

      it '@node3.move_to_left_of @node3' do
        lambda do
          @node3.move_to_left_of @node3
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end
    end

    describe 'move_to_right_of' do
      it '@node1.move_to_right_of @node1' do
        lambda do
          @node1.move_to_right_of @node1
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      it '@node1.move_to_right_of @node2' do
        lambda do
          @node1.move_to_right_of @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node1.move_to_right_of @node3' do
        before do
          @node1.move_to_right_of @node3
          @node2.reload
        end

        it_should_behave_like '[@node3], [@node1, [@node2]]'
      end

      describe '@node2.move_to_right_of @node1' do
        before do
          @node2.move_to_right_of @node1
          @node3.reload
        end

        it_should_behave_like '[@node1], [@node2], [@node3]'
      end

      it '@node2.move_to_right_of @node2' do
        lambda do
          @node2.move_to_right_of @node2
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end

      describe '@node2.move_to_right_of @node3' do
        before do
          @node2.move_to_right_of @node3
          @node1.reload
        end

        it_should_behave_like '[@node1], [@node3], [@node2]'
      end

      describe '@node3.move_to_right_of @node1' do
        before do
          @node3.move_to_right_of @node1
          @node2.reload
        end

        it_should_behave_like '[@node1, [@node2]], [@node3]'
      end

      describe '@node3.move_to_right_of @node2' do
        before do
          @node3.move_to_right_of @node2
          @node1.reload
        end

        it_should_behave_like '[@node1, [@node2, @node3]]'
      end

      it '@node3.move_to_right_of @node3' do
        lambda do
          @node3.move_to_right_of @node3
        end.should raise_error(Sequel::Plugins::StiNestedSet::Error)
      end
    end
  end
end

describe Sequel::Plugins::StiNestedSet do
  describe '全て同じクラス' do
    before do
      Node.create_table!
      @class1 = Node
      @class2 = Node
      @class3 = Node
    end

    it_should_behave_like 'StiNestedSet'
  end

  describe '全て同じクラス STI' do
    before do
      Node.create_table!
      @class1 = ExNode
      @class2 = ExNode
      @class3 = ExNode
    end

    it_should_behave_like 'StiNestedSet'
  end

  describe '別々のクラス混在で STI #1' do
    before do
      Node.create_table!
      @class1 = ExNode
      @class2 = Node
      @class3 = ExNode
    end

    it_should_behave_like 'StiNestedSet'
  end

  describe '別々のクラス混在で STI #2' do
    before do
      Node.create_table!
      @class1 = Node
      @class2 = ExNode
      @class3 = ExNode
    end

    it_should_behave_like 'StiNestedSet'
  end

  describe 'ノードを削除' do
    before do
      Node.create_table!
    end

    it '最初のノードを削除' do
      @node1 = Node.new.save
      @node2 = Node.new.save
      @node3 = Node.new.save

      @node1.left.should  == 1
      @node1.right.should == 2
      @node2.left.should  == 3
      @node2.right.should == 4
      @node3.left.should  == 5
      @node3.right.should == 6

      @node1.destroy

      lambda do
        @node1.reload
      end.should raise_error Sequel::Error
      @node2.reload
      @node3.reload

      @node2.left.should  == 1
      @node2.right.should == 2
      @node3.left.should  == 3
      @node3.right.should == 4
    end

    it '真ん中のノードを削除' do
      @node1 = Node.new.save
      @node2 = Node.new.save
      @node3 = Node.new.save

      @node1.left.should  == 1
      @node1.right.should == 2
      @node2.left.should  == 3
      @node2.right.should == 4
      @node3.left.should  == 5
      @node3.right.should == 6

      @node2.destroy

      @node1.reload
      lambda do
        @node2.reload
      end.should raise_error Sequel::Error
      @node3.reload

      @node1.left.should  == 1
      @node1.right.should == 2
      @node3.left.should  == 3
      @node3.right.should == 4
    end

    it '最後のノードを削除' do
      @node1 = Node.new.save
      @node2 = Node.new.save
      @node3 = Node.new.save

      @node1.left.should  == 1
      @node1.right.should == 2
      @node2.left.should  == 3
      @node2.right.should == 4
      @node3.left.should  == 5
      @node3.right.should == 6

      @node3.destroy

      @node1.reload
      @node2.reload
      lambda do
        @node3.reload
      end.should raise_error Sequel::Error

      @node1.left.should  == 1
      @node1.right.should == 2
      @node2.left.should  == 3
      @node2.right.should == 4
    end

    it 'ツリーを削除' do
      @node1 = Node.new.save
      @node2 = Node.new.save
      @node3 = Node.new.save

      @node2.move_to_child_of @node1

      @node3.reload

      @node1.left.should  == 1
      @node2.left.should  == 2
      @node2.right.should == 3
      @node1.right.should == 4
      @node3.left.should  == 5
      @node3.right.should == 6

      @node1.destroy

      lambda do
        @node1.reload
      end.should raise_error Sequel::Error
      lambda do
        @node2.reload
      end.should raise_error Sequel::Error
      @node3.reload

      @node3.left.should  == 1
      @node3.right.should == 2
    end
  end
end
