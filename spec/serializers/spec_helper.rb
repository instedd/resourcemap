def expect_rendered_value(json, field, serializer, expected_value)
  expect(json).to have_key(field), "expected serializer to render attribute #{field}"
  expect(json[field]).to eq(expected_value), "expected serializer to render #{expected_value} for field #{field}, got #{json[field]}"
end

def expect_fields_rendered_by(serializer)
  json = JSON.parse(serializer.to_json).with_indifferent_access
  spec = yield

  if spec.is_a? Array
    spec.each do |field|
      expect_rendered_value json, field, serializer, serializer.object.send(field).as_json
    end
  elsif spec.is_a? Hash
    spec.each do |field, expected_value|
      expect_rendered_value json, field, serializer, expected_value
    end
  else
    raise "Blocks passed into expect_fields_render_by may only return Arrays or Hashes. Any other return type is unsupported."
  end
end
