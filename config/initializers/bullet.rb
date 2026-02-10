# Bullet configuration for N+1 query detection
if defined?(Bullet)
  Bullet.enable        = true
  # Bullet.alert         = Rails.env.development?
  Bullet.alert = false # Disable browser alerts (can be annoying)
  Bullet.console = true # Print in server console
  Bullet.rails_logger = true # Add to Rails.logger
  Bullet.bullet_logger = true # Log to bullet.log file
  Bullet.add_footer = Rails.env.development? # Add footer with detected issues
  Bullet.raise         = Rails.env.test? # raise an error if n+1 query occurs
  
  # Disable specific checks if needed
  # Bullet.unused_eager_loading_enable = false
  # Bullet.counter_cache_enable = false
  
  # Only show N+1 queries (most important)
  Bullet.n_plus_one_query_enable = true
  Bullet.unused_eager_loading_enable = true
  Bullet.counter_cache_enable = true
  
  # Add safelists for test environment only - associations are actually used but test data creates false warnings
  if Rails.env.test?
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Item", association: :collection
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Item", association: :preparations
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Item", association: :current_identification
    Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :record
    Bullet.add_safelist type: :unused_eager_loading, class_name: "CollectionQuestion", association: :collection_options
  end
  
  # Add safelist for loan requests - requestable preparation association
  Bullet.add_safelist type: :n_plus_one_query, class_name: "Requestable", association: :preparation
  
  # Add safelist for collection questions - collection answers association
  Bullet.add_safelist type: :n_plus_one_query, class_name: "CollectionQuestion", association: :collection_answers
  Bullet.add_safelist type: :n_plus_one_query, class_name: "CollectionQuestion", association: :rich_text_question
  Bullet.add_safelist type: :n_plus_one_query, class_name: "LoanQuestion", association: :loan_answers
  Bullet.add_safelist type: :n_plus_one_query, class_name: "LoanQuestion", association: :rich_text_question
  
  # Add safelist for loan answers - rich text answer association
  Bullet.add_safelist type: :n_plus_one_query, class_name: "LoanAnswer", association: :rich_text_answer
    Bullet.add_safelist type: :n_plus_one_query, class_name: "CollectionAnswer", association: :rich_text_answer

  
  # Add safelist for loan questions - rich text question association
  Bullet.add_safelist type: :unused_eager_loading, class_name: "LoanQuestion", association: :rich_text_question
  
end
