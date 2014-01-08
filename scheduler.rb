require 'data_mapper'

DataMapper.setup(:default, 'sqlite:///Users/Ben/hubert/hubert_db.db')

class Schedule
  include DataMapper::Resource

  property :id,         Serial    
  property :time,       Text    
  property :command,    Text      
  property :requester,  Text  
  property :executed,   Boolean
end

DataMapper.finalize