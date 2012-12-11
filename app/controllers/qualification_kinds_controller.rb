class QualificationKindsController < CrudController
  
  def create
    super(location: qualification_kinds_path)
  end
  
  def update
    super(location: qualification_kinds_path)
  end
    
  private
  
  def list_entries
    super.order(:deleted_at, :label)
  end
  
  def assign_attributes
    super
    entry.deleted_at = nil
  end
  
end