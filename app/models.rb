class Group < ActiveRecord::Base
    belongs_to :user
end

class User < ActiveRecord::Base
    belongs_to :group
end

class DatabaseCredential < ActiveRecord::Base
end
  