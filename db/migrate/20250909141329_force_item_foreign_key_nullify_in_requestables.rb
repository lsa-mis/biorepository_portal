class ForceItemForeignKeyNullifyInRequestables < ActiveRecord::Migration[8.0]
  def up
    # First, find and drop the existing foreign key constraint
    execute <<-SQL
      DO $$
      DECLARE
          constraint_name TEXT;
      BEGIN
          -- Find the foreign key constraint name for item_id
          SELECT tc.constraint_name INTO constraint_name
          FROM information_schema.table_constraints tc
          JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
          JOIN information_schema.constraint_column_usage ccu
            ON ccu.constraint_name = tc.constraint_name
          WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_name = 'requestables'
            AND kcu.column_name = 'item_id'
            AND ccu.table_name = 'items';
          
          -- Drop the constraint if it exists
          IF constraint_name IS NOT NULL THEN
              EXECUTE 'ALTER TABLE requestables DROP CONSTRAINT ' || constraint_name;
          END IF;
      END $$;
    SQL
    
    # Add the new foreign key constraint with SET NULL
    execute <<-SQL
      ALTER TABLE requestables 
      ADD CONSTRAINT fk_rails_requestables_item_id 
      FOREIGN KEY (item_id) 
      REFERENCES items(id) 
      ON DELETE SET NULL;
    SQL
  end

  def down
    # Remove the SET NULL constraint and add back CASCADE (original behavior)
    execute <<-SQL
      DO $$
      DECLARE
          constraint_name TEXT;
      BEGIN
          -- Find and drop the current foreign key constraint
          SELECT tc.constraint_name INTO constraint_name
          FROM information_schema.table_constraints tc
          JOIN information_schema.key_column_usage kcu
            ON tc.constraint_name = kcu.constraint_name
          JOIN information_schema.constraint_column_usage ccu
            ON ccu.constraint_name = tc.constraint_name
          WHERE tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_name = 'requestables'
            AND kcu.column_name = 'item_id'
            AND ccu.table_name = 'items';
          
          IF constraint_name IS NOT NULL THEN
              EXECUTE 'ALTER TABLE requestables DROP CONSTRAINT ' || constraint_name;
          END IF;
      END $$;
    SQL
    
    # Add back the CASCADE constraint
    execute <<-SQL
      ALTER TABLE requestables 
      ADD CONSTRAINT fk_rails_requestables_item_id 
      FOREIGN KEY (item_id) 
      REFERENCES items(id) 
      ON DELETE CASCADE;
    SQL
  end
end
