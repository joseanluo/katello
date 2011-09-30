class PackGroupValidator < ActiveModel::Validator
  def validate(record)
    #repo = Glue::Pulp::Repo.new(:id => record.repo_id)
    #unless repo.package_groups(:id => record.package_group_id).first
    #  record.errors[:base] <<  (_("Package group '%s' doesn't exist in repo '%s'") % [record.package_group_id, record.repo_id])
    #end
  end
end

class SystemTemplatePackGroup < ActiveRecord::Base
  belongs_to :system_template, :inverse_of => :package_groups
  validates_with PackGroupValidator
  validates_uniqueness_of [:name], :scope => :system_template_id, :message => _("is already in the template")

end
