class ActionDispatch::Http::UploadedFile
  # When serializing an UploadedFile to JSON, don't try to serialize the file
  # contents since this breaks the JSON encoders.
  def as_json(options = nil)
    %w(content_type headers original_filename size).inject({}) do |hash, attr|
      hash[attr] = send(attr)
      hash
    end
  end
end
