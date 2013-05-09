class ImportTask
@queue = :import_queue
  def self.perform user_id, collection_id, columns_spec
    ImportWizard.execute(user_id, collection_id, columns_spec)
  end
end
