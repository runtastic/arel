require 'helper'

module Arel
  describe 'update manager' do
    describe 'new' do
      it 'takes an engine' do
        Arel::UpdateManager.new Table.engine
      end
    end

    it "should not quote sql literals" do
      table = Table.new(:users)
      um = Arel::UpdateManager.new Table.engine
      um.table table
      um.set [[table[:name], Arel::Nodes::BindParam.new]]
      um.to_sql.must_be_like %{ UPDATE "users" SET "name" =  ? }
    end

    it 'handles limit properly' do
      table = Table.new(:users)
      um = Arel::UpdateManager.new Table.engine
      um.key = 'id'
      um.take 10
      um.table table
      um.set [[table[:name], nil]]
      assert_match(/LIMIT 10/, um.to_sql)
    end

    describe 'set' do
      it "updates with null" do
        table = Table.new(:users)
        um = Arel::UpdateManager.new Table.engine
        um.table table
        um.set [[table[:name], nil]]
        um.to_sql.must_be_like %{ UPDATE "users" SET "name" =  NULL }
      end

      it 'takes a string' do
        table = Table.new(:users)
        um = Arel::UpdateManager.new Table.engine
        um.table table
        um.set Nodes::SqlLiteral.new "foo = bar"
        um.to_sql.must_be_like %{ UPDATE "users" SET foo = bar }
      end

      it 'takes a list of lists' do
        table = Table.new(:users)
        um = Arel::UpdateManager.new Table.engine
        um.table table
        um.set [[table[:id], 1], [table[:name], 'hello']]
        um.to_sql.must_be_like %{
          UPDATE "users" SET "id" = 1, "name" =  'hello'
        }
      end

      it 'chains' do
        table = Table.new(:users)
        um = Arel::UpdateManager.new Table.engine
        um.set([[table[:id], 1], [table[:name], 'hello']]).must_equal um
      end
    end

    describe 'table' do
      it 'generates an update statement' do
        um = Arel::UpdateManager.new Table.engine
        um.table Table.new(:users)
        um.to_sql.must_be_like %{ UPDATE "users" }
      end

      it 'chains' do
        um = Arel::UpdateManager.new Table.engine
        um.table(Table.new(:users)).must_equal um
      end

      it 'generates an update statement with joins' do
        um = Arel::UpdateManager.new Table.engine

        table = Table.new(:users)
        join_source = Arel::Nodes::JoinSource.new(
          table,
          [table.create_join(Table.new(:posts))]
        )

        um.table join_source
        um.to_sql.must_be_like %{ UPDATE "users" INNER JOIN "posts" }
      end
    end

    describe 'where' do
      it 'generates a where clause' do
        table = Table.new :users
        um = Arel::UpdateManager.new Table.engine
        um.table table
        um.where table[:id].eq(1)
        um.to_sql.must_be_like %{
          UPDATE "users" WHERE "users"."id" = 1
        }
      end

      it 'chains' do
        table = Table.new :users
        um = Arel::UpdateManager.new Table.engine
        um.table table
        um.where(table[:id].eq(1)).must_equal um
      end
    end

    describe 'key' do
      before do
        @table = Table.new :users
        @um = Arel::UpdateManager.new Table.engine
        @um.key = @table[:foo]
      end

      it 'can be set' do
        @um.ast.key.must_equal @table[:foo]
      end

      it 'can be accessed' do
        @um.key.must_equal @table[:foo]
      end
    end
  end
end
